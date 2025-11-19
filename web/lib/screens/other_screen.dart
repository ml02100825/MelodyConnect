import 'package:flutter/material.dart';
import '../bottom_nav.dart';
import 'volume_settings_screen.dart';
import 'contact_screen.dart';
import 'language_settings_screen.dart';
import '../services/auth_api_service.dart';
import '../services/token_storage_service.dart';
import 'login_screen.dart';


class OtherScreen extends StatefulWidget {
  const OtherScreen({Key? key}) : super(key: key);

	@override
	State<OtherScreen> createState() => _OtherScreenState();
}

class _OtherScreenState extends State<OtherScreen> {
  final TokenStorageService _tokenStorage = TokenStorageService();
  final AuthApiService _authApiService = AuthApiService();

  // ログアウト処理（確認ダイアログ表示）
  void _handleLogout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('本当に退会しますか？'),
        content: const Text(
          '退会すると今までの履歴や\nサブスクリプションの情報が\n閲覧できなくなります。\n退会する場合は退会するを押してください',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('戻る'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performLogout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            child: const Text('退会する', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // 実際のログアウト処理
  Future<void> _performLogout() async {
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

  // 退会確認ダイアログ（OtherScreen から直接実行する）
  void _confirmWithdraw() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('本当に退会しますか？'),
        content: const Text(
          '退会すると今までの履歴や\nサブスクリプションの情報が\n閲覧できなくなります。\n退会する場合は退会するを押してください',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('戻る'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performWithdraw();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('退会する', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // 退会処理（アカウント削除またはログアウト）
  Future<void> _performWithdraw() async {
    try {
      final userId = await _tokenStorage.getUserId();
      final accessToken = await _tokenStorage.getAccessToken();

      if (userId != null && accessToken != null) {
        // バックエンドに専用の削除 API があればそちらを実装してください。
        // 現状は logout を呼んでセッションを切断します。
        await _authApiService.logout(userId, accessToken);
      }

      await _tokenStorage.clearAuthData();

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
          content: Text('退会に失敗しました: ${e.toString().replaceAll('Exception: ', '')}'),
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
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.settings,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              '設定',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'ログアウト',
              onPressed: _handleLogout,
            ),
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildMenuButton(
              context,
              icon: Icons.edit,
              label: 'プロフィール編集',
              onTap: () {},
            ),
            const SizedBox(height: 12),
            _buildMenuButton(
              context,
              icon: Icons.volume_up,
              label: '音量設定',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const VolumeSettingsScreen()),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildMenuButton(
              context,
              icon: Icons.language,
              label: '言語設定',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LanguageSettingsScreen()),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildMenuButton(
              context,
              icon: Icons.lock,
              label: 'プライバシー設定',
              onTap: () {},
            ),
            const SizedBox(height: 12),
            _buildMenuButton(
              context,
              icon: Icons.payment,
              label: '支払い情報管理',
              onTap: () {},
            ),
            const SizedBox(height: 12),
            _buildMenuButton(
              context,
              icon: Icons.subscriptions,
              label: 'サブスク登録・解約',
              onTap: () {},
            ),
            const SizedBox(height: 12),
            _buildMenuButton(
              context,
              icon: Icons.support_agent,
              label: 'お問い合わせ',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ContactScreen()),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildMenuButton(
              context,
              icon: Icons.delete_outline,
              label: '退会',
              onTap: _confirmWithdraw,
            ),
          ],
        ),
      ),

      bottomNavigationBar: BottomNavBar(
        currentIndex: 4,
        onTap: (index) {
          // TODO: 画面遷移処理を書く
        },
      ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Colors.black87, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
