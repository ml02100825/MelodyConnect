import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:flutter_webapp/config/app_config.dart';
import 'token_storage_service.dart';

/// オンライン判定用のWebSocket常駐サービス
class PresenceWebSocketService {
  static final PresenceWebSocketService _instance =
      PresenceWebSocketService._internal();
  factory PresenceWebSocketService() => _instance;
  PresenceWebSocketService._internal();

  static const Duration _heartbeatInterval = Duration(seconds: 20);

  final TokenStorageService _tokenStorage = TokenStorageService();
  StompClient? _stompClient;
  Timer? _heartbeatTimer;
  bool _isConnecting = false;
  int? _userId;

  Future<void> connect() async {
    if (_stompClient != null && _stompClient!.connected) {
      return;
    }
    if (_isConnecting) {
      return;
    }
    _isConnecting = true;
    final userId = await _tokenStorage.getUserId();
    _userId = userId;

    // ===== nullチェック強化 =====
    if (userId == null) {
      debugPrint('PresenceWebSocketService: Cannot connect - userId is null');
      _isConnecting = false;
      return;
    }

    _stompClient = StompClient(
      config: StompConfig(
        url: '${AppConfig.wsBaseUrl}/ws',
        stompConnectHeaders: {
          if (userId != null) 'userId': userId.toString(),
          'clientType': 'presence',
        },
        webSocketConnectHeaders: {
          'Sec-WebSocket-Protocol': 'v12.stomp',
        },
        onConnect: (frame) {
          _isConnecting = false;
          _startHeartbeat();
        },
        onWebSocketError: (dynamic error) {
          _isConnecting = false;
          debugPrint('Presence WebSocket Error: $error');
        },
        onStompError: (frame) {
          debugPrint('Presence STOMP Error: ${frame.body}');
        },
        onDisconnect: (frame) {
          _stopHeartbeat();
          _scheduleReconnect();
        },
      ),
    );

    _stompClient!.activate();
    // 注意: _isConnecting は onConnect コールバック内でリセットされる
    // activate() は非同期なので、ここでリセットしてはいけない
  }

  void _scheduleReconnect() {
    if (_isConnecting) return;
    Future.delayed(const Duration(seconds: 5), () {
      if (_stompClient?.connected ?? false) return;
      if (_userId == null) return;
      connect();
    });
  }

  void _startHeartbeat() {
    _stopHeartbeat();
    final userId = _userId;
    if (userId == null) return;

    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
      if (!(_stompClient?.connected ?? false)) {
        return;
      }
      _stompClient?.send(
        destination: '/app/presence/heartbeat',
        body: jsonEncode({'userId': userId}),
      );
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void disconnect() {
    _stopHeartbeat();
    _stompClient?.deactivate();
    _stompClient = null;
  }

  void handleLifecycle(AppLifecycleState state) {
    // タブ切り替えでWebSocket接続を切断しない
    // detachedの場合のみ切断（アプリ終了時）
    if (state == AppLifecycleState.detached) {
      disconnect();
    } else if (state == AppLifecycleState.resumed) {
      // 接続が切れている場合のみ再接続
      if (_stompClient == null || !_stompClient!.connected) {
        connect();
      }
    }
  }
}
