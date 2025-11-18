import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/quiz_models.dart';
import '../services/quiz_api_service.dart';
import 'quiz_result_screen.dart';

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
  final AudioPlayer _audioPlayer = AudioPlayer();
  final TextEditingController _answerController = TextEditingController();

  int _currentIndex = 0;
  List<AnswerResult> _answers = [];
  bool _isSubmitting = false;
  bool _showResult = false;
  bool _isCorrect = false;
  String _correctAnswer = '';

  @override
  void dispose() {
    _audioPlayer.dispose();
    _answerController.dispose();
    super.dispose();
  }

  QuizQuestion get _currentQuestion => widget.questions[_currentIndex];
  bool get _isLastQuestion => _currentIndex == widget.questions.length - 1;
  bool get _isListening => _currentQuestion.questionFormat == 'listening';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('問題 ${_currentIndex + 1}/${widget.questions.length}'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // プログレスバー
              _buildProgressBar(),
              const SizedBox(height: 24),

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
        ElevatedButton.icon(
          onPressed: _playAudio,
          icon: const Icon(Icons.play_arrow),
          label: const Text('音声を再生'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
        ),
      ],
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
        child: Text(
          _currentQuestion.text,
          style: const TextStyle(
            fontSize: 20,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildResultView() {
    return Center(
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
            if (!_isCorrect) ...[
              const Text('正解:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                _correctAnswer,
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ],
          ],
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

  Future<void> _playAudio() async {
    if (_currentQuestion.audioUrl != null) {
      try {
        await _audioPlayer.play(UrlSource(_currentQuestion.audioUrl!));
      } catch (e) {
        _showError('音声の再生に失敗しました');
      }
    } else {
      _showError('音声データがありません');
    }
  }

  void _submitAnswer() {
    final userAnswer = _answerController.text.trim();
    if (userAnswer.isEmpty) {
      _showError('回答を入力してください');
      return;
    }

    setState(() => _isSubmitting = true);

    // 正解判定（実際のアプリではサーバーで判定するべき）
    // ここでは簡易的にクライアント側で判定
    _correctAnswer = _currentQuestion.text
        .replaceAll('_____', '')
        .replaceAll('___', '')
        .trim();

    // 虫食い問題の場合は空欄部分を正解とする
    // リスニング問題の場合は全文を正解とする
    _isCorrect = _isListening
        ? userAnswer.toLowerCase() == _currentQuestion.text.toLowerCase()
        : true; // 実際にはサーバーで判定

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
    try {
      final request = QuizCompleteRequest(
        sessionId: widget.sessionId,
        userId: widget.userId,
        answers: _answers,
      );

      final response = await _apiService.completeQuiz(request);

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
}
