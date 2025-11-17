import 'package:flutter/material.dart';
import 'language_selection_screen.dart';

/// バトルモード選択画面
/// Ranked MatchとRoom Matchを選択します
class BattleModeSelectionScreen extends StatelessWidget {
  const BattleModeSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 600;
    final padding = isWideScreen ? 48.0 : 24.0;
    final maxWidth = isWideScreen ? 600.0 : double.infinity;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Battle Mode'),
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
                  'バトルモードを選択',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '対戦モードを選んでください',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // Ranked Matchボタン
                _buildModeCard(
                  context: context,
                  title: 'Ranked Match',
                  description: 'レーティングをかけて戦う',
                  icon: Icons.emoji_events,
                  color: Colors.amber,
                  isAvailable: true,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LanguageSelectionScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Room Matchボタン（準備中）
                _buildModeCard(
                  context: context,
                  title: 'Room Match',
                  description: 'フレンドとプライベート対戦',
                  icon: Icons.people,
                  color: Colors.green,
                  isAvailable: false,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Room Matchは準備中です'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// モード選択カードを構築
  Widget _buildModeCard({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required bool isAvailable,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // アイコン
              Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    icon,
                    size: 80,
                    color: isAvailable ? color : Colors.grey,
                  ),
                  if (!isAvailable)
                    const Icon(
                      Icons.lock,
                      size: 40,
                      color: Colors.white,
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // タイトル
              Text(
                title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isAvailable ? Colors.black : Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // 説明
              Text(
                description,
                style: TextStyle(
                  fontSize: 16,
                  color: isAvailable ? Colors.grey[700] : Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),

              // ステータス
              if (!isAvailable) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '準備中',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
