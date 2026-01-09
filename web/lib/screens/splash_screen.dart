import 'package:flutter/material.dart';
import '../services/auth_api_service.dart';
import '../services/token_storage_service.dart';
import '../services/presence_websocket_service.dart';
import 'login_screen.dart';
import 'home_screen.dart';

/// スプラッシュ画面
/// アプリ起動時にセッションの有効性を確認し、適切な画面に遷移します
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final TokenStorageService _tokenStorage = TokenStorageService();
  final AuthApiService _authService = AuthApiService();
  final PresenceWebSocketService _presenceService =
      PresenceWebSocketService();

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  /// セッションの有効性を確認
  Future<void> _checkSession() async {
    try {
      // 保存されているリフレッシュトークンを取得
      final refreshToken = await _tokenStorage.getRefreshToken();

      if (refreshToken == null) {
        // トークンがない場合はログイン画面へ
        _navigateToLogin();
        return;
      }

      // サーバーにセッション検証をリクエスト
      final response = await _authService.validateSession(refreshToken);

      // セッションが有効な場合、新しいトークンで更新してホーム画面へ
      await _tokenStorage.saveAuthData(
        accessToken: response['accessToken'],
        refreshToken: response['refreshToken'] ?? refreshToken,
        userId: response['userId'],
        email: response['email'],
        username: response['username'],
      );

      await _presenceService.connect();

      _navigateToHome();
    } on SessionInvalidException {
      // セッションが無効な場合、ローカルデータをクリアしてログイン画面へ
      await _tokenStorage.clearAuthData();
      _navigateToLogin();
    } catch (e) {
      // ネットワークエラー等の場合もログイン画面へ
      // (オフライン時は再ログインが必要)
      await _tokenStorage.clearAuthData();
      _navigateToLogin();
    }
  }

  /// ログイン画面へ遷移
  void _navigateToLogin() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  /// ホーム画面へ遷移
  void _navigateToHome() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // アプリロゴ（必要に応じて変更）
            Icon(
              Icons.music_note,
              size: 80,
              color: Colors.blue[600],
            ),
            const SizedBox(height: 24),
            const Text(
              'MelodyConnect',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              '読み込み中...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
