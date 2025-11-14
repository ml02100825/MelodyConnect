import 'package:flutter/material.dart';
import '../services/auth_api_service.dart';
import '../services/token_storage_service.dart';
import 'login_screen.dart';

/// ホーム画面（プレースホルダー）
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authApiService = AuthApiService();
  final _tokenStorage = TokenStorageService();

  String? _username;
  String? _email;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  /// ユーザー情報を読み込む
  Future<void> _loadUserData() async {
    try {
      final username = await _tokenStorage.getUsername();
      final email = await _tokenStorage.getEmail();

      setState(() {
        _username = username;
        _email = email;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// ログアウト処理
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
    // レスポンシブ対応: 画面幅に応じてレイアウトを調整
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('MelodyConnect'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'ログアウト',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isWideScreen ? 48.0 : 24.0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isWideScreen ? 800 : double.infinity,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ウェルカムメッセージ
                      Icon(
                        Icons.music_note,
                        size: isWideScreen ? 100 : 80,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'ようこそ${_username != null ? '、$_username さん' : ''}！',
                        style: TextStyle(
                          fontSize: isWideScreen ? 32 : 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      if (_email != null)
                        Text(
                          _email!,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      const SizedBox(height: 48),

                      // プレースホルダーカード
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.construction,
                                size: 64,
                                color: Colors.orange,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'ホーム画面は準備中です',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'この画面は今後実装される予定です。\n現在はログインとプロフィール設定が完了しています。',
                                style: TextStyle(
                                  fontSize: isWideScreen ? 16 : 14,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // 統計情報（ダミーデータ）
                      if (isWideScreen)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatCard('総プレイ数', '0'),
                            _buildStatCard('残りライフ', '5'),
                            _buildStatCard('レート', '1500'),
                          ],
                        )
                      else
                        Column(
                          children: [
                            _buildStatCard('総プレイ数', '0'),
                            const SizedBox(height: 16),
                            _buildStatCard('残りライフ', '5'),
                            const SizedBox(height: 16),
                            _buildStatCard('レート', '1500'),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  /// 統計情報カードを構築
  Widget _buildStatCard(String label, String value) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
