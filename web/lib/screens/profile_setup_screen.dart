import 'package:flutter/material.dart';
import '../services/profile_api_service.dart';
import '../services/token_storage_service.dart';
import 'home_screen.dart';

/// プロフィール設定画面（ステップ2: ユーザー名とアイコン設定）
class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({Key? key}) : super(key: key);

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _profileApiService = ProfileApiService();
  final _tokenStorage = TokenStorageService();

  bool _isLoading = false;

  // デフォルトアイコンのリスト
  final List<String> _defaultIcons = [
    'https://ui-avatars.com/api/?name=User&background=FF6B6B&color=fff',
    'https://ui-avatars.com/api/?name=User&background=4ECDC4&color=fff',
    'https://ui-avatars.com/api/?name=User&background=45B7D1&color=fff',
    'https://ui-avatars.com/api/?name=User&background=96CEB4&color=fff',
    'https://ui-avatars.com/api/?name=User&background=FFEAA7&color=333',
    'https://ui-avatars.com/api/?name=User&background=DDA15E&color=fff',
  ];

  String? _selectedIcon;

  @override
  void dispose() {
    _usernameController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  /// ユーザー名のバリデーション
  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'ユーザー名を入力してください';
    }

    if (value.length < 3) {
      return 'ユーザー名は3文字以上である必要があります';
    }

    if (value.length > 20) {
      return 'ユーザー名は20文字以下である必要があります';
    }

    return null;
  }

  /// プロフィール更新処理
  Future<void> _handleProfileUpdate() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 保存されている認証情報を取得
      final userId = await _tokenStorage.getUserId();
      final accessToken = await _tokenStorage.getAccessToken();

      if (userId == null || accessToken == null) {
        throw Exception('認証情報が見つかりません');
      }

      // プロフィール更新API呼び出し
      final response = await _profileApiService.updateProfile(
        userId: userId,
        username: _usernameController.text.trim(),
        imageUrl: _selectedIcon ?? _imageUrlController.text.trim(),
        accessToken: accessToken,
      );

      // ユーザー名を保存
      await _tokenStorage.saveUsername(response['username']);

      if (!mounted) return;

      // 成功メッセージを表示
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('プロフィールを設定しました'),
          backgroundColor: Colors.green,
        ),
      );

      // ホーム画面へ遷移
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // レスポンシブ対応: 画面幅に応じて最大幅を設定
    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = screenWidth > 600 ? 500.0 : double.infinity;
    final padding = screenWidth > 600 ? 48.0 : 24.0;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(padding),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // タイトル
                  const Text(
                    'プロフィール設定',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'ユーザー名とアイコンを設定してください',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // ユーザー名入力
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'ユーザー名',
                      hintText: '3〜20文字で入力',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    validator: _validateUsername,
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: 24),

                  // アイコン選択
                  const Text(
                    'アイコンを選択',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: _defaultIcons.map((iconUrl) {
                      final isSelected = _selectedIcon == iconUrl;
                      return GestureDetector(
                        onTap: _isLoading
                            ? null
                            : () {
                                setState(() {
                                  _selectedIcon = iconUrl;
                                  _imageUrlController.clear();
                                });
                              },
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.blue : Colors.transparent,
                              width: 3,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 30,
                            backgroundImage: NetworkImage(iconUrl),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // カスタム画像URL入力（オプション）
                  const Text(
                    'またはカスタム画像URLを入力',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _imageUrlController,
                    decoration: const InputDecoration(
                      labelText: '画像URL（オプション）',
                      hintText: 'https://example.com/avatar.png',
                      prefixIcon: Icon(Icons.image),
                      border: OutlineInputBorder(),
                    ),
                    enabled: !_isLoading,
                    onChanged: (value) {
                      if (value.isNotEmpty) {
                        setState(() {
                          _selectedIcon = null;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 32),

                  // 設定完了ボタン
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleProfileUpdate,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            '設定完了',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
