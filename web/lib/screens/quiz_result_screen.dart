import 'package:flutter/material.dart';
import '../models/quiz_models.dart';

class QuizResultScreen extends StatelessWidget {
  final QuizCompleteResponse result;
  final SongInfo? songInfo;

  const QuizResultScreen({
    super.key,
    required this.result,
    this.songInfo,
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

            // ナビゲーションボタン
            _buildNavigationButtons(context),
            const SizedBox(height: 24),

            // 問題一覧
            _buildQuestionList(),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreCard() {
    final percentage = (result.accuracy * 100).round();
    Color scoreColor;
    String message;

    if (percentage >= 80) {
      scoreColor = Colors.green;
      message = '素晴らしい！';
    } else if (percentage >= 60) {
      scoreColor = Colors.orange;
      message = 'よくできました！';
    } else {
      scoreColor = Colors.red;
      message = 'もっと頑張りましょう！';
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

  Widget _buildNavigationButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showQuestionDetails(context),
            icon: const Icon(Icons.list),
            label: const Text('問題一覧を見る'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _goToHome(context),
                icon: const Icon(Icons.home),
                label: const Text('ホームへ'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _goToVocabulary(context),
                icon: const Icon(Icons.book),
                label: const Text('単語帳'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuestionList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '問題一覧',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...result.questionResults.asMap().entries.map((entry) {
          final index = entry.key;
          final questionResult = entry.value;
          return _buildQuestionResultCard(index + 1, questionResult);
        }),
      ],
    );
  }

  Widget _buildQuestionResultCard(int number, QuestionResult questionResult) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
        title: Text('問題 $number'),
        subtitle: Text(
          questionResult.questionFormat == 'listening'
              ? 'リスニング'
              : '虫食い',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('問題', questionResult.questionText),
                const SizedBox(height: 8),
                _buildDetailRow('あなたの回答', questionResult.userAnswer),
                const SizedBox(height: 8),
                _buildDetailRow('正解', questionResult.correctAnswer),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text(
                      '難易度: ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '★' * questionResult.difficultyLevel,
                      style: const TextStyle(color: Colors.amber),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  void _showQuestionDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return ListView.builder(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: result.questionResults.length,
            itemBuilder: (context, index) {
              return _buildQuestionResultCard(
                index + 1,
                result.questionResults[index],
              );
            },
          );
        },
      ),
    );
  }

  void _goToHome(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _goToVocabulary(BuildContext context) {
    // TODO: 単語帳画面へ遷移
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('単語帳機能は準備中です')),
    );
  }
}
