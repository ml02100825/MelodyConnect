import 'dart:convert';
import 'package:http/http.dart' as http;

/// セッション無効例外
/// セッションが失効・revoke済みの場合にスローされます
class SessionInvalidException implements Exception {
  final String message;
  SessionInvalidException(this.message);

  @override
  String toString() => message;
}

/// 認証APIサービス
/// バックエンドの認証エンドポイントとの通信を行います
class AuthApiService {
  // 開発環境のAPIベースURL（本番環境では適切なURLに変更してください）
  static const String baseUrl = 'http://localhost:8080/api/auth';

  /// ユーザー登録
  ///
  /// [email] - メールアドレス
  /// [password] - パスワード
  ///
  /// 返り値: AuthResponse（ユーザーID、メールアドレス、トークン）
  /// エラーの場合は例外をスロー
  Future<Map<String, dynamic>> register(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? '登録に失敗しました');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('ネットワークエラーが発生しました');
    }
  }

  /// ログイン
  ///
  /// [email] - メールアドレス
  /// [password] - パスワード
  ///
  /// 返り値: AuthResponse（ユーザーID、メールアドレス、トークン）
  /// エラーの場合は例外をスロー
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'ログインに失敗しました');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('ネットワークエラーが発生しました');
    }
  }

  /// トークンのリフレッシュ
  ///
  /// [refreshToken] - リフレッシュトークン
  ///
  /// 返り値: AuthResponse（新しいアクセストークン）
  /// エラーの場合は例外をスロー
  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/refresh'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'refreshToken': refreshToken,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'トークンのリフレッシュに失敗しました');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('ネットワークエラーが発生しました');
    }
  }

  /// セッション検証（アプリ起動時にセッションが有効か確認）
  ///
  /// [refreshToken] - リフレッシュトークン
  ///
  /// 返り値: AuthResponse（有効な場合）
  /// セッションが無効な場合は例外をスロー
  Future<Map<String, dynamic>> validateSession(String refreshToken) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/validate'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'refreshToken': refreshToken,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        // 401 = セッション無効
        throw SessionInvalidException('セッションが無効です');
      }
    } catch (e) {
      if (e is SessionInvalidException) {
        rethrow;
      }
      throw Exception('セッション検証中にエラーが発生しました');
    }
  }

  /// ログアウト
  ///
  /// [userId] - ユーザーID
  /// [accessToken] - アクセストークン
  ///
  /// 成功した場合はtrue、失敗した場合は例外をスロー
  Future<bool> logout(int userId, String accessToken) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/logout/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'ログアウトに失敗しました');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('ネットワークエラーが発生しました');
    }
  }
}
