import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:flutter_webapp/config/app_config.dart';
import '../services/token_storage_service.dart';
import '../services/presence_websocket_service.dart';
import '../services/authentication_state_manager.dart';

/// ルーム招待通知オーバーレイ
/// アプリ全体で招待通知を表示します
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

class _RoomInvitationOverlayState extends State<RoomInvitationOverlay>
    with WidgetsBindingObserver {
  final TokenStorageService _tokenStorage = TokenStorageService();
  final PresenceWebSocketService _presenceService =
      PresenceWebSocketService();
  final AuthenticationStateManager _authStateManager =
      AuthenticationStateManager();
  StompClient? _stompClient;
  int? _userId;
  Timer? _reconnectTimer;
  StreamSubscription<int?>? _userIdSubscription;

  int _reconnectAttempts = 0;
  bool _isConnecting = false;
  int? _lastInvitationRoomId;
  DateTime? _lastInvitationAt;

  // 表示中の通知
  OverlayEntry? _currentOverlay;
  Timer? _hideTimer;

@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addObserver(this);

  // AuthenticationStateManagerのuserIdを監視
  _authStateManager.userIdListenable.addListener(_onUserIdChanged);

  // 初期化（安全版）
  _initializeSafely();

  // 後方互換性のため、既存のStreamリスナーも保持
  _userIdSubscription = _tokenStorage.userIdStream.listen((userId) async {
    if (!mounted) return;
    if (userId == null) {
      _stompClient?.deactivate();
      _stompClient = null;
      return;
    }
    _userId = userId;
    await _presenceService.connect();
    _connectWebSocketSafely();
  });
}

void _onUserIdChanged() {
  if (!mounted) return;

  final newUserId = _authStateManager.userId;

  if (newUserId == null) {
    // ログアウト時
    _userId = null;
    _stompClient?.deactivate();
    _stompClient = null;
    debugPrint('RoomInvitationOverlay: User logged out, disconnected');
    return;
  }

  if (_userId != newUserId) {
    // userIdが変更された（ログイン完了）
    _userId = newUserId;
    debugPrint('RoomInvitationOverlay: userId updated to $_userId');
    _connectWebSocketSafely();
  }
}


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshUserIfNeeded();
  }

  @override
void dispose() {
  _authStateManager.userIdListenable.removeListener(_onUserIdChanged);
  _userIdSubscription?.cancel();
  _stompClient?.deactivate();
  _hideTimer?.cancel();
  _reconnectTimer?.cancel();
  _currentOverlay?.remove();
  WidgetsBinding.instance.removeObserver(this);
  super.dispose();
}

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // タブ切り替えでWebSocket接続を切断しない
    // detachedの場合のみ切断（アプリ終了時）
    if (state == AppLifecycleState.detached) {
      _stompClient?.deactivate();
    } else if (state == AppLifecycleState.resumed) {
      // 接続が切れている場合のみ再接続
      if (_stompClient == null || !_stompClient!.connected) {
        _connectWebSocketSafely();
      }
    }
    _presenceService.handleLifecycle(state);
  }

  Future<void> _initializeSafely() async {
    _userId = _authStateManager.userId;

    debugPrint('RoomInvitationOverlay initialized with userId=$_userId');

    if (_userId != null && _authStateManager.isAuthenticatedWithUserId) {
      await _presenceService.connect();
      _connectWebSocketSafely();
    } else {
      debugPrint('RoomInvitationOverlay: Waiting for authentication...');
    }
  }

  Future<void> _refreshUserIfNeeded() async {
    if (_userId != null) return;
    final userId = await _tokenStorage.getUserId();
    if (!mounted || userId == null) return;
    setState(() {
      _userId = userId;
    });
    await _presenceService.connect();
    _connectWebSocketSafely();
  }

  void _connectWebSocketSafely() {
    // ===== CRITICAL: userIdのnullチェック =====
    if (_userId == null) {
      debugPrint('RoomInvitationOverlay: Cannot connect - userId is null');
      return;
    }

    // 認証状態の二重チェック
    if (!_authStateManager.isAuthenticatedWithUserId) {
      debugPrint('RoomInvitationOverlay: Cannot connect - not authenticated');
      return;
    }

    if (_stompClient != null && _stompClient!.connected) {
      return;
    }
    if (_isConnecting) {
      return;
    }

    // ===== 最終安全チェック（ローカル変数に固定） =====
    final safeUserId = _userId;
    if (safeUserId == null) {
      debugPrint('RoomInvitationOverlay: CRITICAL - userId became null');
      return;
    }

    _isConnecting = true;
    _stompClient?.deactivate();
    _stompClient = StompClient(
      config: StompConfig(
        url: '${AppConfig.wsBaseUrl}/ws',
        stompConnectHeaders: {
          'userId': safeUserId.toString(), // null安全な変数を使用
          'clientType': 'overlay',
        },
        onConnect: (frame) {
          _reconnectAttempts = 0;
          _isConnecting = false;

          // ===== サブスクライブ時も安全チェック =====
          final currentUserId = _userId;
          if (currentUserId == null) {
            debugPrint('RoomInvitationOverlay: userId null at subscribe');
            _stompClient?.deactivate();
            return;
          }

          _stompClient!.subscribe(
            destination: '/topic/room-invitation/$currentUserId',
            callback: (StompFrame frame) {
              if (frame.body != null) {
                _handleInvitation(frame.body!);
              }
            },
          );
          debugPrint('RoomInvitationOverlay: Connected and subscribed with userId=$currentUserId');
        },
        onWebSocketError: (error) {
          debugPrint('RoomInvitationOverlay WebSocket Error: $error');
          _scheduleReconnect();
        },
        onDisconnect: (frame) {
          _scheduleReconnect();
        },
      ),
    );

    _stompClient!.activate();
    // 注意: _isConnecting は onConnect コールバック内でリセットされる
    // activate() は非同期なので、ここでリセットしてはいけない
  }

  void _handleInvitation(String body) {
    try {
      final data = jsonDecode(body);
      final type = data['type'];

      if (type == 'room_invitation') {
        _showInvitationBanner(data);
      }
    } catch (e) {
      debugPrint('Invitation parse error: $e');
    }
  }

  /// 招待バナーを表示
  void _showInvitationBanner(Map<String, dynamic> data) {
    // 既存の通知を削除
    final roomId = data['roomId'];
    final now = DateTime.now();
    if (_currentOverlay != null &&
        _lastInvitationRoomId == roomId &&
        _lastInvitationAt != null &&
        now.difference(_lastInvitationAt!).inSeconds < 3) {
      _hideTimer?.cancel();
      _hideTimer = Timer(const Duration(seconds: 10), () {
        _currentOverlay?.remove();
        _currentOverlay = null;
      });
      return;
    }

    _currentOverlay?.remove();
    _hideTimer?.cancel();

    final inviter = data['inviter'] as Map<String, dynamic>?;
    final inviterName = inviter?['username'] ?? '誰か';
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
    _lastInvitationRoomId = roomId;
    _lastInvitationAt = now;
    final overlayState = widget.navigatorKey.currentState?.overlay;
    if (overlayState == null) return;
    overlayState.insert(overlay);


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

  void _scheduleReconnect() {
    if (!mounted) return;
    if (_reconnectTimer?.isActive ?? false) {
      return;
    }
    _reconnectAttempts += 1;
    final delaySeconds = (_reconnectAttempts + 1).clamp(2, 6);
    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      if (!mounted) return;
      if (_stompClient?.connected ?? false) return;
      _connectWebSocketSafely();
    });
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
