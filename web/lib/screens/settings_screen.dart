import 'package:flutter/material.dart';
import '../services/profile_api_service.dart';
import '../services/token_storage_service.dart';
import '../widgets/profile_edit_dialog.dart';
import './volume_settings_screen.dart';

/// ========================================
/// 設定画面
/// ========================================
/// HomeScreenの設定ボタンから遷移する画面です。
/// プロフィール変更などの各種設定機能を提供します。
/// ========================================
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _profileApiService = ProfileApiService();
  final _tokenStorage = TokenStorageService();

  // ========================================
  // ユーザー情報（プロフィール表示用）
  // ========================================
  String? _username;
  String? _userUuid;
  String? _imageUrl;
  String? _email;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  /// ========================================
  /// プロフィール情報を読み込む
  /// ========================================
  /// ProfileApiServiceを使用してバックエンドから
  /// ユーザー情報を取得します。
  /// ========================================
  Future<void> _loadProfile() async {
    try {
      final userId = await _tokenStorage.getUserId();
      final accessToken = await _tokenStorage.getAccessToken();

      if (userId == null || accessToken == null) {
        throw Exception('認証情報が見つかりません');
      }

      final profile = await _profileApiService.getProfile(
        userId: userId,
        accessToken: accessToken,
      );

      setState(() {
        _username = profile['username'];
        _userUuid = profile['userUuid'];
        _imageUrl = profile['imageUrl'];
        _email = profile['email'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('プロフィールの読み込みに失敗しました: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// ========================================
  /// プロフィール編集ダイアログを表示
  /// ========================================
  /// ProfileEditDialogを表示し、編集完了後に
  /// プロフィール情報を再読み込みします。
  /// ========================================
  Future<void> _showProfileEditDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ProfileEditDialog(
        currentUsername: _username ?? '',
        currentUserUuid: _userUuid ?? '',
        currentImageUrl: _imageUrl,
      ),
    );

    if (result == true) {
      // プロフィールが更新された場合、再読み込み
      _loadProfile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('プロフィールを更新しました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ========================================
                  // プロフィールセクション
                  // ========================================
                  _buildSectionHeader('プロフィール'),
                  const SizedBox(height: 8),
                  _buildProfileCard(),
                  const SizedBox(height: 24),

                  // ========================================
                  // アカウント設定セクション（将来の拡張用）
                  // ========================================
                  _buildSectionHeader('アカウント設定'),
                  const SizedBox(height: 8),
                  _buildSettingsItem(
                    icon: Icons.email,
                    title: 'メールアドレス',
                    subtitle: _email ?? '未設定',
                    onTap: null, // 将来的にメール変更機能を追加
                  ),
                  const SizedBox(height: 24),

                  // ========================================
                  // アプリ設定セクション（将来の拡張用）
                  // ========================================
                  _buildSectionHeader('アプリ設定'),
                  const SizedBox(height: 8),
                  _buildSettingsItem(
                    icon: Icons.volume_up,
                    title: '音量設定',
                    subtitle: '効果音・BGMの音量を調整',
                    onTap: () {
                      print("🎵 音量設定がタップされました！");
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const VolumeSettingsScreen()),
                      );
                    },
                  ),
                  _buildSettingsItem(
                    icon: Icons.language,
                    title: '言語設定',
                    subtitle: 'アプリの表示言語を変更',
                    onTap: null, // 将来的に言語設定機能を追加
                  ),
                ],
              ),
            ),
    );
  }

  /// ========================================
  /// セクションヘッダーを構築
  /// ========================================
  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.blue,
      ),
    );
  }

  /// ========================================
  /// プロフィールカードを構築
  /// ========================================
  /// 現在のプロフィール情報を表示し、
  /// タップでプロフィール編集ダイアログを開きます。
  /// ========================================
  Widget _buildProfileCard() {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: _showProfileEditDialog,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // アイコン画像
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.grey[200],
                backgroundImage: _imageUrl != null && _imageUrl!.isNotEmpty
                    ? NetworkImage(_imageUrl!)
                    : null,
                child: _imageUrl == null || _imageUrl!.isEmpty
                    ? const Icon(Icons.person, size: 40, color: Colors.grey)
                    : null,
              ),
              const SizedBox(width: 16),
              // ユーザー情報
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ユーザー名
                    Text(
                      _username ?? '未設定',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // ユーザーID（フレンド申請用）
                    Row(
                      children: [
                        const Icon(Icons.badge, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          'ID: ${_userUuid ?? '未設定'}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // 編集アイコン
              const Icon(Icons.edit, color: Colors.blue),
            ],
          ),
        ),
      ),
    );
  }

  /// ========================================
  /// 設定項目を構築
  /// ========================================
  /// 各設定項目のリストタイルを生成します。
  /// onTapがnullの場合は無効化されます。
  /// ========================================
  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: onTap != null ? Colors.blue : Colors.grey,
                  size: 28,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: onTap != null ? Colors.black87 : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: onTap != null ? Colors.grey : Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  onTap != null ? Icons.chevron_right : Icons.lock_outline,
                  color: onTap != null ? Colors.grey : Colors.grey[400],
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}