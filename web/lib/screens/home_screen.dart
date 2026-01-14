import 'dart:async';
import 'package:flutter/material.dart';
import '../services/auth_api_service.dart';
import '../services/artist_api_service.dart';
import '../services/presence_websocket_service.dart';
import '../services/token_storage_service.dart';
import '../services/life_api_service.dart';
import '../widgets/genre_selection_dialog.dart';
import '../widgets/artist_selection_dialog.dart';
import '../bottom_nav.dart';
import 'login_screen.dart';
import 'my_profile.dart';
import 'battle_mode_selection_screen.dart';
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

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final _authApiService = AuthApiService();
  final _artistApiService = ArtistApiService();
  final PresenceWebSocketService _presenceService =
      PresenceWebSocketService();
  final _tokenStorage = TokenStorageService();
  final _lifeApiService = LifeApiService();

  bool _isLoading = true;
  bool _showedArtistDialog = false;
  int? _userId;

  // ライフ関連
  int _currentLife = 5;
  int _maxLife = 5;
  int _nextRecoveryInSeconds = 0;
  Timer? _recoveryTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _recoveryTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _presenceService.handleLifecycle(state);
    if (state == AppLifecycleState.resumed) {
      // バックグラウンドから戻ったら再取得
      _fetchLifeStatus();
    }
  }

  /// ユーザー情報を読み込む
  Future<void> _loadUserData() async {
    try {
      await _tokenStorage.getEmail();
      final userId = await _tokenStorage.getUserId();

      setState(() {
        _userId = userId;
        _isLoading = false;
      });

      // ライフ状態を取得
      _fetchLifeStatus();

      // 初期設定完了状態をチェックし、未完了ならダイアログを表示
      _checkInitialSetup();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// ライフ状態を取得
  Future<void> _fetchLifeStatus() async {
    try {
      final userId = await _tokenStorage.getUserId();
      final accessToken = await _tokenStorage.getAccessToken();

      if (userId != null && accessToken != null) {
        final lifeStatus = await _lifeApiService.getLifeStatus(
          userId: userId,
          accessToken: accessToken,
        );
        if (mounted) {
          setState(() {
            _currentLife = lifeStatus.currentLife;
            _maxLife = lifeStatus.maxLife;
            _nextRecoveryInSeconds = lifeStatus.nextRecoveryInSeconds;
          });
          _startRecoveryTimer();
        }
      }
    } catch (e) {
      debugPrint('ライフ状態取得エラー: $e');
    }
  }

  /// 回復タイマーを開始
  void _startRecoveryTimer() {
    _recoveryTimer?.cancel();
    if (_currentLife >= _maxLife || _nextRecoveryInSeconds <= 0) return;

    _recoveryTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _nextRecoveryInSeconds--;
        if (_nextRecoveryInSeconds <= 0 && _currentLife < _maxLife) {
          _currentLife++;
          _nextRecoveryInSeconds = 600; // 10分
          if (_currentLife >= _maxLife) {
            timer.cancel();
          }
        }
      });
    });
  }

  /// 秒数を分:秒形式にフォーマット
  String _formatRecoveryTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
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
        _showGenreSelectionDialog();
      }
    } catch (e) {
      // エラーが発生してもダイアログは表示しない
      debugPrint('初期設定状態の確認に失敗: $e');
    }
  }

  /// ジャンル選択ダイアログを表示
  Future<void> _showGenreSelectionDialog() async {
    final selectedGenres = await showDialog<List<String>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const GenreSelectionDialog(),
    );

    if (!mounted) return;

    // ジャンル選択後、アーティスト選択ダイアログを表示
    _showArtistSelectionDialog(selectedGenres);
  }

  /// アーティスト選択ダイアログを表示
  Future<void> _showArtistSelectionDialog(List<String>? selectedGenres) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ArtistSelectionDialog(selectedGenres: selectedGenres),
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
      _presenceService.disconnect();

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
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            // ライフ表示
            ...List.generate(_maxLife, (index) {
              final isFilled = index < _currentLife;
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(
                  Icons.music_note,
                  color: isFilled ? Colors.blue[600] : Colors.grey[300],
                  size: 20,
                ),
              );
            }),
            const SizedBox(width: 8),
            // 次回回復までの時間（life < maxのとき）
            if (_currentLife < _maxLife)
              Text(
                _formatRecoveryTime(_nextRecoveryInSeconds),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
                      debugPrint('アバターがタップされました');
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MyProfile(),
                        ),
                      ).then((_) => _fetchLifeStatus()); // 戻ったら再取得
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
                                  debugPrint('対戦するボタンがタップされました');
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const BattleModeSelectionScreen(),
                                    ),
                                  ).then((_) => _fetchLifeStatus()); // 戻ったら再取得
                                },
                              ),
                              const SizedBox(width: 12),
                              _buildMenuCard(
                                icon: Icons.library_music,
                                label: '単語帳',
                                onTap: () {
                                  debugPrint('単語帳ボタンがタップされました');
                                  if (_userId != null) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => VocabularyScreen(userId: _userId!),
                                      ),
                                    ).then((_) => _fetchLifeStatus()); // 戻ったら再取得
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('ユーザー情報の取得に失敗しました'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
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
                                  debugPrint('ショップボタンがタップされました');
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const ShopScreen(),
                                    ),
                                  ).then((_) => _fetchLifeStatus()); // 戻ったら再取得
                                },
                              ),
                              const SizedBox(width: 12),
                              _buildMenuCard(
                                icon: Icons.local_florist,
                                label: 'バッジ',
                                subtitle: '12/49',
                                onTap: () {
                                  debugPrint('バッジボタンがタップされました');
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const BadgeScreen(),
                                    ),
                                  ).then((_) => _fetchLifeStatus()); // 戻ったら再取得
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // ランキングボタン
                          _buildRankingCard(
                            onTap: () {
                              debugPrint('ランキングボタンがタップされました');
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const RankingScreen(),
                                ),
                              ).then((_) => _fetchLifeStatus()); // 戻ったら再取得
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
          // 画面遷移はBottomNavBar内で処理
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
