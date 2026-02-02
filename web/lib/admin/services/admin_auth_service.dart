import 'dart:convert';
import 'package:http/http.dart' as http;
import 'admin_token_storage_service.dart';
import '../../config/app_config.dart';

/// 管理者認証サービス
class AdminAuthService {
  static String get _baseUrl => AppConfig.apiBaseUrl;

  /// 管理者ログイン（メールアドレスで認証）
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/admin/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await AdminTokenStorageService.saveTokens(
        accessToken: data['accessToken'],
        refreshToken: data['refreshToken'],
        adminId: data['adminId'],
        email: data['email'],
      );
      return {'success': true, 'data': data};
    } else {
      final error = jsonDecode(response.body);
      return {'success': false, 'error': error['error'] ?? 'ログインに失敗しました'};
    }
  }

  /// トークンリフレッシュ
  static Future<bool> refreshToken() async {
    final refreshToken = await AdminTokenStorageService.getRefreshToken();
    if (refreshToken == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/admin/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await AdminTokenStorageService.saveTokens(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
          adminId: data['adminId'],
          email: data['email'],
        );
        return true;
      }
    } catch (e) {
      // リフレッシュ失敗
    }
    return false;
  }

  /// ログアウト
  static Future<void> logout() async {
    await AdminTokenStorageService.clearTokens();
  }

  /// 認証状態をチェック
  static Future<bool> isAuthenticated() async {
    return await AdminTokenStorageService.hasToken();
  }
}
