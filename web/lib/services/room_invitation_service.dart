import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
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

    final userId = await _tokenStorage.getUserId();
    if (userId == null) return;

    // 初期招待リストを取得
    await _fetchInvitations(userId);

    _stompClient = StompClient(
      config: StompConfig(
        url: 'ws://localhost:8080/ws',
        stompConnectHeaders: {
          if (userId != null) 'userId': userId.toString(),
        },
        onConnect: (frame) {
          _subscribeToRoomInvitations(userId);
        },
        onWebSocketError: (dynamic error) {
          debugPrint('WebSocket Error (Room): $error');
        },
        onStompError: (frame) {
          debugPrint('STOMP Error (Room): ${frame.body}');
        },
        onDisconnect: (frame) {
          debugPrint('Disconnected from Room WebSocket');
        },
      ),
    );

    _stompClient!.activate();
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
  }

  /// リソースを解放
  void dispose() {
    disconnect();
    _eventController.close();
    _countController.close();
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
