import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:flutter_webapp/config/app_config.dart';
import 'token_storage_service.dart';
import 'room_api_service.dart';

/// ルーム招待通知サービス
/// WebSocketでルーム招待通知を受信し、招待数を管理します
class RoomInvitationService {
  static final RoomInvitationService _instance =
      RoomInvitationService._internal();
  factory RoomInvitationService() => _instance;
  RoomInvitationService._internal();

  StompClient? _stompClient;
  final TokenStorageService _tokenStorage = TokenStorageService();
  final RoomApiService _roomApiService = RoomApiService();
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  bool _isConnecting = false;

  // 招待数
  int _invitationCount = 0;
  int get invitationCount => _invitationCount;

  // 招待リスト
  List<Map<String, dynamic>> _invitations = [];
  List<Map<String, dynamic>> get invitations => List.unmodifiable(_invitations);

  // 通知ストリーム
  final StreamController<RoomInvitationEvent> _eventController =
      StreamController<RoomInvitationEvent>.broadcast();

  Stream<RoomInvitationEvent> get eventStream => _eventController.stream;

  // 招待数変更ストリーム
  final StreamController<int> _countController =
      StreamController<int>.broadcast();

  Stream<int> get countStream => _countController.stream;

  /// WebSocket接続を開始
  Future<void> connect() async {
    if (_stompClient != null && _stompClient!.connected) {
      return;
    }
    if (_isConnecting) {
      return;
    }
    _isConnecting = true;

    final userId = await _tokenStorage.getUserId();

    // ===== nullチェック強化 =====
    if (userId == null) {
      debugPrint('RoomInvitationService: Cannot connect - userId is null');
      _isConnecting = false;
      return;
    }

    // 初期招待リストを取得
    await _fetchInvitations(userId);

    _stompClient = StompClient(
      config: StompConfig(
        url: '${AppConfig.wsBaseUrl}/ws',
        stompConnectHeaders: {
          if (userId != null) 'userId': userId.toString(),
          'clientType': 'invitation',
        },
        onConnect: (frame) {
          _reconnectAttempts = 0;
          _isConnecting = false;
          _subscribeToRoomInvitations(userId);
        },
        onWebSocketError: (dynamic error) {
          debugPrint('WebSocket Error (Room): $error');
          _scheduleReconnect();
        },
        onStompError: (frame) {
          debugPrint('STOMP Error (Room): ${frame.body}');
        },
        onDisconnect: (frame) {
          debugPrint('Disconnected from Room WebSocket');
          _scheduleReconnect();
        },
      ),
    );

    _stompClient!.activate();
    // 注意: _isConnecting は onConnect コールバック内でリセットされる
    // activate() は非同期なので、ここでリセットしてはいけない
  }

  /// 招待リストを取得
  Future<void> _fetchInvitations(int userId) async {
    try {
      final accessToken = await _tokenStorage.getAccessToken();
      if (accessToken == null) return;

      final invitations = await _roomApiService.getInvitations(
        userId: userId,
        accessToken: accessToken,
      );

      _invitations = invitations;
      _invitationCount = invitations.length;
      _countController.add(_invitationCount);
    } catch (e) {
      debugPrint('Error fetching invitations: $e');
    }
  }

  /// 招待リストを再取得（外部から呼び出し用）
  Future<void> refreshInvitations() async {
    final userId = await _tokenStorage.getUserId();
    if (userId != null) {
      await _fetchInvitations(userId);
    }
  }

  /// ルーム招待通知をサブスクライブ
  void _subscribeToRoomInvitations(int userId) {
    _stompClient?.subscribe(
      destination: '/topic/room-invitation/$userId',
      callback: (frame) {
        if (frame.body != null) {
          _handleInvitationNotification(frame.body!);
        }
      },
    );
  }

  /// 招待通知を処理
  void _handleInvitationNotification(String body) {
    try {
      final Map<String, dynamic> notification = jsonDecode(body);
      final type = notification['type'];

      if (type == 'room_invitation') {
        // 新しい招待を追加
        _invitations.add(notification);
        _invitationCount++;
        _countController.add(_invitationCount);

        // イベントを発火
        _eventController.add(RoomInvitationEvent(
          type: RoomInvitationEventType.received,
          data: notification,
        ));
      } else if (type == 'invitation_canceled') {
        // 招待がキャンセルされた
        final roomId = notification['roomId'];
        _invitations.removeWhere((inv) => inv['roomId'] == roomId);
        _invitationCount = _invitations.length;
        _countController.add(_invitationCount);

        _eventController.add(RoomInvitationEvent(
          type: RoomInvitationEventType.canceled,
          data: notification,
        ));
      }
    } catch (e) {
      debugPrint('Error parsing room invitation: $e');
    }
  }

  /// 招待を受理
  Future<Map<String, dynamic>?> acceptInvitation(int roomId) async {
    try {
      final userId = await _tokenStorage.getUserId();
      final accessToken = await _tokenStorage.getAccessToken();

      if (userId == null || accessToken == null) return null;

      final result = await _roomApiService.acceptInvitation(
        roomId: roomId,
        userId: userId,
        accessToken: accessToken,
      );

      // ローカルリストから削除
      _invitations.removeWhere((inv) => inv['roomId'] == roomId);
      _invitationCount = _invitations.length;
      _countController.add(_invitationCount);

      await _reconnectAfterAccept();
      return result;
    } catch (e) {
      debugPrint('Error accepting invitation: $e');
      rethrow;
    }
  }

  /// 招待を拒否
  Future<void> rejectInvitation(int roomId) async {
    try {
      final userId = await _tokenStorage.getUserId();
      final accessToken = await _tokenStorage.getAccessToken();

      if (userId == null || accessToken == null) return;

      await _roomApiService.rejectInvitation(
        roomId: roomId,
        userId: userId,
        accessToken: accessToken,
      );

      // ローカルリストから削除
      _invitations.removeWhere((inv) => inv['roomId'] == roomId);
      _invitationCount = _invitations.length;
      _countController.add(_invitationCount);
    } catch (e) {
      debugPrint('Error rejecting invitation: $e');
      rethrow;
    }
  }

  /// 接続を切断
  void disconnect() {
    _stompClient?.deactivate();
    _stompClient = null;
    _reconnectTimer?.cancel();
    _isConnecting = false;
  }

  /// リソースを解放
  void dispose() {
    disconnect();
    _eventController.close();
    _countController.close();
  }

  void _scheduleReconnect() {
    if (_reconnectTimer?.isActive ?? false) {
      return;
    }
    _reconnectAttempts += 1;
    final delaySeconds = (_reconnectAttempts + 1).clamp(2, 6);
    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () async {
      if (_stompClient?.connected ?? false) {
        return;
      }
      await connect();
    });
  }

  Future<void> _reconnectAfterAccept() async {
    disconnect();
    await connect();
  }
}

/// 招待イベントタイプ
enum RoomInvitationEventType {
  received,
  canceled,
}

/// 招待イベント
class RoomInvitationEvent {
  final RoomInvitationEventType type;
  final Map<String, dynamic> data;

  RoomInvitationEvent({required this.type, required this.data});
}
