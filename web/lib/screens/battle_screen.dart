import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/token_storage_service.dart';
import '../../models/battle_models.dart';

/// APIのベースURL
const String _apiBaseUrl = String.fromEnvironment(
  "API_BASE_URL",
  defaultValue: "http://localhost:8080",
);

/// バトル画面
/// ランクマッチの対戦進行を行います
class BattleScreen extends StatefulWidget {
  final String matchId;

  const BattleScreen({Key? key, required this.matchId}) : super(key: key);

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen> {
  final _tokenStorage = TokenStorageService();
  final _answerController = TextEditingController();
  final _audioPlayer = AudioPlayer();

  // WebSocket
  StompClient? _stompClient;

  // 状態
  BattleStatus _status = BattleStatus.answering;
  bool _isLoading = true;
  String? _errorMessage;

  // バトル情報
  BattleStartInfo? _battleInfo;
  int? _myUserId;
  String? _myUsername;
  BattlePlayer? _myPlayer;
  BattlePlayer? _opponentPlayer;

  // 現在のラウンド
  BattleQuestion? _currentQuestion;
  int _myWins = 0;
  int _opponentWins = 0;
  bool _myAnswered = false;
  bool _opponentAnswered = false;

  // タイマー
  Timer? _roundTimer;
  int _remainingSeconds = 90;
  bool _isTimedOut = false;

  // ラウンド結果
  RoundResult? _lastRoundResult;
  bool _waitingForOpponentNext = false;  // 相手の「次へ」待ち状態

  // 試合結果
  BattleResult? _battleResult;

  // 勝利に必要な勝ち数
  static const int _winsRequired = 3;

  @override
  void initState() {
    super.initState();
    _initBattle();
  }

  @override
  void dispose() {
    _roundTimer?.cancel();
    _stompClient?.deactivate();
    _answerController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  /// バトル初期化
  Future<void> _initBattle() async {
    try {
      _myUserId = await _tokenStorage.getUserId();
      _myUsername = await _tokenStorage.getUsername();

      if (_myUserId == null) {
        throw Exception('ユーザーIDが見つかりません');
      }

      // バトル情報を取得
      await _loadBattleInfo();

      // WebSocket接続
      _connectWebSocket();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  /// バトル情報を取得
  Future<void> _loadBattleInfo() async {
    final token = await _tokenStorage.getAccessToken();
    if (token == null) {
      throw Exception('認証トークンが見つかりません');
    }

    final response = await http.get(
      Uri.parse('$_apiBaseUrl/api/battle/start/${widget.matchId}'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      _battleInfo = BattleStartInfo.fromJson(data);

      // プレイヤー情報を設定（APIから取得したユーザー情報を使用）
      final isPlayer1 = _battleInfo!.user1Id == _myUserId;

      if (isPlayer1) {
        // 自分がPlayer1の場合
        _myPlayer = _battleInfo!.user1Info ?? BattlePlayer(
          userId: _myUserId!,
          username: _myUsername ?? 'あなた',
          rating: 1500,
        );
        _opponentPlayer = _battleInfo!.user2Info ?? BattlePlayer(
          userId: _battleInfo!.user2Id,
          username: '対戦相手',
          rating: 1500,
        );
      } else {
        // 自分がPlayer2の場合
        _myPlayer = _battleInfo!.user2Info ?? BattlePlayer(
          userId: _myUserId!,
          username: _myUsername ?? 'あなた',
          rating: 1500,
        );
        _opponentPlayer = _battleInfo!.user1Info ?? BattlePlayer(
          userId: _battleInfo!.user1Id,
          username: '対戦相手',
          rating: 1500,
        );
      }

      _remainingSeconds = _battleInfo!.roundTimeLimitSeconds;
    } else {
      throw Exception('バトル情報の取得に失敗しました: ${response.statusCode}');
    }
  }

  /// WebSocket接続
  void _connectWebSocket() {
    _stompClient = StompClient(
      config: StompConfig(
        url: 'ws://localhost:8080/ws',
        webSocketConnectHeaders: {
          'Sec-WebSocket-Protocol': 'v12.stomp',
        },
        onConnect: _onWebSocketConnect,
        onWebSocketError: (error) {
          if (!mounted) return;
          setState(() {
            _errorMessage = 'WebSocket接続エラー: $error';
            _isLoading = false;
          });
        },
        onStompError: (frame) {
          if (!mounted) return;
          setState(() {
            _errorMessage = 'STOMPエラー: ${frame.body}';
            _isLoading = false;
          });
        },
        onDisconnect: (frame) {
          _roundTimer?.cancel();
        },
      ),
    );

    _stompClient!.activate();
  }

  /// WebSocket接続完了
  void _onWebSocketConnect(StompFrame frame) {
    if (!mounted) return;

    // ユーザー専用トピックを購読
    _stompClient!.subscribe(
      destination: '/topic/battle/$_myUserId',
      callback: (StompFrame frame) {
        if (frame.body == null) return;
        final data = jsonDecode(frame.body!);
        _handleBattleMessage(data);
      },
    );

    // バトル準備完了を送信
    _stompClient!.send(
      destination: '/app/battle/ready',
      body: jsonEncode({
        'matchId': widget.matchId,
        'userId': _myUserId,
      }),
    );

    setState(() {
      _isLoading = false;
    });
  }

  /// バトルメッセージを処理
  void _handleBattleMessage(Map<String, dynamic> data) {
    final type = data['type'];

    switch (type) {
      case 'question':
        _handleQuestionMessage(data);
        break;
      case 'answer_received':
        _handleAnswerReceived(data);
        break;
      case 'opponent_answered':
        _handleOpponentAnswered(data);
        break;
      case 'round_result':
        _handleRoundResult(data);
        break;
      case 'battle_result':
        _handleBattleResult(data);
        break;
      case 'opponent_surrendered':
        _handleOpponentSurrendered(data);
        break;
      case 'waiting_opponent_next':
        _handleWaitingOpponentNext(data);
        break;
      case 'error':
        _handleError(data);
        break;
    }
  }

  /// 問題受信
  void _handleQuestionMessage(Map<String, dynamic> data) {
    if (!mounted) return;

    final questionData = data['question'];
    if (questionData == null) return;

    setState(() {
      _currentQuestion = BattleQuestion.fromJson(questionData);
      _myWins = data['player1Wins'] ?? _myWins;
      _opponentWins = data['player2Wins'] ?? _opponentWins;

      // プレイヤー1かどうかで勝ち数を調整
      if (_battleInfo != null && _battleInfo!.user1Id != _myUserId) {
        final temp = _myWins;
        _myWins = _opponentWins;
        _opponentWins = temp;
      }

      _myAnswered = false;
      _opponentAnswered = false;
      _isTimedOut = false;
      _waitingForOpponentNext = false;  // リセット
      _status = BattleStatus.answering;
      _answerController.clear();
      // サーバー時刻に基づいて残り時間を計算（画面更新時もリセットされない）
      _remainingSeconds = _currentQuestion?.calculateRemainingSeconds()
          ?? _battleInfo?.roundTimeLimitSeconds
          ?? 90;
    });

    // タイマー開始
    _startRoundTimer();
  }

  /// 回答受付確認
  void _handleAnswerReceived(Map<String, dynamic> data) {
    if (!mounted) return;
    setState(() {
      _myAnswered = true;
      if (_status == BattleStatus.submitting) {
        _status = BattleStatus.waitingOpponent;
      }
    });
  }

  /// 相手の回答通知
  void _handleOpponentAnswered(Map<String, dynamic> data) {
    if (!mounted) return;
    setState(() {
      _opponentAnswered = true;
    });
  }

  /// ラウンド結果
  void _handleRoundResult(Map<String, dynamic> data) {
    if (!mounted) return;
    _roundTimer?.cancel();

    final resultData = data['result'];
    if (resultData == null) return;

    setState(() {
      _lastRoundResult = RoundResult.fromJson(resultData);

      // 勝ち数を更新（プレイヤー視点）
      if (_battleInfo != null && _battleInfo!.user1Id == _myUserId) {
        _myWins = _lastRoundResult!.player1Wins;
        _opponentWins = _lastRoundResult!.player2Wins;
      } else {
        _myWins = _lastRoundResult!.player2Wins;
        _opponentWins = _lastRoundResult!.player1Wins;
      }

      // 必ずラウンド結果表示状態に遷移（スキップしない）
      _status = BattleStatus.roundResult;
    });

    // 試合継続の場合は、ユーザーが「次へ」を押すまで待機
    // 自動遷移しない（ラウンド結果がスキップされないようにするため）
  }

  /// 試合結果
  void _handleBattleResult(Map<String, dynamic> data) {
    if (!mounted) return;
    _roundTimer?.cancel();

    setState(() {
      _battleResult = BattleResult.fromJson(data);
      _status = BattleStatus.matchFinished;
    });
  }

  /// 相手が降参
  void _handleOpponentSurrendered(Map<String, dynamic> data) {
    if (!mounted) return;
    _roundTimer?.cancel();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('相手が降参しました'),
        backgroundColor: Colors.orange,
      ),
    );

    // 結果が来るのを待つ
  }

  /// エラー
  void _handleError(Map<String, dynamic> data) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('エラー: ${data['message']}'),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// 相手の「次へ」待ち
  void _handleWaitingOpponentNext(Map<String, dynamic> data) {
    if (!mounted) return;
    setState(() {
      _waitingForOpponentNext = true;
    });
  }

  /// ラウンドタイマー開始
  void _startRoundTimer() {
    _roundTimer?.cancel();
    _roundTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _remainingSeconds--;
      });

      if (_remainingSeconds <= 0) {
        timer.cancel();
        _onTimeout();
      }
    });
  }

  /// タイムアウト処理
  void _onTimeout() {
    setState(() {
      _isTimedOut = true;
    });

    if (_status == BattleStatus.answering && !_myAnswered) {
      // 未回答の場合、サーバーにタイムアウトを通知
      _stompClient?.send(
        destination: '/app/battle/timeout',
        body: jsonEncode({
          'matchId': widget.matchId,
          'userId': _myUserId,
        }),
      );
    }

    setState(() {
      if (_status != BattleStatus.roundResult && _status != BattleStatus.matchFinished) {
        _status = BattleStatus.waitingOpponent;
      }
    });
  }

  /// 回答送信
  void _submitAnswer() {
    if (_status != BattleStatus.answering || _myAnswered) return;

    final answer = _answerController.text.trim();
    if (answer.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('回答を入力してください'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _status = BattleStatus.submitting;
    });

    _stompClient?.send(
      destination: '/app/battle/answer',
      body: jsonEncode({
        'matchId': widget.matchId,
        'userId': _myUserId,
        'answer': answer,
      }),
    );
  }

  /// 次のラウンドへ進む（「次へ」ボタン押下時）
  void _goToNextRound() {
    if (_lastRoundResult == null || !_lastRoundResult!.matchContinues) return;
    if (_waitingForOpponentNext) return; // 既にリクエスト済み

    // サーバーに次のラウンドへ進むリクエストを送信
    _stompClient?.send(
      destination: '/app/battle/next-round',
      body: jsonEncode({
        'matchId': widget.matchId,
        'userId': _myUserId,
      }),
    );

    // 相手の「次へ」待ち状態に設定（問題受信まで待機）
    // サーバーから両者準備完了またはタイムアウトでquestionが来る
    setState(() {
      _waitingForOpponentNext = true;
    });
  }

  /// 降参
  Future<void> _surrender() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('降参'),
        content: const Text('本当に降参しますか？\nこの対戦は敗北となります。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('降参する'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _roundTimer?.cancel();
      _stompClient?.send(
        destination: '/app/battle/surrender',
        body: jsonEncode({
          'matchId': widget.matchId,
          'userId': _myUserId,
        }),
      );
    }
  }

  /// 音声再生（エラー時も進行を妨げない）
  Future<void> _playAudio() async {
    if (_currentQuestion == null || _currentQuestion!.audioUrl == null || _currentQuestion!.audioUrl!.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('音声データがありません（回答は可能です）'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    try {
      String audioUrl = _currentQuestion!.audioUrl!;
      String originalUrl = audioUrl;  // デバッグ用に元のURLを保存

      // 相対パスの場合、ベースURLを追加（学習側と同じ処理）
      if (!audioUrl.startsWith('http://') && !audioUrl.startsWith('https://')) {
        // ./ で始まる場合は除去
        if (audioUrl.startsWith('./')) {
          audioUrl = audioUrl.substring(2);
        }
        // 先頭に / がない場合は追加
        if (!audioUrl.startsWith('/')) {
          audioUrl = '/$audioUrl';
        }
        audioUrl = '$_apiBaseUrl$audioUrl';
      }

      // デバッグログ（学習側との比較用）
      debugPrint('=== Audio Debug ===');
      debugPrint('Original audioUrl: $originalUrl');
      debugPrint('Final audioUrl: $audioUrl');
      debugPrint('API Base URL: $_apiBaseUrl');
      debugPrint('==================');

      await _audioPlayer.play(UrlSource(audioUrl));
    } catch (e) {
      // 音声再生失敗時もユーザーは回答可能
      debugPrint('Audio play error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('音声の再生に失敗しました（回答は可能です）\n$e'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      // エラーを投げずに続行（進行を止めない）
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_status != BattleStatus.matchFinished) {
          final shouldExit = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('バトルを終了'),
              content: const Text('バトル中に退出すると敗北扱いになります。\n本当に終了しますか？'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('いいえ'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('終了する'),
                ),
              ],
            ),
          );

          if (shouldExit == true) {
            _surrender();
          }
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        body: SafeArea(
          child: _isLoading
              ? _buildLoading()
              : _errorMessage != null
                  ? _buildError()
                  : _buildBattleContent(),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(strokeWidth: 6),
          SizedBox(height: 24),
          Text(
            'バトルを準備中...',
            style: TextStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 64),
            const SizedBox(height: 24),
            Text(
              'エラーが発生しました',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 16),
            Text(_errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
              child: const Text('ホームに戻る'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBattleContent() {
    return Column(
      children: [
        // ヘッダー（プレイヤー情報とスコア）
        _buildHeader(),

        // タイマー
        _buildTimer(),

        // メインコンテンツ
        Expanded(
          child: _status == BattleStatus.roundResult
              ? _buildRoundResultContent()
              : _status == BattleStatus.matchFinished
                  ? _buildMatchFinishedContent()
                  : _buildQuestionContent(),
        ),
      ],
    );
  }

  /// ヘッダー（プレイヤー情報とスコア）
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          // 自分
          Expanded(
            child: _buildPlayerInfo(
              player: _myPlayer,
              wins: _myWins,
              hasAnswered: _myAnswered,
              isMe: true,
            ),
          ),

          // VS とスコア
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                const Text(
                  'VS',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 8),
                // スコア表示（○→✓形式）
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildScoreIndicator(_myWins, true),
                    const SizedBox(width: 8),
                    const Text('-', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    _buildScoreIndicator(_opponentWins, false),
                  ],
                ),
              ],
            ),
          ),

          // 相手
          Expanded(
            child: _buildPlayerInfo(
              player: _opponentPlayer,
              wins: _opponentWins,
              hasAnswered: _opponentAnswered,
              isMe: false,
            ),
          ),
        ],
      ),
    );
  }

  /// スコア表示（○○○ → ✓○○ → ✓✓○ → ✓✓✓）
  Widget _buildScoreIndicator(int wins, bool isMe) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_winsRequired, (index) {
        final isWon = index < wins;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isWon
                ? (isMe ? Colors.blue : Colors.orange)
                : Colors.grey[300],
            border: Border.all(
              color: isWon
                  ? (isMe ? Colors.blue[700]! : Colors.orange[700]!)
                  : Colors.grey[400]!,
              width: 2,
            ),
          ),
          child: isWon
              ? const Icon(Icons.check, color: Colors.white, size: 14)
              : null,
        );
      }),
    );
  }

  /// プレイヤー情報
  Widget _buildPlayerInfo({
    required BattlePlayer? player,
    required int wins,
    required bool hasAnswered,
    required bool isMe,
  }) {
    return Column(
      children: [
        // アイコン（回答済みなら✓マーク）
        Stack(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: isMe ? Colors.blue[100] : Colors.orange[100],
              backgroundImage: player?.iconUrl != null
                  ? NetworkImage('$_apiBaseUrl/images/${player!.iconUrl}')
                  : null,
              child: player?.iconUrl == null
                  ? Icon(
                      Icons.person,
                      size: 28,
                      color: isMe ? Colors.blue : Colors.orange,
                    )
                  : null,
            ),
            if (hasAnswered)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        // ユーザー名
        Text(
          isMe ? 'あなた' : (player?.username ?? '対戦相手'),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        // レート
        if (player?.rating != null)
          Text(
            'Rate: ${player!.rating}',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
      ],
    );
  }

  /// タイマー
  Widget _buildTimer() {
    final isWarning = _remainingSeconds <= 10;
    final isTimeout = _remainingSeconds <= 0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      color: isTimeout
          ? Colors.grey[300]
          : isWarning
              ? Colors.red[50]
              : Colors.blue[50],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isTimeout ? Icons.timer_off : Icons.timer,
            color: isTimeout ? Colors.grey : (isWarning ? Colors.red : Colors.blue),
          ),
          const SizedBox(width: 8),
          if (isTimeout)
            Text(
              '時間切れ。結果確定を待っています...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            )
          else
            Text(
              '残り ${_remainingSeconds}秒',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isWarning ? Colors.red : Colors.blue,
              ),
            ),
          if (_currentQuestion != null && !isTimeout) ...[
            const SizedBox(width: 20),
            Text(
              'Round ${_currentQuestion!.roundNumber} / ${_currentQuestion!.totalRounds}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 問題コンテンツ
  Widget _buildQuestionContent() {
    if (_currentQuestion == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // 問題タイプに応じて表示を切り替え
    final isListening = _currentQuestion!.isListening;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 降参ボタン
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _surrender,
              icon: const Icon(Icons.flag, color: Colors.red),
              label: const Text('降参', style: TextStyle(color: Colors.red)),
            ),
          ),

          const SizedBox(height: 12),

          // 問題タイプ表示
          _buildQuestionTypeChip(isListening),

          const SizedBox(height: 16),

          // 問題表示領域
          if (isListening)
            _buildListeningQuestion()
          else
            _buildFillInBlankQuestion(),

          const SizedBox(height: 24),

          // 状態メッセージ
          if (_status == BattleStatus.waitingOpponent)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text(
                    '相手の解答を待っています...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            )
          else if (_status == BattleStatus.submitting)
            const Center(child: CircularProgressIndicator())
          else ...[
            // 解答入力欄
            TextField(
              controller: _answerController,
              enabled: _status == BattleStatus.answering && !_myAnswered && !_isTimedOut,
              decoration: InputDecoration(
                hintText: isListening
                    ? '聞こえた文を入力してください'
                    : '答えを入力してください',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
              onSubmitted: (_) => _submitAnswer(),
            ),

            const SizedBox(height: 20),

            // 解答ボタン
            ElevatedButton(
              onPressed: _status == BattleStatus.answering && !_myAnswered && !_isTimedOut
                  ? _submitAnswer
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                '解答する',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 問題タイプ表示チップ
  Widget _buildQuestionTypeChip(bool isListening) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isListening ? Colors.blue[100] : Colors.green[100],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isListening ? Icons.headphones : Icons.edit,
              size: 20,
              color: isListening ? Colors.blue : Colors.green,
            ),
            const SizedBox(width: 8),
            Text(
              isListening ? 'リスニング問題' : '虫食い問題',
              style: TextStyle(
                color: isListening ? Colors.blue : Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// リスニング問題表示（問題文は非表示）
  Widget _buildListeningQuestion() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.headphones,
            size: 64,
            color: Colors.blue,
          ),
          const SizedBox(height: 16),
          const Text(
            '音声を聞いて入力してください',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          // 音声再生ボタン
          ElevatedButton.icon(
            onPressed: _playAudio,
            icon: const Icon(Icons.play_arrow),
            label: const Text('再生'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  /// 虫食い問題表示
  Widget _buildFillInBlankQuestion() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '問題 ${_currentQuestion!.roundNumber}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _currentQuestion!.text,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          if (_currentQuestion!.translationJa != null) ...[
            const SizedBox(height: 16),
            Text(
              _currentQuestion!.translationJa!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  /// ラウンド結果コンテンツ
  Widget _buildRoundResultContent() {
    if (_lastRoundResult == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final result = _lastRoundResult!;
    final isMyWin = result.roundWinnerId == _myUserId;
    final isNoCount = result.isNoCount;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 結果アイコン
            Icon(
              isNoCount
                  ? Icons.remove_circle_outline
                  : isMyWin
                      ? Icons.check_circle
                      : Icons.cancel,
              size: 80,
              color: isNoCount
                  ? Colors.grey
                  : isMyWin
                      ? Colors.green
                      : Colors.red,
            ),

            const SizedBox(height: 16),

            // 結果テキスト
            Text(
              isNoCount
                  ? result.noCountReasonText
                  : isMyWin
                      ? 'あなたの勝ち！'
                      : '相手の勝ち',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isNoCount
                    ? Colors.grey
                    : isMyWin
                        ? Colors.green
                        : Colors.red,
              ),
            ),

            const SizedBox(height: 24),

            // 正解
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text('正解', style: TextStyle(fontSize: 14)),
                  const SizedBox(height: 8),
                  Text(
                    result.correctAnswer,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 現在のスコア（○→✓形式）
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildScoreIndicator(_myWins, true),
                const SizedBox(width: 16),
                Text(
                  '$_myWins - $_opponentWins',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 16),
                _buildScoreIndicator(_opponentWins, false),
              ],
            ),

            const SizedBox(height: 32),

            // 次へボタン（試合継続の場合のみ）
            if (result.matchContinues)
              _waitingForOpponentNext
                  ? Column(
                      children: [
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '相手の準備を待っています...',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    )
                  : ElevatedButton.icon(
                      onPressed: _goToNextRound,
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('次の問題へ'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    )
            else
              // 試合終了時：結果が受信済みなら「結果を見る」、まだなら待機表示
              _battleResult != null
                  ? ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _status = BattleStatus.matchFinished;
                        });
                      },
                      icon: const Icon(Icons.emoji_events),
                      label: const Text('結果を見る'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    )
                  : Column(
                      children: [
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '結果を取得中...',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
          ],
        ),
      ),
    );
  }

  /// 試合終了コンテンツ
  Widget _buildMatchFinishedContent() {
    if (_battleResult == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final result = _battleResult!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 結果アイコン
            Icon(
              result.isWin
                  ? Icons.emoji_events
                  : result.isDraw
                      ? Icons.handshake
                      : Icons.sentiment_dissatisfied,
              size: 100,
              color: result.isWin
                  ? Colors.amber
                  : result.isDraw
                      ? Colors.grey
                      : Colors.blue,
            ),

            const SizedBox(height: 24),

            // 結果テキスト
            Text(
              result.resultText,
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: result.isWin
                    ? Colors.amber[700]
                    : result.isDraw
                        ? Colors.grey
                        : Colors.blue,
              ),
            ),

            Text(
              result.outcomeReasonText,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),

            const SizedBox(height: 32),

            // スコア（○→✓形式）
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildScoreIndicator(result.myScore, true),
                const SizedBox(width: 16),
                Text(
                  '${result.myScore} - ${result.opponentScore}',
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 16),
                _buildScoreIndicator(result.opponentScore, false),
              ],
            ),

            const SizedBox(height: 24),

            // レート変動
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: result.rateChange >= 0 ? Colors.green[50] : Colors.red[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    result.rateChange >= 0
                        ? '+${result.rateChange}'
                        : '${result.rateChange}',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: result.rateChange >= 0 ? Colors.green : Colors.red,
                    ),
                  ),
                  Text(
                    '新しいレート: ${result.newRate}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 48),

            // ボタン群（3つ横並び、または縦並び）
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 16,
              runSpacing: 12,
              children: [
                // 再キューボタン
                ElevatedButton.icon(
                  onPressed: _goToRematch,
                  icon: const Icon(Icons.refresh),
                  label: const Text('再キュー'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),

                // 単語帳ボタン
                ElevatedButton.icon(
                  onPressed: _goToVocabulary,
                  icon: const Icon(Icons.book),
                  label: const Text('単語帳'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),

                // ホームに戻るボタン
                ElevatedButton.icon(
                  onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                  icon: const Icon(Icons.home),
                  label: const Text('ホーム'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 再キュー（同じ設定で再マッチング）
  void _goToRematch() {
    // WebSocket接続を切断
    _stompClient?.deactivate();
    _roundTimer?.cancel();

    // 直前のマッチ設定（言語）を使って再マッチへ遷移
    final language = _battleInfo?.language ?? 'english';
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/matching?language=$language',
      (route) => route.isFirst,
    );
  }

  /// 単語帳画面へ遷移
  void _goToVocabulary() {
    // ホームに戻ってから単語帳画面へ
    Navigator.popUntil(context, (route) => route.isFirst);
    // userIdをクエリパラメータとして渡す
    Navigator.pushNamed(context, '/vocabulary?userId=$_myUserId');
  }
}
