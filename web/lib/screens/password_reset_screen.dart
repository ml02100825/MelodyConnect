import 'package:flutter/material.dart';
import '../services/auth_api_service.dart';
import 'password_reset_confirm_screen.dart'; // ★このあと作成するファイルをインポート

class PasswordResetScreen extends StatefulWidget {
  /// ログイン済みユーザーから呼び出す場合に設定する。
  /// 値があればメール入力画面をスキップし、自動でコード送信する。
  final String? initialEmail;

  const PasswordResetScreen({Key? key, this.initialEmail}) : super(key: key);

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _authApiService = AuthApiService();

  bool _isLoading = false;
  bool _isEmailSent = false; // メール送信成功フラグ

  @override
  void initState() {
    super.initState();
    // 設定画面から遷移した場合は自動でコード送信
    if (widget.initialEmail != null) {
      _emailController.text = widget.initialEmail!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sendResetCode(widget.initialEmail!);
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  /// API呼び出し本体（フォーム送信・自動送信の両方で共有）
  Future<void> _sendResetCode(String email) async {
    setState(() => _isLoading = true);

    try {
      await _authApiService.requestPasswordReset(email);

      if (!mounted) return;
      setState(() {
        _isEmailSent = true;
      });
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

  /// 送信ボタン押下時の処理
  Future<void> _handleRequest() async {
    if (!_formKey.currentState!.validate()) return;
    await _sendResetCode(_emailController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('パスワードリセット')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: _isEmailSent
                ? _buildSentView() // 送信完了後の画面
                : _buildRequestForm(), // メール入力フォーム
          ),
        ),
      ),
    );
  }

  // 入力フォーム
  Widget _buildRequestForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '登録したメールアドレスを入力してください。\nリセット用コードを発行します。',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'メールアドレス',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) return '入力してください';
              if (!value.contains('@')) return '有効なメールアドレスを入力してください';
              return null;
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isLoading ? null : _handleRequest,
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            child: _isLoading
                ? const SizedBox(
                    height: 20, width: 20, 
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  )
                : const Text('リセットコードを送信', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  // 送信完了画面
  Widget _buildSentView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.mark_email_read, size: 80, color: Colors.green),
        const SizedBox(height: 24),
        const Text(
          '送信完了',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Text(
          '${_emailController.text} 宛に\nコードを送信しました(ログを確認してください)。',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () {
            // 次の画面へ遷移
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PasswordResetConfirmScreen()),
            );
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
          child: const Text('コードを入力して再設定する'),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('戻る'),
        ),
      ],
    );
  }
}