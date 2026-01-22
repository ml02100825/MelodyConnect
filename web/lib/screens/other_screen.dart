import 'package:flutter/material.dart';
import '../services/profile_api_service.dart';
import '../services/token_storage_service.dart';
import '../widgets/profile_edit_dialog.dart';
import 'contact_screen.dart';
import '../bottom_nav.dart';
import 'payment_management_screen.dart'; // 既存画面
import 'subscription_screen.dart';       // 既存画面
import 'privacy_settings_screen.dart';   // 既存画面

class OtherScreen extends StatefulWidget {
  const OtherScreen({Key? key}) : super(key: key);

  @override
  State<OtherScreen> createState() => _OtherScreenState();
}

class _OtherScreenState extends State<OtherScreen> {
  final _profileApiService = ProfileApiService();
  final _tokenStorage = TokenStorageService();

  bool _isLoading = true;
  int? _userId;

  // プロフィール表示用
  String? _username;
  String? _userUuid;
  String? _imageUrl;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final userId = await _tokenStorage.getUserId();
      final token = await _tokenStorage.getAccessToken();

      if (userId == null || token == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final data = await _profileApiService.getProfile(
        userId: userId,
        accessToken: token,
      );

      if (mounted) {
        setState(() {
          _userId = userId;
          _username = data['username'];
          _userUuid = data['userUuid'];
          _imageUrl = data['imageUrl'];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // プロフィール編集
  Future<void> _showProfileEdit() async {
    if (_userId == null) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => ProfileEditDialog(
        currentUsername: _username ?? '',
        currentUserUuid: _userUuid ?? '',
        currentImageUrl: _imageUrl,
      ),
    );

    // 編集があった場合はリロード
    if (result == true) {
      await _loadProfile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('プロフィールを更新しました')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('設定・その他'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          // === プロフィールカード ===
          if (_userId != null)
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  radius: 30,
                  backgroundImage: _imageUrl != null && _imageUrl!.isNotEmpty
                      ? NetworkImage(_imageUrl!)
                      : null,
                  child: _imageUrl == null || _imageUrl!.isEmpty
                      ? const Icon(Icons.person, size: 30) : null,
                ),
                title: Text(_username ?? 'No Name', 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                subtitle: Text('ID: ${_userUuid ?? '---'}'),
                trailing: IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: _showProfileEdit,
                ),
              ),
            ),
          
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('契約・支払い', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),

          // === クレジットカード管理 ===
          ListTile(
            leading: const Icon(Icons.credit_card),
            title: const Text('クレジットカード管理'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PaymentManagementScreen()),
              );
            },
          ),

          // === サブスクリプション ===
          ListTile(
            leading: const Icon(Icons.workspace_premium),
            title: const Text('サブスクリプション登録・解約'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SubscriptionScreen()),
              );
            },
          ),

          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('アプリ設定', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),

          // === プライバシー設定 (別画面へ遷移) ===
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('プライバシー設定'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              if (_userId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PrivacySettingsScreen(userId: _userId!),
                  ),
                );
              }
            },
          ),

          // === お問い合わせ ===
          ListTile(
            leading: const Icon(Icons.mail_outline),
            title: const Text('お問い合わせ'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ContactScreen()),
              );
            },
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
}