import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../services/token_storage_service.dart';

/// ルーム招待通知オーバーレイ
/// アプリ全体で招待通知を表示します（battle_screen除外）
class RoomInvitationOverlay extends StatefulWidget {
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;

  const RoomInvitationOverlay({
    Key? key,
    required this.child,
    required this.navigatorKey,
  }) : super(key: key);

  @override
  State<RoomInvitationOverlay> createState() => _RoomInvitationOverlayState();
}

class _RoomInvitationOverlayState extends State<RoomInvitationOverlay> {
  final TokenStorageService _tokenStorage = TokenStorageService();
  StompClient? _stompClient;
  int? _userId;

  // 表示中の通知
  OverlayEntry? _currentOverlay;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _stompClient?.deactivate();
    _hideTimer?.cancel();
    _currentOverlay?.remove();
    super.dispose();
  }

  Future<void> _initialize() async {
    _userId = await _tokenStorage.getUserId();
    if (_userId != null) {
      _connectWebSocket();
    }
  }

  void _connectWebSocket() {
    _stompClient = StompClient(
      config: StompConfig(
        url: 'ws://localhost:8080/ws',
        stompConnectHeaders: {
          if (_userId != null) 'userId': _userId.toString(),
        },
        onConnect: (frame) {
          _stompClient!.subscribe(
            destination: '/topic/room-invitation/$_userId',
            callback: (StompFrame frame) {
              if (frame.body != null) {
                _handleInvitation(frame.body!);
              }
            },
          );
        },
        onWebSocketError: (error) {
          debugPrint('RoomInvitationOverlay WebSocket Error: $error');
        },
        onDisconnect: (frame) {
          // 再接続を試みる
          Future.delayed(const Duration(seconds: 5), () {
            if (mounted && _stompClient != null) {
              _stompClient!.activate();
            }
          });
        },
      ),
    );

    _stompClient!.activate();
  }

  void _handleInvitation(String body) {
    try {
      final data = jsonDecode(body);
      final type = data['type'];

      if (type == 'room_invitation') {
        // バトル中・ランクマッチ待機中は通知しない
        if (_shouldSuppressNotification()) {
          return;
        }

        _showInvitationBanner(data);
      }
    } catch (e) {
      debugPrint('Invitation parse error: $e');
    }
  }

  /// 現在のルートが通知を抑制すべき画面かチェック
  /// 対象: /battle（バトル中）, /matching（ランクマッチ待機中）
  bool _shouldSuppressNotification() {
    final navigator = widget.navigatorKey.currentState;
    if (navigator == null) return false;

    String? currentRouteName;
    navigator.popUntil((route) {
      currentRouteName = route.settings.name;
      return true;
    });

    if (currentRouteName == null) return false;

    // バトル中またはランクマッチ待機中は通知を抑制
    return currentRouteName!.startsWith('/battle') ||
           currentRouteName!.startsWith('/matching');
  }

  /// 招待バナーを表示
  void _showInvitationBanner(Map<String, dynamic> data) {
    // 既存の通知を削除
    _currentOverlay?.remove();
    _hideTimer?.cancel();

    final inviter = data['inviter'] as Map<String, dynamic>?;
    final inviterName = inviter?['username'] ?? '誰か';
    final roomId = data['roomId'];
    final matchType = data['matchType'] ?? 5;

    final overlay = OverlayEntry(
      builder: (context) => _InvitationBanner(
        inviterName: inviterName,
        matchType: matchType,
        onAccept: () {
          _currentOverlay?.remove();
          _currentOverlay = null;
          _hideTimer?.cancel();

          // ルームマッチ画面へ遷移
          widget.navigatorKey.currentState?.pushNamed(
            '/room-match?roomId=$roomId&isGuest=true',
          );
        },
        onDismiss: () {
          _currentOverlay?.remove();
          _currentOverlay = null;
          _hideTimer?.cancel();
        },
        onViewAll: () {
          _currentOverlay?.remove();
          _currentOverlay = null;
          _hideTimer?.cancel();

          // 招待一覧画面へ遷移
          widget.navigatorKey.currentState?.pushNamed('/room-invitations');
        },
      ),
    );

    _currentOverlay = overlay;
    Overlay.of(context).insert(overlay);

    // 10秒後に自動で消す
    _hideTimer = Timer(const Duration(seconds: 10), () {
      _currentOverlay?.remove();
      _currentOverlay = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// 招待バナーウィジェット
class _InvitationBanner extends StatelessWidget {
  final String inviterName;
  final int matchType;
  final VoidCallback onAccept;
  final VoidCallback onDismiss;
  final VoidCallback onViewAll;

  const _InvitationBanner({
    required this.inviterName,
    required this.matchType,
    required this.onAccept,
    required this.onDismiss,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade600, Colors.purple.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // アイコン
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.videogame_asset,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // テキスト
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ルームマッチへの招待',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$inviterName さんから招待',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '先取${matchType}本勝負',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 閉じるボタン
                    IconButton(
                      onPressed: onDismiss,
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),

              // アクションボタン
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    // 招待一覧を見る
                    Expanded(
                      child: TextButton(
                        onPressed: onViewAll,
                        child: const Text(
                          '招待一覧',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 30,
                      color: Colors.white24,
                    ),
                    // 参加する
                    Expanded(
                      child: TextButton(
                        onPressed: onAccept,
                        child: const Text(
                          '参加する',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
