import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
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
    _userId = await _tokenStorage.getUserId();
    if (_userId == null) {
      _isConnecting = false;
      return;
    }

    _stompClient = StompClient(
      config: StompConfig(
        url: 'ws://localhost:8080/ws',
        stompConnectHeaders: {
          if (_userId != null) 'userId': _userId.toString(),
        },
        webSocketConnectHeaders: {
          'Sec-WebSocket-Protocol': 'v12.stomp',
        },
        onConnect: (frame) {
          _startHeartbeat();
        },
        onWebSocketError: (dynamic error) {
          debugPrint('Presence WebSocket Error: $error');
        },
        onStompError: (frame) {
          debugPrint('Presence STOMP Error: ${frame.body}');
        },
        onDisconnect: (frame) {
          _stopHeartbeat();
        },
      ),
    );

    _stompClient!.activate();
    _isConnecting = false;
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
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      disconnect();
    } else if (state == AppLifecycleState.resumed) {
      connect();
    }
  }
}
