import 'package:flutter/material.dart';
import '../services/auth_api_service.dart';

class PasswordResetConfirmScreen extends StatefulWidget {
  const PasswordResetConfirmScreen({Key? key}) : super(key: key);

  @override
  State<PasswordResetConfirmScreen> createState() => _PasswordResetConfirmScreenState();
}

class _PasswordResetConfirmScreenState extends State<PasswordResetConfirmScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // 入力コントローラー
  final _tokenController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  
  final _authApiService = AuthApiService();

  bool _isLoading = false;
  bool _obscurePassword = true; // パスワード表示切替用

  @override
  void dispose() {
    _tokenController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleResetConfirm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // API呼び出し
      await _authApiService.confirmPasswordReset(
        _tokenController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      // 成功メッセージ
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('パスワードを変更しました。新しいパスワードでログインしてください。'),
          backgroundColor: Colors.green,
        ),
      );

      // ログイン画面まで戻る (ナビゲーションスタックを全クリア)
      Navigator.of(context).popUntil((route) => route.isFirst);

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
      appBar: AppBar(title: const Text('パスワード再設定')),
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
                    'メール(ログ)に記載されたコードと\n新しいパスワードを入力してください。',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // トークン入力欄
                  TextFormField(
                    controller: _tokenController,
                    decoration: const InputDecoration(
                      labelText: 'リセットコード (UUID)',
                      hintText: '例: 550e8400-e29b...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.key),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'コードを入力してください';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // パスワード入力欄
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: '新しいパスワード',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock_reset),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'パスワードを入力してください';
                      if (value.length < 6) return '6文字以上で入力してください';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // パスワード確認欄
                  TextFormField(
                    controller: _confirmController,
                    obscureText: _obscurePassword,
                    decoration: const InputDecoration(
                      labelText: 'パスワード確認',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    validator: (value) {
                      if (value != _passwordController.text) return 'パスワードが一致しません';
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // 実行ボタン
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleResetConfirm,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20, width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                          )
                        : const Text('変更を実行する', style: TextStyle(fontSize: 16)),
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