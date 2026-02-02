import 'package:flutter/material.dart';
import '../services/auth_api_service.dart';
import '../services/token_storage_service.dart';
import 'login_screen.dart';

/// メールアドレス変更実行画面
///
/// メール（ログ）で受け取った変更コードと新しいメールアドレスを入力し、
/// メールアドレス変更を実行します。
class EmailChangeConfirmScreen extends StatefulWidget {
  const EmailChangeConfirmScreen({Key? key}) : super(key: key);

  @override
  State<EmailChangeConfirmScreen> createState() =>
      _EmailChangeConfirmScreenState();
}

class _EmailChangeConfirmScreenState extends State<EmailChangeConfirmScreen> {
  final _formKey = GlobalKey<FormState>();

  // 入力コントローラー
  final _tokenController = TextEditingController();
  final _emailController = TextEditingController();

  final _authApiService = AuthApiService();
  final _tokenStorage = TokenStorageService();

  bool _isLoading = false;

  @override
  void dispose() {
    _tokenController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailChange() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // API呼び出し
      await _authApiService.confirmEmailChange(
        _tokenController.text.trim(),
        _emailController.text.trim(),
      );

      if (!mounted) return;

      // 認証情報をクリア（ログアウト）
      await _tokenStorage.clearAuthData();

      // 成功メッセージ
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('メールアドレスを変更しました。新しいメールアドレスでログインしてください。'),
          backgroundColor: Colors.green,
        ),
      );

      // ログイン画面へ遷移
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
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
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('メールアドレス変更'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'メール（ログ）に記載されたコードと\n新しいメールアドレスを入力してください。',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // トークン入力欄
                  TextFormField(
                    controller: _tokenController,
                    decoration: const InputDecoration(
                      labelText: '変更コード (UUID)',
                      hintText: '例: 550e8400-e29b...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.key),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'コードを入力してください';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 新しいメールアドレス入力欄
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: '新しいメールアドレス',
                      hintText: 'example@example.com',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'メールアドレスを入力してください';
                      }
                      if (!value.contains('@')) {
                        return '有効なメールアドレスを入力してください';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // 実行ボタン
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleEmailChange,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text('変更を実行する',
                            style: TextStyle(fontSize: 16)),
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
