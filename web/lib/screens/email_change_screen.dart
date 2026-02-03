import 'package:flutter/material.dart';
import '../services/auth_api_service.dart';
import '../services/token_storage_service.dart';
import 'email_change_confirm_screen.dart';

/// メールアドレス変更確認画面
///
/// ユーザーに「メールアドレスを変更しますか？」と確認し、
/// 「はい」を選択した場合は現在のメールアドレスに変更コードを送信します。
class EmailChangeScreen extends StatefulWidget {
  const EmailChangeScreen({Key? key}) : super(key: key);

  @override
  State<EmailChangeScreen> createState() => _EmailChangeScreenState();
}

class _EmailChangeScreenState extends State<EmailChangeScreen> {
  final _authApiService = AuthApiService();
  final _tokenStorage = TokenStorageService();

  bool _isLoading = false;
  bool _isEmailSent = false; // メール送信成功フラグ
  String? _currentEmail; // 現在のメールアドレス

  @override
  void initState() {
    super.initState();
    _loadCurrentEmail();
  }

  Future<void> _loadCurrentEmail() async {
    final email = await _tokenStorage.getEmail();
    if (mounted) {
      setState(() => _currentEmail = email);
    }
  }

  /// 変更要求処理
  Future<void> _handleRequest() async {
    setState(() => _isLoading = true);

    try {
      final accessToken = await _tokenStorage.getAccessToken();
      if (accessToken == null) {
        throw Exception('認証情報が見つかりません');
      }

      await _authApiService.requestEmailChange(accessToken);

      if (!mounted) return;

      // 成功したら画面を切り替え
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
            child: _isEmailSent
                ? _buildSentView() // 送信完了後の画面
                : _buildConfirmView(), // 確認画面
          ),
        ),
      ),
    );
  }

  // 確認画面
  Widget _buildConfirmView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.email, size: 80, color: Colors.blue),
        const SizedBox(height: 24),
        const Text(
          'メールアドレスを変更しますか?',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        // 現在のメールアドレスを表示
        if (_currentEmail != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.mail_outline, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    _currentEmail!,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        const Text(
          '上記のメールアドレスに\n変更用のコードを送信します。',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleRequest,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Colors.blue,
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : const Text('はい、変更します',
                  style: TextStyle(fontSize: 16, color: Colors.white)),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('いいえ、キャンセル', style: TextStyle(fontSize: 16)),
        ),
      ],
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
        const Text(
          '現在のメールアドレス宛に\nコードを送信しました（ログを確認してください）。',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () {
            // 次の画面へ遷移
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const EmailChangeConfirmScreen()),
            );
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
          child: const Text('コードを入力して変更する'),
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
