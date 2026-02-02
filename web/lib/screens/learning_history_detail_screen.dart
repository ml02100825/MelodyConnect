import 'package:flutter/material.dart';
import '../models/history_models.dart';
import '../services/history_api_service.dart';
import '../services/token_storage_service.dart';
import 'report_screen.dart';

/// 学習履歴詳細画面
class LearningHistoryDetailScreen extends StatefulWidget {
  final int historyId;

  const LearningHistoryDetailScreen({
    super.key,
    required this.historyId,
  });

  @override
  State<LearningHistoryDetailScreen> createState() => _LearningHistoryDetailScreenState();
}

class _LearningHistoryDetailScreenState extends State<LearningHistoryDetailScreen> {
  final HistoryApiService _apiService = HistoryApiService();
  final TokenStorageService _tokenStorage = TokenStorageService();

  LearningHistoryDetail? _detail;
  bool _isLoading = true;
  String? _errorMessage;
  int? _userId;
  String? _userName;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    try {
      final token = await _tokenStorage.getAccessToken();

      if (token == null) {
        setState(() {
          _errorMessage = '認証情報を取得できませんでした';
          _isLoading = false;
        });
        return;
      }

      // ユーザー情報を取得
      final userId = await _tokenStorage.getUserId();
      final userName = await _tokenStorage.getUsername();

      final detail = await _apiService.getLearningHistoryDetail(widget.historyId, token);
      setState(() {
        _detail = detail;
        _userId = userId;
        _userName = userName;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '詳細の取得に失敗しました: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('学習詳細'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(_errorMessage!, style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    if (_detail == null) {
      return const Center(child: Text('データがありません'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // サマリーカード
          _buildSummaryCard(),
          const SizedBox(height: 24),
          // 問題一覧
          const Text(
            '問題一覧',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(_detail!.questions.length, (index) {
            return _buildQuestionCard(index + 1, _detail!.questions[index]);
          }),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final detail = _detail!;
    final accuracy = detail.totalCount > 0
        ? (detail.correctCount / detail.totalCount * 100).round()
        : 0;

    Color scoreColor;
    String message;
    IconData icon;

    if (accuracy >= 80) {
      scoreColor = Colors.green;
      message = '素晴らしい！';
      icon = Icons.celebration;
    } else if (accuracy >= 60) {
      scoreColor = Colors.orange;
      message = 'よくできました！';
      icon = Icons.thumb_up;
    } else {
      scoreColor = Colors.red;
      message = 'もっと頑張りましょう！';
      icon = Icons.fitness_center;
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [scoreColor.withOpacity(0.8), scoreColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, size: 48, color: Colors.white),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '$accuracy%',
              style: const TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${detail.correctCount} / ${detail.totalCount} 問正解',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildInfoChip(detail.learningAt, Colors.white24),
                const SizedBox(width: 8),
                _buildInfoChip(
                  _getLanguageLabel(detail.learningLang),
                  Colors.white24,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String text, Color backgroundColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildQuestionCard(int number, QuestionDetail question) {
    final isCorrect = question.isCorrect;
    final resultColor = isCorrect ? Colors.green : Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: resultColor.withOpacity(0.3),
        ),
      ),
      child: ExpansionTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: resultColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              isCorrect ? Icons.check : Icons.close,
              color: resultColor,
            ),
          ),
        ),
        title: Text(
          '問題 $number',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: question.questionFormat == 'listening'
                    ? Colors.blue[100]
                    : Colors.green[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                question.questionFormat == 'listening' ? 'リスニング' : '虫食い',
                style: TextStyle(
                  color: question.questionFormat == 'listening'
                      ? Colors.blue[800]
                      : Colors.green[800],
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(
            Icons.flag,
            color: Colors.red,
          ),
          onPressed: question.questionId != null && _userId != null
              ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReportScreen(
                        reportType: 'QUESTION',
                        targetId: question.questionId!,
                        targetDisplayText: question.questionText,
                        userName: _userName ?? 'User',
                        userId: _userId!,
                      ),
                    ),
                  );
                }
              : null,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailSection('問題', question.questionText),
                const SizedBox(height: 12),
                _buildDetailSection(
                  'あなたの回答',
                  question.userAnswer.isEmpty ? '(未回答)' : question.userAnswer,
                  valueColor: isCorrect ? Colors.green : Colors.red,
                ),
                const SizedBox(height: 12),
                _buildDetailSection(
                  '正解',
                  question.correctAnswer,
                  valueColor: Colors.green,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String label, String value, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }

  String _getLanguageLabel(String lang) {
    switch (lang.toLowerCase()) {
      case 'en':
      case 'english':
        return '英語';
      case 'ja':
      case 'japanese':
        return '日本語';
      case 'ko':
      case 'korean':
        return '韓国語';
      default:
        return lang;
    }
  }
}
