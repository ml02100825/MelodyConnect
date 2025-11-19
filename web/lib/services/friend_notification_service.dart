import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'token_storage_service.dart';
import 'friend_api_service.dart';

/// フレンド申請通知サービス
/// WebSocketでフレンド申請通知を受信し、ポップアップを表示します
class FriendNotificationService {
  static final FriendNotificationService _instance =
      FriendNotificationService._internal();
  factory FriendNotificationService() => _instance;
  FriendNotificationService._internal();

  StompClient? _stompClient;
  final TokenStorageService _tokenStorage = TokenStorageService();
  final FriendApiService _friendApiService = FriendApiService();

  // 通知を無効にする画面のリスト
  final Set<String> _disabledScreens = {
    'BattleScreen',
    'MatchingScreen',
    'QuizScreen',
  };

  // 現在のスクリーン名
  String? _currentScreen;

  // 通知ストリーム
  final StreamController<Map<String, dynamic>> _notificationController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get notificationStream =>
      _notificationController.stream;

  /// 現在の画面を設定
  void setCurrentScreen(String screenName) {
    _currentScreen = screenName;
  }

  /// WebSocket接続を開始
  Future<void> connect() async {
    if (_stompClient != null && _stompClient!.connected) {
      return;
    }

    final userId = await _tokenStorage.getUserId();
    if (userId == null) return;

    _stompClient = StompClient(
      config: StompConfig(
        url: 'ws://localhost:8080/ws',
        onConnect: (frame) {
          _subscribeToFriendNotifications(userId);
        },
        onWebSocketError: (dynamic error) {
          debugPrint('WebSocket Error: $error');
        },
        onStompError: (frame) {
          debugPrint('STOMP Error: ${frame.body}');
        },
        onDisconnect: (frame) {
          debugPrint('Disconnected from WebSocket');
        },
      ),
    );

    _stompClient!.activate();
  }

  /// フレンド通知をサブスクライブ
  void _subscribeToFriendNotifications(int userId) {
    _stompClient?.subscribe(
      destination: '/topic/friend/$userId',
      callback: (frame) {
        if (frame.body != null) {
          _handleNotification(frame.body!);
        }
      },
    );
  }

  /// 通知を処理
  void _handleNotification(String body) {
    try {
      // JSON文字列をパース
      final Map<String, dynamic> notification = jsonDecode(body);

      // 現在の画面が無効リストにない場合のみ通知
      if (_currentScreen == null ||
          !_disabledScreens.contains(_currentScreen)) {
        _notificationController.add(notification);
      }
    } catch (e) {
      debugPrint('Error parsing notification: $e');
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
    _notificationController.close();
  }
}

/// フレンド申請通知ポップアップウィジェット
class FriendRequestPopup extends StatelessWidget {
  final Map<String, dynamic> notification;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onClose;

  const FriendRequestPopup({
    Key? key,
    required this.notification,
    required this.onAccept,
    required this.onDecline,
    required this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'フレンド申請',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // ユーザー情報
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.blue.shade50,
                backgroundImage: notification['requesterImageUrl'] != null
                    ? NetworkImage(notification['requesterImageUrl'])
                    : null,
                child: notification['requesterImageUrl'] == null
                    ? const Icon(Icons.person, size: 40, color: Colors.purple)
                    : null,
              ),
              const SizedBox(height: 12),

              Text(
                notification['requesterUsername'] ?? '',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '@${notification['requesterUserUuid'] ?? ''}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'からフレンド申請が届きました',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 24),

              // アクションボタン
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onDecline,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                      child: const Text('拒否'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onAccept,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text('承認'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: onClose,
                child: const Text('後で確認する'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// フレンド通知オーバーレイを管理するウィジェット
class FriendNotificationOverlay extends StatefulWidget {
  final Widget child;

  const FriendNotificationOverlay({Key? key, required this.child})
      : super(key: key);

  @override
  State<FriendNotificationOverlay> createState() =>
      _FriendNotificationOverlayState();
}

class _FriendNotificationOverlayState extends State<FriendNotificationOverlay> {
  final FriendNotificationService _notificationService =
      FriendNotificationService();
  final TokenStorageService _tokenStorage = TokenStorageService();
  final FriendApiService _friendApiService = FriendApiService();

  Map<String, dynamic>? _currentNotification;
  StreamSubscription<Map<String, dynamic>>? _subscription;

  @override
  void initState() {
    super.initState();
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    await _notificationService.connect();
    _subscription =
        _notificationService.notificationStream.listen((notification) {
      if (notification['type'] == 'friend_request') {
        setState(() {
          _currentNotification = notification;
        });
      }
    });
  }

  Future<void> _handleAccept() async {
    if (_currentNotification == null) return;

    try {
      final accessToken = await _tokenStorage.getAccessToken();
      final userId = await _tokenStorage.getUserId();

      if (accessToken != null && userId != null) {
        // friendIdが通知に含まれていないため、申請一覧から取得する必要がある
        // この場合は承認せずに閉じる（申請画面で承認）
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('フレンドが追加されました。'),
            backgroundColor: Colors.blue,
          ),
        );
        final requesterid = _currentNotification!['requesterId'];

        await _friendApiService.acceptFriendRequestbyId(
            userId, requesterid, accessToken);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {
      _currentNotification = null;
    });
  }

  void _handleDecline() {
    // 拒否の場合も申請画面で行う
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('フレンド申請画面から拒否してください'),
        backgroundColor: Colors.orange,
      ),
    );
    setState(() {
      _currentNotification = null;
    });
  }

  void _handleClose() {
    setState(() {
      _currentNotification = null;
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_currentNotification != null)
          FriendRequestPopup(
            notification: _currentNotification!,
            onAccept: _handleAccept,
            onDecline: _handleDecline,
            onClose: _handleClose,
          ),
      ],
    );
  }
}
