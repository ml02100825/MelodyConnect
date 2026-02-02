import 'package:flutter/material.dart';
import '../models/quiz_models.dart';
import '../services/token_storage_service.dart';
import 'vocabulary_screen.dart';
import 'report_screen.dart';

class QuizResultScreen extends StatelessWidget {
  final QuizCompleteResponse result;
  final SongInfo? songInfo;
  final int? userId;
  final String? userName;

  const QuizResultScreen({
    super.key,
    required this.result,
    this.songInfo,
    this.userId,
    this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('結果'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // スコア表示
            _buildScoreCard(),
            const SizedBox(height: 24),

            // 曲情報
            if (songInfo != null) ...[
              _buildSongInfoCard(),
              const SizedBox(height: 24),
            ],

            // ★ 修正: ナビゲーションボタン（問題一覧ボタンを大きく）
            _buildNavigationButtons(context),
            
            // ★ 削除: デフォルトの問題一覧表示を削除
            // 代わりにボトムシートで表示
          ],
        ),
      ),
    );
  }

  Widget _buildScoreCard() {
    final percentage = (result.accuracy * 100).round();
    Color scoreColor;
    String message;
    IconData icon;

    if (percentage >= 80) {
      scoreColor = Colors.green;
      message = '素晴らしい！';
      icon = Icons.celebration;
    } else if (percentage >= 60) {
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
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '$percentage%',
              style: const TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${result.correctCount} / ${result.totalCount} 問正解',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSongInfoCard() {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.music_note, color: Colors.deepPurple),
        title: Text(songInfo!.songName),
        subtitle: Text('${songInfo!.artistName} • ${songInfo!.genre ?? ''}'),
      ),
    );
  }

  /// ★ 修正: ナビゲーションボタン - 問題一覧ボタンを大きく目立たせる
  Widget _buildNavigationButtons(BuildContext context) {
    return Column(
      children: [
        // ★ 問題一覧を見るボタン（大きく目立たせる）
        SizedBox(
          width: double.infinity,
          height: 64,
          child: ElevatedButton.icon(
            onPressed: () => _showQuestionDetails(context),
            icon: const Icon(Icons.list_alt, size: 28),
            label: const Text(
              '問題一覧を見る',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
            ),
          ),
        ),
        const SizedBox(height: 16),
        // ホームと単語帳ボタン
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 56,
                child: OutlinedButton(
                  onPressed: () => _goToHome(context),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.home, size: 20),
                        SizedBox(width: 6),
                        Text('ホーム'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 56,
                child: OutlinedButton(
                  onPressed: () => _goToVocabulary(context),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.book, size: 20),
                        SizedBox(width: 6),
                        Text('単語帳'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // もう一度挑戦ボタン
        SizedBox(
          width: double.infinity,
          height: 48,
          child: TextButton.icon(
            onPressed: () => _retryQuiz(context),
            icon: const Icon(Icons.refresh),
            label: const Text('もう一度挑戦'),
          ),
        ),
      ],
    );
  }

  /// 問題詳細をボトムシートで表示
  void _showQuestionDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              // ハンドル
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // ヘッダー
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '問題一覧',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${result.correctCount}/${result.totalCount} 正解',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Divider(),
              // 問題リスト
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: result.questionResults.length,
                  itemBuilder: (context, index) {
                    return _buildQuestionResultCard(
                      context,
                      index + 1,
                      result.questionResults[index],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildQuestionResultCard(BuildContext context, int number, QuestionResult questionResult) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: questionResult.isCorrect
              ? Colors.green.shade200
              : Colors.red.shade200,
          width: 1,
        ),
      ),
      child: ExpansionTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: questionResult.isCorrect
                ? Colors.green.shade100
                : Colors.red.shade100,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              questionResult.isCorrect ? Icons.check : Icons.close,
              color: questionResult.isCorrect ? Colors.green : Colors.red,
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
                color: questionResult.questionFormat == 'listening'
                    ? Colors.blue.shade100
                    : Colors.green.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                questionResult.questionFormat == 'listening'
                    ? 'リスニング'
                    : '虫食い',
                style: TextStyle(
                  color: questionResult.questionFormat == 'listening'
                      ? Colors.blue.shade800
                      : Colors.green.shade800,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '★' * questionResult.difficultyLevel,
              style: const TextStyle(color: Colors.amber, fontSize: 12),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(
            Icons.flag,
            color: Colors.red,
          ),
          onPressed: userId != null
              ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReportScreen(
                        reportType: 'QUESTION',
                        targetId: questionResult.questionId,
                        targetDisplayText: questionResult.questionText,
                        userName: userName ?? 'User',
                        userId: userId!,
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
                _buildDetailRow('問題', questionResult.questionText),
                const SizedBox(height: 12),
                _buildDetailRow(
                  'あなたの回答',
                  questionResult.userAnswer,
                  color: questionResult.isCorrect ? Colors.green : Colors.red,
                ),
                const SizedBox(height: 12),
                _buildDetailRow(
                  '正解',
                  questionResult.correctAnswer,
                  color: Colors.green,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  void _goToHome(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _goToVocabulary(BuildContext context) async {
    final tokenStorage = TokenStorageService();
    final userId = await tokenStorage.getUserId();

    if (userId == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ユーザー情報を取得できませんでした')),
        );
      }
      return;
    }

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VocabularyScreen(userId: userId),
        ),
      );
    }
  }

}


  void _retryQuiz(BuildContext context) {
    // ホーム画面に戻る（そこから再挑戦）
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
