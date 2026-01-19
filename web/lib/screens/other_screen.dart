import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../bottom_nav.dart';
import './volume_settings_screen.dart';
import './privacy_settings_screen.dart';
import './profile_setup_screen.dart';
import './subscription_screen.dart';
import './payment_management_screen.dart';
import 'contact_screen.dart';

class OtherScreen extends StatefulWidget {
  const OtherScreen({Key? key}) : super(key: key);

  @override
  State<OtherScreen> createState() => _OtherScreenState();
}

class _OtherScreenState extends State<OtherScreen> {
  int _userId = 0;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _userId = prefs.getInt('userId') ?? 0;
      });
    } catch (e) {
      print('ユーザーID読み込みエラー: $e');
    }
  }

  Future<void> _navigateToPrivacySettings(BuildContext context) async {
    if (_userId == 0) {
      // SharedPreferencesから再取得を試みる
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId') ?? 0;
      
      if (userId == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ユーザーIDを取得できませんでした')),
        );
        return;
      }
      
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PrivacySettingsScreen(userId: userId),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PrivacySettingsScreen(userId: _userId),
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
              padding: EdgeInsets.zero,
              icon: const Icon(
                Icons.person_add,
                color: Colors.black87,
                size: 20,
              ),
              onPressed: () {},
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
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ProfileSetupScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildMenuButton(
              context,
              icon: Icons.volume_up,
              label: '音量設定',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const VolumeSettingsScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildMenuButton(
              context,
              icon: Icons.lock,
              label: 'プライバシー設定',
              onTap: () => _navigateToPrivacySettings(context), // 修正
            ),
            const SizedBox(height: 12),
            _buildMenuButton(
              context,
              icon: Icons.payment,
              label: '支払い情報管理',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AddPaymentMethodScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildMenuButton(
              context,
              icon: Icons.subscriptions,
              label: 'サブスク登録・解約',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SubscriptionScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildMenuButton(
              context,
              icon: Icons.support_agent,
              label: 'お問い合わせ',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ContactScreen(),
                  ),
                );
              },
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