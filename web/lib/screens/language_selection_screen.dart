import 'package:flutter/material.dart';
import 'matching_screen.dart';

/// 言語選択画面
/// バトルで使用する問題の言語を選択します
class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 600;
    final padding = isWideScreen ? 48.0 : 24.0;
    final maxWidth = isWideScreen ? 600.0 : double.infinity;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Language Selection'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(padding),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // タイトル
                const Text(
                  '問題の言語を選択',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'バトルで出題される問題の言語を選んでください',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // 英語ボタン
                _buildLanguageCard(
                  context: context,
                  language: 'English',
                  languageCode: 'english',
                  flag: '🇬🇧',
                  description: '英語の問題で対戦',
                  color: Colors.blue,
                ),
                const SizedBox(height: 24),

                // 韓国語ボタン
                _buildLanguageCard(
                  context: context,
                  language: 'Korean',
                  languageCode: 'korean',
                  flag: '🇰🇷',
                  description: '韓国語の問題で対戦',
                  color: Colors.red,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 言語選択カードを構築
  Widget _buildLanguageCard({
    required BuildContext context,
    required String language,
    required String languageCode,
    required String flag,
    required String description,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: () {
          // マッチング画面に遷移
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MatchingScreen(language: languageCode),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              // フラグ絵文字
              Text(
                flag,
                style: const TextStyle(fontSize: 80),
              ),
              const SizedBox(height: 16),

              // 言語名
              Text(
                language,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // 説明
              Text(
                description,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
