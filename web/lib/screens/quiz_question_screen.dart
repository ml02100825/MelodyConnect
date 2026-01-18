import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/quiz_models.dart';
import '../services/quiz_api_service.dart';
import '../services/token_storage_service.dart';
import 'quiz_result_screen.dart';

/// ★ 追加: APIのベースURL
const String _apiBaseUrl = String.fromEnvironment(
  "API_BASE_URL",
  defaultValue: "http://localhost:8080",
);

class QuizQuestionScreen extends StatefulWidget {
  final int sessionId;
  final int userId;
  final List<QuizQuestion> questions;
  final SongInfo? songInfo;

  const QuizQuestionScreen({
    super.key,
    required this.sessionId,
    required this.userId,
    required this.questions,
    this.songInfo,
  });

  @override
  State<QuizQuestionScreen> createState() => _QuizQuestionScreenState();
}

class _QuizQuestionScreenState extends State<QuizQuestionScreen> {
  final QuizApiService _apiService = QuizApiService();
  final TokenStorageService _tokenStorage = TokenStorageService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final TextEditingController _answerController = TextEditingController();

  int _currentIndex = 0;
  List<AnswerResult> _answers = [];
  bool _isSubmitting = false;
  bool _showResult = false;
  bool _isCorrect = false;
  String _correctAnswer = '';
  String? _accessToken;
  
  // ★ 追加: 音声再生スピード（0.75x = スロー、1.0x = 通常）
  // 英語学習アプリ（Duolingo, iKnow!等）では0.75xが一般的
  double _playbackSpeed = 1.0;
  static const double _normalSpeed = 1.0;
  static const double _slowSpeed = 0.75;

  @override
  void initState() {
    super.initState();
    _loadAccessToken();
    // ★ デバッグ: 問題データを確認
    _debugPrintQuestions();
  }

  /// ★ 追加: デバッグ用 - 問題データをログ出力
  void _debugPrintQuestions() {
    debugPrint('=== Quiz Questions Debug ===');
    debugPrint('Total questions: ${widget.questions.length}');
    for (int i = 0; i < widget.questions.length; i++) {
      final q = widget.questions[i];
      debugPrint('Question $i:');
      debugPrint('  - questionId: ${q.questionId}');
      debugPrint('  - text: ${q.text}');
      debugPrint('  - questionFormat: "${q.questionFormat}"');
      debugPrint('  - answer: "${q.answer}"');
      debugPrint('  - audioUrl: ${q.audioUrl}');
      debugPrint('  - difficultyLevel: ${q.difficultyLevel}');
    }
    debugPrint('============================');
  }

  Future<void> _loadAccessToken() async {
    final token = await _tokenStorage.getAccessToken();
    setState(() {
      _accessToken = token;
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _answerController.dispose();
    super.dispose();
  }

  QuizQuestion get _currentQuestion => widget.questions[_currentIndex];
  bool get _isLastQuestion => _currentIndex == widget.questions.length - 1;
  
  /// ★ 修正: リスニング問題の判定を改善
  /// "listening" の他に、大文字小文字の違いや空白も考慮
  bool get _isListening {
    final format = _currentQuestion.questionFormat.toLowerCase().trim();
    debugPrint('_isListening check: format="$format", result=${format == 'listening'}');
    return format == 'listening';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('問題 ${_currentIndex + 1}/${widget.questions.length}'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: _showRetireDialog,
            child: const Text(
              'リタイア',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // プログレスバー
              _buildProgressBar(),
              const SizedBox(height: 12),
              
              // ★ 追加: 曲情報
              if (widget.songInfo != null) _buildSongInfoChip(),
              const SizedBox(height: 12),

              // 問題タイプ表示
              _buildQuestionTypeChip(),
              const SizedBox(height: 16),

              // 問題内容
              Expanded(
                child: _showResult
                    ? _buildResultView()
                    : _buildQuestionView(),
              ),

              // 回答入力・ボタン
              if (!_showResult) ...[
                _buildAnswerInput(),
                const SizedBox(height: 16),
                _buildSubmitButton(),
              ] else ...[
                _buildNextButton(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Column(
      children: [
        LinearProgressIndicator(
          value: (_currentIndex + 1) / widget.questions.length,
          backgroundColor: Colors.grey.shade200,
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.deepPurple),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '難易度: ${'★' * _currentQuestion.difficultyLevel}',
              style: const TextStyle(color: Colors.amber),
            ),
            Text(
              '${_currentIndex + 1} / ${widget.questions.length}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  /// ★ 追加: 曲情報を表示
  Widget _buildSongInfoChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.music_note, size: 16, color: Colors.purple.shade600),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              '${widget.songInfo!.artistName} - ${widget.songInfo!.songName}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.purple.shade800,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionTypeChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _isListening ? Colors.blue.shade100 : Colors.green.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isListening ? Icons.headphones : Icons.edit,
            size: 20,
            color: _isListening ? Colors.blue : Colors.green,
          ),
          const SizedBox(width: 8),
          Text(
            _isListening ? 'リスニング問題' : '虫食い問題',
            style: TextStyle(
              color: _isListening ? Colors.blue : Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
          // ★ デバッグ用: 実際のquestionFormat値を表示
          const SizedBox(width: 8),
          Text(
            '(${_currentQuestion.questionFormat})',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionView() {
    if (_isListening) {
      return _buildListeningQuestion();
    } else {
      return _buildFillInBlankQuestion();
    }
  }

  Widget _buildListeningQuestion() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.headphones,
          size: 80,
          color: Colors.deepPurple,
        ),
        const SizedBox(height: 24),
        const Text(
          '音声を聞いて、聞こえた文を入力してください',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 24),
        // ★ 再生ボタンとスピード切り替え（画面幅に応じて折り返し）
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [
            // 通常再生ボタン
            ElevatedButton.icon(
              onPressed: _playAudio,
              icon: const Icon(Icons.play_arrow),
              label: const Text('再生'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
            ),
            // スピード切り替えボタン
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSpeedButton(_normalSpeed, '1x'),
                  _buildSpeedButton(_slowSpeed, '遅い'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // スピード説明
        Text(
          _playbackSpeed == _slowSpeed 
              ? '🐢 ゆっくり再生 (0.75x)' 
              : '🎵 通常再生',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        // デバッグ用: audioUrl表示（開発時のみ）
        if (_currentQuestion.audioUrl != null) ...[
          const SizedBox(height: 16),
          Text(
            'Audio: ${_currentQuestion.audioUrl}',
            style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  /// ★ 追加: スピード切り替えボタン
  Widget _buildSpeedButton(double speed, String label) {
    final isSelected = _playbackSpeed == speed;
    return GestureDetector(
      onTap: () {
        setState(() {
          _playbackSpeed = speed;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepPurple : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildFillInBlankQuestion() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 問題文
            Text(
              _currentQuestion.text,
              style: const TextStyle(
                fontSize: 20,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            // ★ 追加: 日本語訳を表示
            if (_currentQuestion.translationJa != null && 
                _currentQuestion.translationJa!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.translate, size: 18, color: Colors.blue.shade600),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _currentQuestion.translationJa!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue.shade800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultView() {
    return Center(
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _isCorrect ? Colors.green.shade50 : Colors.red.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isCorrect ? Colors.green : Colors.red,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isCorrect ? Icons.check_circle : Icons.cancel,
                size: 64,
                color: _isCorrect ? Colors.green : Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                _isCorrect ? '正解！' : '不正解',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _isCorrect ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(height: 16),
              // 不正解の場合に正解を表示
              if (!_isCorrect) ...[
                const Text('正解:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    _correctAnswer.isNotEmpty ? _correctAnswer : '(正解データなし)',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'あなたの回答: ${_answerController.text}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
              // 正解の場合もフィードバック
              if (_isCorrect) ...[
                const SizedBox(height: 8),
                Text(
                  'あなたの回答: ${_answerController.text}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
              // ★ 追加: 日本語訳を表示（正解・不正解両方）
              if (_currentQuestion.translationJa != null && 
                  _currentQuestion.translationJa!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.translate, size: 18, color: Colors.blue.shade600),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _currentQuestion.translationJa!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue.shade800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnswerInput() {
    return TextField(
      controller: _answerController,
      decoration: InputDecoration(
        hintText: _isListening ? '聞こえた文を入力...' : '空欄に入る単語を入力...',
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => _submitAnswer(),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitAnswer,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSubmitting
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                '回答する',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Widget _buildNextButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _nextQuestion,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          _isLastQuestion ? '結果を見る' : '次の問題へ',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  /// ★ 修正: 音声再生処理（スピード調整対応）
  Future<void> _playAudio() async {
    String? audioUrl = _currentQuestion.audioUrl;
    
    if (audioUrl == null || audioUrl.isEmpty) {
      _showError('音声データがありません');
      return;
    }

    try {
      // 相対パスの場合、ベースURLを追加
      if (!audioUrl.startsWith('http://') && !audioUrl.startsWith('https://')) {
        // ★ 修正: ./ で始まる場合は除去
        if (audioUrl.startsWith('./')) {
          audioUrl = audioUrl.substring(2);  // "./" を除去
        }
        // 先頭に / がない場合は追加
        if (!audioUrl.startsWith('/')) {
          audioUrl = '/$audioUrl';
        }
        audioUrl = '$_apiBaseUrl$audioUrl';
      }
      
      debugPrint('Playing audio: $audioUrl (speed: $_playbackSpeed)');
      
      // ★ 追加: 再生スピードを設定
      await _audioPlayer.setPlaybackRate(_playbackSpeed);
      await _audioPlayer.play(UrlSource(audioUrl));
    } catch (e) {
      debugPrint('Audio play error: $e');
      _showError('音声の再生に失敗しました: $e');
    }
  }

  /// ★ 修正: 正解判定処理
  void _submitAnswer() {
    final userAnswer = _answerController.text.trim();
    if (userAnswer.isEmpty) {
      _showError('回答を入力してください');
      return;
    }

    setState(() => _isSubmitting = true);

    // ★ 修正: answerフィールドから正解を取得
    _correctAnswer = _currentQuestion.answer ?? '';
    
    // ★ デバッグログ
    debugPrint('=== Answer Check ===');
    debugPrint('User answer: "$userAnswer"');
    debugPrint('Correct answer (raw): "${_currentQuestion.answer}"');
    debugPrint('Correct answer (used): "$_correctAnswer"');
    debugPrint('Normalized user: "${_normalizeAnswer(userAnswer)}"');
    debugPrint('Normalized correct: "${_normalizeAnswer(_correctAnswer)}"');
    
    // ★ 修正: 正解判定（大文字小文字を無視して比較）
    _isCorrect = _normalizeAnswer(userAnswer) == _normalizeAnswer(_correctAnswer);
    
    debugPrint('Is correct: $_isCorrect');
    debugPrint('====================');

    _answers.add(AnswerResult(
      questionId: _currentQuestion.questionId,
      userAnswer: userAnswer,
      isCorrect: _isCorrect,
    ));

    setState(() {
      _showResult = true;
      _isSubmitting = false;
    });
  }

  /// ★ 追加: 回答を正規化（比較用）
  String _normalizeAnswer(String answer) {
    return answer
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ')  // 複数の空白を1つに
        .replaceAll(RegExp(r'''[.,!?'"]+'''), '');  // 句読点を削除
  }

  void _nextQuestion() {
    if (_isLastQuestion) {
      _completeQuiz();
    } else {
      setState(() {
        _currentIndex++;
        _showResult = false;
        _answerController.clear();
      });
    }
  }

  Future<void> _completeQuiz() async {
    if (_accessToken == null) {
      _showError('認証情報が取得できませんでした');
      return;
    }

    try {
      final request = QuizCompleteRequest(
        sessionId: widget.sessionId,
        userId: widget.userId,
        answers: _answers,
      );

      final response = await _apiService.completeQuiz(request, _accessToken!);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => QuizResultScreen(
              result: response,
              songInfo: widget.songInfo,
            ),
          ),
        );
      }
    } catch (e) {
      _showError('結果の送信に失敗しました: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showRetireDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('リタイア'),
        content: const Text('クイズを終了しますか？\n残りの問題は不正解として処理されます。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _retire();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('リタイア'),
          ),
        ],
      ),
    );
  }

  Future<void> _retire() async {
    // 残りの問題を全て不正解として追加
    for (int i = _currentIndex; i < widget.questions.length; i++) {
      // 現在の問題で既に回答済みの場合はスキップ
      if (i == _currentIndex && _showResult) continue;

      _answers.add(AnswerResult(
        questionId: widget.questions[i].questionId,
        userAnswer: '',
        isCorrect: false,
      ));
    }

    // 結果画面へ遷移
    await _completeQuiz();
  }
}