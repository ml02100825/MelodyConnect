import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../services/token_storage_service.dart';
import '../models/battle_models.dart';

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

  // ラウンド結果
  RoundResult? _lastRoundResult;

  // 試合結果
  BattleResult? _battleResult;

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
      Uri.parse('http://localhost:8080/api/battle/start/${widget.matchId}'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      _battleInfo = BattleStartInfo.fromJson(data);

      // プレイヤー情報を設定
      final isPlayer1 = _battleInfo!.user1Id == _myUserId;
      _myPlayer = BattlePlayer(
        userId: _myUserId!,
        username: _myUsername ?? 'あなた',
        rating: 1500, // TODO: 実際のレートを取得
      );
      _opponentPlayer = BattlePlayer(
        userId: isPlayer1 ? _battleInfo!.user2Id : _battleInfo!.user1Id,
        username: '対戦相手', // TODO: 相手のユーザー名を取得
        rating: 1500, // TODO: 実際のレートを取得
      );

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
      _status = BattleStatus.answering;
      _answerController.clear();
      _remainingSeconds = _battleInfo?.roundTimeLimitSeconds ?? 90;
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

      _status = BattleStatus.roundResult;
    });

    // 一定時間後に次のラウンドへ（試合継続の場合）
    if (_lastRoundResult!.matchContinues) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _status == BattleStatus.roundResult) {
          setState(() {
            _status = BattleStatus.answering;
          });
        }
      });
    }
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

  /// リザルト画面へ遷移
  void _navigateToResult() {
    if (_battleResult == null) return;

    Navigator.pushReplacementNamed(
      context,
      '/battle-result',
      arguments: _battleResult,
    );
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
        // ヘッダー（プレイヤー情報）
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

  /// ヘッダー（プレイヤー情報）
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

          // VS
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                const Text(
                  'VS',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$_myWins - $_opponentWins',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
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
              radius: 30,
              backgroundColor: isMe ? Colors.blue[100] : Colors.orange[100],
              backgroundImage: player?.iconUrl != null
                  ? NetworkImage('http://localhost:8080/images/${player!.iconUrl}')
                  : null,
              child: player?.iconUrl == null
                  ? Icon(
                      Icons.person,
                      size: 32,
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
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        // ユーザー名
        Text(
          isMe ? 'あなた' : (player?.username ?? '対戦相手'),
          style: const TextStyle(
            fontSize: 14,
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
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
      ],
    );
  }

  /// タイマー
  Widget _buildTimer() {
    final isWarning = _remainingSeconds <= 10;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      color: isWarning ? Colors.red[50] : Colors.blue[50],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.timer,
            color: isWarning ? Colors.red : Colors.blue,
          ),
          const SizedBox(width: 8),
          Text(
            '残り ${_remainingSeconds}秒',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isWarning ? Colors.red : Colors.blue,
            ),
          ),
          if (_currentQuestion != null) ...[
            const SizedBox(width: 24),
            Text(
              'Round ${_currentQuestion!.roundNumber} / ${_currentQuestion!.totalRounds}',
              style: TextStyle(
                fontSize: 16,
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

          const SizedBox(height: 16),

          // 問題文
          Container(
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
          ),

          const SizedBox(height: 32),

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
              enabled: _status == BattleStatus.answering && !_myAnswered,
              decoration: InputDecoration(
                hintText: '答えを入力してください',
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

            const SizedBox(height: 24),

            // 解答ボタン
            ElevatedButton(
              onPressed: _status == BattleStatus.answering && !_myAnswered
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
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 現在のスコア
            Text(
              'スコア: $_myWins - $_opponentWins',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            if (result.matchContinues)
              const Text(
                '次の問題を準備中...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
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

            // スコア
            Text(
              '${result.myScore} - ${result.opponentScore}',
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
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

            // ホームに戻るボタン
            ElevatedButton.icon(
              onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
              icon: const Icon(Icons.home),
              label: const Text('ホームに戻る'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
