import 'package:flutter/material.dart';
import '../services/auth_api_service.dart';
import '../services/artist_api_service.dart';
import '../services/token_storage_service.dart';
import '../services/friend_notification_service.dart';
import '../widgets/artist_selection_dialog.dart';
import 'login_screen.dart';
import 'friend_screen.dart';

/// ホーム画面（プレースホルダー）
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authApiService = AuthApiService();
  final _artistApiService = ArtistApiService();
  final _tokenStorage = TokenStorageService();
  final _notificationService = FriendNotificationService();

  String? _username;
  String? _email;
  bool _isLoading = true;
  bool _showedArtistDialog = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _notificationService.connect();
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

      // 初期設定完了状態をチェックし、未完了ならダイアログを表示
      _checkInitialSetup();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 初期設定完了状態を確認
  Future<void> _checkInitialSetup() async {
    if (_showedArtistDialog) return;

    try {
      final accessToken = await _tokenStorage.getAccessToken();
      if (accessToken == null) return;

      final isCompleted =
          await _artistApiService.isInitialSetupCompleted(accessToken);

      if (!isCompleted && mounted) {
        _showedArtistDialog = true;
        _showArtistSelectionDialog();
      }
    } catch (e) {
      // エラーが発生してもダイアログは表示しない
      debugPrint('初期設定状態の確認に失敗: $e');
    }
  }

  /// アーティスト選択ダイアログを表示
  Future<void> _showArtistSelectionDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const ArtistSelectionDialog(),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('お気に入りアーティストを登録しました'),
          backgroundColor: Colors.green,
        ),
      );
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

                      // Battleボタン
                      SizedBox(
                        width: double.infinity,
                        height: 80,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/battle-mode');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.sports_martial_arts, size: 36),
                              SizedBox(width: 16),
                              Text(
                                'Battle',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 学習ボタン
                      SizedBox(
                        width: double.infinity,
                        height: 80,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/learning');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.school, size: 36),
                              SizedBox(width: 16),
                              Text(
                                '学習',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // フレンドボタン
                      SizedBox(
                        width: double.infinity,
                        height: 80,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const FriendScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.people, size: 36),
                              SizedBox(width: 16),
                              Text(
                                'フレンド',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
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
