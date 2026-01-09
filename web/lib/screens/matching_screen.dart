import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../services/token_storage_service.dart';
import 'package:http/http.dart' as http;

/// マッチング画面
/// WebSocket接続でリアルタイムマッチングを行います
class MatchingScreen extends StatefulWidget {
  final String language;

  const MatchingScreen({Key? key, required this.language}) : super(key: key);

  @override
  State<MatchingScreen> createState() => _MatchingScreenState();
}

class _MatchingScreenState extends State<MatchingScreen> {
  final _tokenStorage = TokenStorageService();
  StompClient? _stompClient;
  bool _isConnecting = true;
  bool _isMatching = false;
  String _statusMessage = 'サーバーに接続中...';
  int _waitTime = 0;
  Timer? _waitTimer;

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
  }

  @override
  void dispose() {
    _waitTimer?.cancel();
    _stompClient?.deactivate();
    super.dispose();
  }

  /// WebSocket接続とマッチングキューへの参加
  Future<void> _connectWebSocket() async {
    try {
      final userId = await _tokenStorage.getUserId();
      if (userId == null) {
        if (!mounted) return;
        setState(() {
          _isConnecting = false;
          _isMatching = false;
          _statusMessage = 'ユーザーIDが見つかりません';
        });
        return;
      }

      // STOMP WebSocket接続
      _stompClient = StompClient(
        config: StompConfig(
          url: 'ws://localhost:8080/ws',
          stompConnectHeaders: {
            if (userId != null) 'userId': userId.toString(),
          },
          webSocketConnectHeaders: {
            'Sec-WebSocket-Protocol': 'v12.stomp',
          },
          onConnect: (StompFrame frame) {
            if (!mounted) return;

            setState(() {
              _isConnecting = false;
              _isMatching = true;
              _statusMessage = 'マッチング相手を探しています...';
            });

            // ユーザー専用トピックを購読
            _stompClient!.subscribe(
              destination: '/topic/matching/$userId',
              callback: (StompFrame frame) {
                if (frame.body == null) return;

                final data = jsonDecode(frame.body!);
                _handleMatchingMessage(data);
              },
            );

            // マッチングキューに参加
            _stompClient!.send(
              destination: '/app/matching/join',
              body: jsonEncode({
                'userId': userId,
                'language': widget.language,
              }),
            );

            // 待機時間タイマーを開始
            _startWaitTimer();
          },
          onWebSocketError: (dynamic error) {
            if (!mounted) return;

            setState(() {
              _isConnecting = false;
              _isMatching = false;
              _statusMessage = 'WebSocket接続エラー: $error';
            });
          },
          onStompError: (StompFrame frame) {
            if (!mounted) return;

            setState(() {
              _isConnecting = false;
              _isMatching = false;
              _statusMessage = 'STOMPエラー: ${frame.body}';
            });
          },
        ),
      );

      _stompClient!.activate();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isConnecting = false;
        _isMatching = false;
        _statusMessage = 'エラー: ${e.toString()}';
      });
    }
  }

  /// 待機時間タイマーを開始
  void _startWaitTimer() {
    _waitTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _waitTime++;
      });
    });
  }

  /// マッチングメッセージを処理
  void _handleMatchingMessage(Map<String, dynamic> data) {
    final status = data['status'];
    final code = data['code'];

    if (status == 'joined') {
      // キュー参加成功
      if (!mounted) return;
      setState(() {
        _statusMessage = 'マッチング相手を探しています...';
      });
    } else if (status == 'matched') {
      // マッチング成立
      _waitTimer?.cancel();
      _onMatchFound(data);
    } else if (status == 'timeout') {
      // タイムアウト
      _waitTimer?.cancel();
      if (!mounted) return;

      setState(() {
        _isMatching = false;
        _statusMessage = 'マッチングがタイムアウトしました（15分経過）';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('マッチングがタイムアウトしました'),
          backgroundColor: Colors.orange,
        ),
      );

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.pop(context);
        }
      });
    } else if (status == 'error') {
      // エラー
      _waitTimer?.cancel();
      if (!mounted) return;

      if (code == 'INSUFFICIENT_LIFE') {
        // ライフ不足エラー
        _handleInsufficientLife(data);
      } else {
        setState(() {
          _isMatching = false;
          _statusMessage = 'エラー: ${data['message']}';
        });
      }
    }
  }

  /// ライフ不足エラーを処理
  void _handleInsufficientLife(Map<String, dynamic> data) {
    final currentLife = data['currentLife'] ?? 0;
    final nextRecoveryInSeconds = data['nextRecoveryInSeconds'] ?? 600;

    setState(() {
      _isMatching = false;
      _statusMessage = 'ライフが不足しています';
    });

    // ダイアログを表示
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('ライフが不足しています'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.music_off,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'ランクマッチにはライフが必要です\n現在のライフ: $currentLife',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(
              '次の回復まで: ${_formatRecoveryTime(nextRecoveryInSeconds)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // ダイアログを閉じる
              Navigator.pop(context); // マッチング画面を閉じる
            },
            child: const Text('戻る'),
          ),
        ],
      ),
    );
  }

  /// 秒数を分:秒形式にフォーマット
  String _formatRecoveryTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  /// マッチング成立時の処理
  void _onMatchFound(Map<String, dynamic> data) async {
    if (!mounted) return;

    setState(() {
      _statusMessage = 'マッチング成立！バトルを開始します...';
    });

    // マッチング成功メッセージを表示
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('マッチングが成立しました！'),
        backgroundColor: Colors.green,
      ),
    );

    // 少し待ってからバトル画面に遷移
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    // バトル画面に遷移
    final matchId = data['matchId'];
    Navigator.pushReplacementNamed(
      context,
      '/battle?matchId=$matchId',
    );
  }

  /// マッチングをキャンセル
  Future<void> _cancelMatching() async {
    try {
      final userId = await _tokenStorage.getUserId();
      if (userId == null) return;

      // キャンセルメッセージを送信
      _stompClient?.send(
        destination: '/app/matching/cancel',
        body: jsonEncode({
          'userId': userId,
        }),
      );

      _waitTimer?.cancel();
      _stompClient?.deactivate();

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('キャンセルに失敗しました: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 待機時間を分:秒形式で取得
  String get _formattedWaitTime {
    final minutes = _waitTime ~/ 60;
    final seconds = _waitTime % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isMatching) {
          // マッチング中の場合、確認ダイアログを表示
          final shouldCancel = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('マッチングをキャンセル'),
              content: const Text('マッチングを中止してもよろしいですか？'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('いいえ'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('はい'),
                ),
              ],
            ),
          );

          if (shouldCancel == true) {
            await _cancelMatching();
            return false; // WillPopScopeがナビゲーションを処理する
          }
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('マッチング'),
          centerTitle: true,
          automaticallyImplyLeading: !_isConnecting,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ローディングアニメーション
                if (_isConnecting || _isMatching)
                  const CircularProgressIndicator(
                    strokeWidth: 6,
                  ),
                const SizedBox(height: 32),

                // ステータスメッセージ
                Text(
                  _statusMessage,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // 待機時間表示
                if (_isMatching) ...[
                  const SizedBox(height: 16),
                  Text(
                    '待機時間',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formattedWaitTime,
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_waitTime >= 90)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'レーティング許容範囲が拡大しました (±200)',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    Text(
                      'レーティング許容範囲: ±150',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                ],

                const SizedBox(height: 48),

                // キャンセルボタン
                if (_isMatching)
                  ElevatedButton(
                    onPressed: _cancelMatching,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 48,
                        vertical: 16,
                      ),
                    ),
                    child: const Text(
                      'キャンセル',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
