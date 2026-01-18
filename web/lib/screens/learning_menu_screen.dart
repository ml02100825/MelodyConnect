import 'package:flutter/material.dart';
import '../services/token_storage_service.dart';

/// 学習メニュー画面
/// 「学習」と「学習履歴」を選択できる中間画面
class LearningMenuScreen extends StatefulWidget {
  const LearningMenuScreen({super.key});

  @override
  State<LearningMenuScreen> createState() => _LearningMenuScreenState();
}

class _LearningMenuScreenState extends State<LearningMenuScreen> {
  final TokenStorageService _tokenStorage = TokenStorageService();
  int? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final userId = await _tokenStorage.getUserId();
    setState(() {
      _userId = userId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 600;
    final padding = isWideScreen ? 48.0 : 24.0;
    final maxWidth = isWideScreen ? 600.0 : double.infinity;

    return Scaffold(
      appBar: AppBar(
        title: const Text('学習'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
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
                  '学習モードを選択',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'クイズに挑戦するか、過去の学習記録を確認できます',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // 学習を始めるボタン
                _buildMenuCard(
                  context: context,
                  title: '学習を始める',
                  description: 'クイズに挑戦しよう',
                  icon: Icons.school,
                  color: Colors.deepPurple,
                  onTap: () {
                    Navigator.pushNamed(context, '/learning');
                  },
                ),
                const SizedBox(height: 24),

                // 学習履歴ボタン
                _buildMenuCard(
                  context: context,
                  title: '学習履歴',
                  description: '過去の学習記録を確認',
                  icon: Icons.history,
                  color: Colors.teal,
                  onTap: () {
                    if (_userId != null) {
                      Navigator.pushNamed(
                        context,
                        '/learning-history?userId=$_userId',
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Icon(
                icon,
                size: 64,
                color: color,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
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
