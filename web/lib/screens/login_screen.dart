import 'package:flutter/material.dart';
import '../services/auth_api_service.dart';
import '../services/token_storage_service.dart';
import 'register_screen.dart';

/// ログイン画面
class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authApiService = AuthApiService();
  final _tokenStorage = TokenStorageService();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// メールアドレスのバリデーション
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'メールアドレスを入力してください';
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return '有効なメールアドレスを入力してください';
    }

    return null;
  }

  /// パスワードのバリデーション
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'パスワードを入力してください';
    }
    return null;
  }

  /// ログイン処理
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _authApiService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      // トークンを保存
      await _tokenStorage.saveAuthData(
        accessToken: response['accessToken'],
        refreshToken: response['refreshToken'],
        userId: response['userId'],
        email: response['email'],
      );

      if (!mounted) return;

      // ログイン成功メッセージを表示
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ログインしました'),
          backgroundColor: Colors.green,
        ),
      );

      // ホーム画面へ遷移（ここでは単純にメッセージを表示）
      // 実際のアプリでは、適切な画面に遷移してください
      // Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen()));
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

  /// 登録画面へ遷移
  void _navigateToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ロゴまたはタイトル
                  const Icon(
                    Icons.music_note,
                    size: 80,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'MelodyConnect',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'ログイン',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // メールアドレス入力
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'メールアドレス',
                      hintText: 'example@example.com',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: _validateEmail,
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: 16),

                  // パスワード入力
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'パスワード',
                      hintText: 'パスワードを入力',
                      prefixIcon: const Icon(Icons.lock),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    obscureText: _obscurePassword,
                    validator: _validatePassword,
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: 32),

                  // ログインボタン
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
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
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'ログイン',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                  const SizedBox(height: 16),

                  // 区切り線
                  const Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('または'),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 新規登録ボタン
                  OutlinedButton(
                    onPressed: _isLoading ? null : _navigateToRegister,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      '新規登録',
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
