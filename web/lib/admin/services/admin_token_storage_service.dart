import 'package:shared_preferences/shared_preferences.dart';

/// 管理者トークン保存サービス
class AdminTokenStorageService {
  static const String _accessTokenKey = 'admin_access_token';
  static const String _refreshTokenKey = 'admin_refresh_token';
  static const String _adminIdKey = 'admin_id';
  static const String _adminEmailKey = 'admin_email';

  /// アクセストークンを保存
  static Future<void> saveAccessToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, token);
  }

  /// リフレッシュトークンを保存
  static Future<void> saveRefreshToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_refreshTokenKey, token);
  }

  /// 管理者IDを保存
  static Future<void> saveAdminId(int adminId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_adminIdKey, adminId);
  }

  /// 管理者メールアドレスを保存
  static Future<void> saveAdminEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_adminEmailKey, email);
  }

  /// 全トークンを保存
  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required int adminId,
    String? email,
  }) async {
    await saveAccessToken(accessToken);
    await saveRefreshToken(refreshToken);
    await saveAdminId(adminId);
    if (email != null) {
      await saveAdminEmail(email);
    }
  }

  /// アクセストークンを取得
  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  /// リフレッシュトークンを取得
  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  /// 管理者IDを取得
  static Future<int?> getAdminId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_adminIdKey);
  }

  /// 管理者メールアドレスを取得
  static Future<String?> getAdminEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_adminEmailKey);
  }

  /// 全トークンを削除（ログアウト）
  static Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_adminIdKey);
    await prefs.remove(_adminEmailKey);
  }

  /// トークンが存在するかチェック
  static Future<bool> hasToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
