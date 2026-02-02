import 'package:flutter/material.dart';
import '../services/profile_api_service.dart';
import '../services/token_storage_service.dart';

class PrivacySettingsScreen extends StatefulWidget {
  final int userId;

  const PrivacySettingsScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  final _profileApiService = ProfileApiService();
  final _tokenStorage = TokenStorageService();

  bool _isLoading = true;
  int _privacy = 0; // 0: 公開, 1: フレンドのみ, 2: 非公開
  String? _accessToken;

  @override
  void initState() {
    super.initState();
    _loadPrivacySettings();
  }

  // 現在の設定を読み込む
  Future<void> _loadPrivacySettings() async {
    setState(() => _isLoading = true);
    try {
      final token = await _tokenStorage.getAccessToken();
      if (token == null) {
        throw Exception('ログインしていません');
      }
      _accessToken = token;

      // プロフィール取得APIを流用して現在の設定を取得
      // GET /api/profile/{userId}
      final data = await _profileApiService.getProfile(
        userId: widget.userId,
        accessToken: token,
      );

      if (mounted) {
        setState(() {
          // バックエンドのレスポンスに合わせてキー名を調整してください
          // ProfileControllerのレスポンス: "privacy"
          if (data['privacy'] != null) {
            _privacy = data['privacy'] as int;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('設定の読み込みに失敗しました: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // 設定を保存する
  Future<void> _savePrivacySettings(int newValue) async {
    // 楽観的UI更新（先に画面を変えてしまう）
    final oldValue = _privacy;
    setState(() => _privacy = newValue);

    try {
      if (_accessToken == null) throw Exception('認証エラー');

      // PUT /api/profile/{userId}/privacy
      await _profileApiService.updatePrivacy(
        widget.userId,
        newValue,
        _accessToken!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('プライバシー設定を保存しました'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      // 失敗したら元に戻す
      if (mounted) {
        setState(() => _privacy = oldValue);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存に失敗しました: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('プライバシー設定'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 16.0),
            child: Text(
              'プロフィールの公開範囲を設定します。\n設定した範囲外のユーザーからは、あなたのプロフィール詳細や再生履歴が見えなくなります。',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          
          // --- 設定項目 ---
          
          _buildPrivacyOption(
            value: 0,
            title: '全体に公開',
            subtitle: 'すべてのユーザーがあなたのプロフィールを閲覧できます',
            icon: Icons.public,
          ),
          
          _buildPrivacyOption(
            value: 1,
            title: 'フレンドのみ公開',
            subtitle: '相互フォローしているフレンドのみ閲覧できます',
            icon: Icons.people,
          ),
          
          _buildPrivacyOption(
            value: 2,
            title: '非公開',
            subtitle: '自分以外は誰も閲覧できません',
            icon: Icons.lock,
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyOption({
    required int value,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _privacy == value;
    
    return Card(
      elevation: isSelected ? 2 : 0,
      color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.05) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected 
            ? BorderSide(color: Theme.of(context).primaryColor, width: 2)
            : BorderSide.none,
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: RadioListTile<int>(
        value: value,
        groupValue: _privacy,
        onChanged: (val) => _savePrivacySettings(val!),
        title: Row(
          children: [
            Icon(icon, color: isSelected ? Theme.of(context).primaryColor : Colors.grey),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Theme.of(context).primaryColor : null,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(subtitle),
        ),
        activeColor: Theme.of(context).primaryColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }
}