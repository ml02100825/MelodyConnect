import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // 直接通信用
import '../services/profile_api_service.dart';
import '../services/token_storage_service.dart';
import '../widgets/profile_edit_dialog.dart';
import 'contact_screen.dart';
import '../bottom_nav.dart';
import 'payment_management_screen.dart';
import 'subscription_screen.dart';
import 'privacy_settings_screen.dart';
import 'login_screen.dart';

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

    if (result == true) {
      await _loadProfile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('プロフィールを更新しました')),
        );
      }
    }
  }

  // ログアウト処理
  Future<void> _handleLogout() async {
    await _tokenStorage.clearAuthData();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  // ▼▼▼ 退会処理（修正版） ▼▼▼
  Future<void> _handleWithdraw() async {
    setState(() => _isLoading = true);
    try {
      // 1. ユーザーIDとトークンを取得
      final userId = await _tokenStorage.getUserId();
      final token = await _tokenStorage.getAccessToken();
      
      if (userId == null || token == null) {
        throw Exception('認証情報またはユーザーIDが見つかりません');
      }

      // 2. サーバーへ退会リクエスト（URLにIDを含める + DELETEメソッド）
      final url = Uri.parse('http://localhost:8080/api/auth/withdraw/$userId'); 
      
      final response = await http.delete( // POST -> DELETE に変更
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // 3. レスポンス確認
      if (response.statusCode != 200) {
        String errorMessage = '退会処理に失敗しました';
        try {
            final body = jsonDecode(utf8.decode(response.bodyBytes));
            if (body['error'] != null) {
                errorMessage = body['error'];
            }
        } catch (_) {}
        throw Exception(errorMessage);
      }
      
      // 4. 成功したら端末のデータを消してログイン画面へ
      await _tokenStorage.clearAuthData();

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('退会しました。ご利用ありがとうございました。')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラー: $e')),
      );
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
          // プロフィール
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

          const Divider(),
          
          // ログアウト
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('ログアウト'),
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('確認'),
                  content: const Text('ログアウトしますか？'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('キャンセル')),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _handleLogout();
                      },
                      child: const Text('ログアウト', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          ),

          // 退会ボタン
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('退会する', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('退会の確認', style: TextStyle(color: Colors.red)),
                  content: const Text('本当に退会しますか？\nアカウント情報はすべて削除され、復元できません。'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('キャンセル')),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _handleWithdraw();
                      },
                      child: const Text('退会する', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 4,
        onTap: (index) {},
      ),
    );
  }
}