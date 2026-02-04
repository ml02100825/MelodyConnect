import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_webapp/config/app_config.dart';
import '../services/auth_api_service.dart';
import '../services/artist_api_service.dart';
import '../services/presence_websocket_service.dart';
import '../services/token_storage_service.dart';
import '../services/life_api_service.dart';
import '../services/profile_api_service.dart';
import '../widgets/unified_selection_dialog.dart';
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
  String? _imageUrl;

  // ライフ関連
  int _currentLife = 0;
  int _maxLife = 0;
  int _nextRecoveryInSeconds = 0;
  bool _isLifeLoading = true;
  bool _hasLifeData = false;
  Timer? _recoveryTimer;

  // バッジ数
  int? _earnedBadges;
  int? _totalBadges;

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
      _fetchBadgeCounts();
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

      // プロフィール画像を取得
      final accessToken = await _tokenStorage.getAccessToken();
      if (_userId != null && accessToken != null) {
        final profileService = ProfileApiService();
        final profile = await profileService.getProfile(
          userId: _userId!,
          accessToken: accessToken,
        );
        if (mounted) {
          setState(() {
            _imageUrl = profile['imageUrl'];
          });
        }
      }

      // ライフ状態を取得
      await _fetchLifeStatus();

      // バッジ数を取得
      _fetchBadgeCounts();

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
    if (mounted && !_hasLifeData) {
      setState(() {
        _isLifeLoading = true;
      });
    }

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
            _hasLifeData = true;
            _isLifeLoading = false;
          });
          _startRecoveryTimer();
        }
      } else if (mounted) {
        setState(() {
          _isLifeLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLifeLoading = false;
        });
      }
      debugPrint('ライフ状態取得エラー: $e');
    }
  }

  /// バッジの獲得数/総数を取得
  Future<void> _fetchBadgeCounts() async {
    try {
      final userId = await _tokenStorage.getUserId();
      final accessToken = await _tokenStorage.getAccessToken();

      if (userId == null || accessToken == null) return;

      final uri = Uri.parse(
          '${AppConfig.apiBaseUrl}/api/v1/badges?userId=$userId&mode=all');
      final res = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (res.statusCode == 200) {
        final List<dynamic> body = json.decode(utf8.decode(res.bodyBytes));
        final total = body.length;
        final earned = body.where((e) {
          final progress = e is Map<String, dynamic> ? e['progress'] : null;
          return progress is num && progress >= 1;
        }).length;

        if (mounted) {
          setState(() {
            _earnedBadges = earned;
            _totalBadges = total;
          });
        }
      } else {
        debugPrint('バッジ数取得エラー: ${res.statusCode}');
      }
    } catch (e) {
      debugPrint('バッジ数取得エラー: $e');
    }
  }

  /// 回復タイマーを開始
  void _startRecoveryTimer() {
    _recoveryTimer?.cancel();
    if (!_hasLifeData) return;
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

  /// 秒数を「分:秒」形式にフォーマット
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
        _showUnifiedSelectionDialog();
      }
    } catch (e) {
      debugPrint('初期設定状態の確認に失敗: $e');
    }
  }

  /// 統合された選択ダイアログを表示
  Future<void> _showUnifiedSelectionDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const UnifiedSelectionDialog(),
    );

    if (mounted) {
      _fetchLifeStatus();
      _fetchBadgeCounts();
    }
  }

  /// ログアウト処理
  Future<void> _handleLogout() async {
    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      final accessToken = await _tokenStorage.getAccessToken();

      if (refreshToken != null && accessToken != null) {
        await _authApiService.logout(refreshToken, accessToken);
      }

      await _tokenStorage.clearAuthData();
      _presenceService.disconnect();

      if (!mounted) return;

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

  /// 回復アイテム使用ダイアログを表示
  Future<void> _showRecoveryItemDialog() async {
    try {
      final accessToken = await _tokenStorage.getAccessToken();
      if (accessToken == null || _userId == null) return;

      // アイテム情報を取得
      final recoveryItem = await _lifeApiService.getRecoveryItem(
        userId: _userId!,
        accessToken: accessToken,
      );

      if (!mounted) return;

      // ダイアログ表示
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('ライフ回復'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                recoveryItem.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(recoveryItem.description),
              const SizedBox(height: 16),
              Text(
                '所持数: ${recoveryItem.quantity}個',
                style: TextStyle(
                  fontSize: 14,
                  color: recoveryItem.quantity > 0 ? Colors.black87 : Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (recoveryItem.quantity == 0) ...[
                const SizedBox(height: 8),
                const Text(
                  'アイテムがありません',
                  style: TextStyle(color: Colors.red),
                ),
              ],
              if (recoveryItem.quantity > 0) ...[
                const SizedBox(height: 16),
                const Text('使用しますか？'),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('いいえ'),
            ),
            if (recoveryItem.quantity > 0)
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: const Text('はい'),
              ),
          ],
        ),
      );

      // 「はい」が選択された場合、アイテムを使用
      if (confirmed == true) {
        await _useRecoveryItem(recoveryItem.itemId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラーが発生しました: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 回復アイテムを使用
  Future<void> _useRecoveryItem(int itemId) async {
    try {
      final accessToken = await _tokenStorage.getAccessToken();
      if (accessToken == null || _userId == null) return;

      final result = await _lifeApiService.useRecoveryItem(
        userId: _userId!,
        itemId: itemId,
        accessToken: accessToken,
      );

      if (result.success) {
        // ライフ状態を更新
        setState(() {
          _currentLife = result.newLife;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ライフを回復しました'),
              backgroundColor: Colors.green,
            ),
          );
        }

        // ライフ状態を再取得（回復タイマーの更新のため）
        _fetchLifeStatus();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('アイテムの使用に失敗しました: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
            if (_hasLifeData) ...[
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
              // ライフが0の場合のみ+ボタンを表示
              if (_currentLife == 0) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: _showRecoveryItemDialog,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 8),
              // 次回回復までの時間
              if (_currentLife < _maxLife)
                Text(
                  _formatRecoveryTime(_nextRecoveryInSeconds),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
            ] else if (_isLifeLoading) ...[
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 8),
              Text(
                'ライフ取得中',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
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
                // アバター
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MyProfile(),
                        ),
                      ).then((_) {
                        _fetchLifeStatus();
                        _fetchBadgeCounts();
                      });
                    },
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.blue.shade50,
                      backgroundImage: _imageUrl != null && _imageUrl!.isNotEmpty
                          ? NetworkImage(_imageUrl!)
                          : null,
                      child: _imageUrl == null || _imageUrl!.isEmpty
                          ? const Icon(Icons.person,
                              size: 45, color: Colors.purple)
                          : null,
                    ),
                  ),
                ),

                // メインコンテンツ
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildMenuCard(
                                icon: Icons.sports_esports,
                                label: '対戦する',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const BattleModeSelectionScreen(),
                                    ),
                                  ).then((_) {
                                    _fetchLifeStatus();
                                    _fetchBadgeCounts();
                                  });
                                },
                              ),
                              const SizedBox(width: 12),
                              _buildMenuCard(
                                icon: Icons.library_music,
                                label: '単語帳',
                                onTap: () {
                                  if (_userId != null) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            VocabularyScreen(userId: _userId!),
                                      ),
                                    ).then((_) {
                                      _fetchLifeStatus();
                                      _fetchBadgeCounts();
                                    });
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
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const ShopScreen(),
                                    ),
                                  ).then((_) {
                                    _fetchLifeStatus();
                                    _fetchBadgeCounts();
                                  });
                                },
                              ),
                              const SizedBox(width: 12),
                              _buildMenuCard(
                                icon: Icons.local_florist,
                                label: 'バッジ',
                                subtitle: _earnedBadges != null &&
                                        _totalBadges != null
                                    ? '${_earnedBadges!}/${_totalBadges!}'
                                    : '0/0',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const BadgeScreen(),
                                    ),
                                  ).then((_) {
                                    _fetchLifeStatus();
                                    _fetchBadgeCounts();
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _buildRankingCard(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const RankingScreen(),
                                ),
                              ).then((_) {
                                _fetchLifeStatus();
                                _fetchBadgeCounts();
                              });
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
          // Navigation logic
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
