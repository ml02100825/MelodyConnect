import 'package:flutter/material.dart';
import '../services/auth_api_service.dart';
import '../services/token_storage_service.dart';
import '../bottom_nav.dart';
import 'login_screen.dart';
import 'my_profile.dart';
import 'battle_screen.dart';
import 'vocabulary_screen.dart';
import 'shop_screen.dart';
import 'badge_screen.dart';
import 'ranking_screen.dart';

/// ホーム画面
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authApiService = AuthApiService();
  final _tokenStorage = TokenStorageService();

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  /// ユーザー情報を読み込む
  /// ユーザー情報を読み込む
  Future<void> _loadUserData() async {
    try {
      await _tokenStorage.getEmail();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }
  Future<void> _handleLogout() async {
    try {
      final userId = await _tokenStorage.getUserId();
      final accessToken = await _tokenStorage.getAccessToken();

      if (userId != null && accessToken != null) {
        await _authApiService.logout(userId, accessToken);
      }

      // ローカルの認証情報を削除
      await _tokenStorage.clearAuthData();

      if (!mounted) return;

      // ログイン画面に戻る
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ログアウトに失敗しました: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            // ライフ表示（音符5個）
            Row(
              children: List.generate(5, (index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(
                    Icons.music_note,
                    color: Colors.blue[600],
                    size: 20,
                  ),
                );
              }),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black87),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // アバター（タップでマイプロフィールへ）
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: GestureDetector(
                    onTap: () {
                      print('アバターがタップされました'); // デバッグ用
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MyProfile(),
                        ),
                      );
                    },
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.purple[100],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person,
                        color: Colors.purple[300],
                        size: 45,
                      ),
                    ),
                  ),
                ),
                
                // メインコンテンツ（中央寄せ）
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // メインメニュー（2x2グリッド）
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildMenuCard(
                                icon: Icons.sports_esports,
                                label: '対戦する',
                                onTap: () {
                                  print('対戦するボタンがタップされました');
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const BattleScreen(),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 12),
                              _buildMenuCard(
                                icon: Icons.library_music,
                                label: '単語帳',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const VocabularyScreen(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildMenuCard(
                                icon: Icons.shopping_cart,
                                label: 'ショップ',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const ShopScreen(),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 12),
                              _buildMenuCard(
                                icon: Icons.local_florist,
                                label: 'バッジ',
                                subtitle: '12/49',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const BadgeScreen(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // ランキングボタン
                          _buildRankingCard(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const RankingScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 0,
        onTap: (index) {
          // TODO: 画面遷移処理を書く
        },
      ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String label,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        height: 140,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Colors.black87),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRankingCard({required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 332,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          children: [
            const Text(
              'ランキングを確認する',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Icon(
              Icons.emoji_events,
              size: 48,
              color: Colors.amber[700],
            ),
          ],
        ),
      ),
    );
  }
}