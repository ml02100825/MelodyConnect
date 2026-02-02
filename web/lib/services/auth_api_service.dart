import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_webapp/config/app_config.dart';

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
  // APIベースURL（assets/config.jsonから読み込み）
  String get baseUrl => '${AppConfig.apiBaseUrl}/api/auth';

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
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        final error = jsonDecode(utf8.decode(response.bodyBytes));
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
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        final error = jsonDecode(utf8.decode(response.bodyBytes));
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
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        final error = jsonDecode(utf8.decode(response.bodyBytes));
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
        return jsonDecode(utf8.decode(response.bodyBytes));
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
  /// [refreshToken] - 現在のリフレッシュトークン（特定のセッションを削除するため）
  /// [accessToken] - アクセストークン（認証ヘッダー用）
  ///
  /// 成功した場合はtrue、失敗した場合は例外をスロー
  Future<bool> logout(String refreshToken, String accessToken) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/logout'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'refreshToken': refreshToken,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        // 失敗してもクライアント側ではログアウト扱いにするのが一般的ですが、エラー内容は返します
        final error = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(error['error'] ?? 'ログアウトに失敗しました');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('ネットワークエラーが発生しました');
    }
  }

  /// 退会(アカウント削除)
  ///
  /// [accessToken] - アクセストークン
  ///
  /// 成功した場合はtrue、失敗した場合は例外をスロー
  Future<bool> withdraw(String accessToken) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/withdraw'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );
     
      if (response.statusCode == 200) {
        return true;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? '退会処理に失敗しました');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('ネットワークエラーが発生しました');
    }
  }

  // ==========================================
  // ★追加: パスワードリセット関連メソッド
  // ==========================================

  /// パスワードリセット要求 (メール送信シミュレーション)
  ///
  /// [email] - リセットしたいアカウントのメールアドレス
  Future<void> requestPasswordReset(String email) async {
    // Spring Bootの @RequestParam に合わせてクエリパラメータで送信
    final uri = Uri.parse('$baseUrl/request-password-reset').replace(queryParameters: {
      'email': email,
    });

    final response = await http.post(uri);

    if (response.statusCode != 200) {
      String message = '送信に失敗しました';
      try {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        if (body['error'] != null) {
          message = body['error'];
        }
      } catch (_) {}
      throw Exception(message);
    }
  }

  /// パスワード更新実行
  ///
  /// [token] - メール(ログ)で受け取ったリセットコード
  /// [newPassword] - 新しいパスワード
  Future<void> confirmPasswordReset(String token, String newPassword) async {
    final uri = Uri.parse('$baseUrl/reset-password');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'token': token,
        'newPassword': newPassword,
      }),
    );

    if (response.statusCode != 200) {
      String message = 'パスワード更新に失敗しました';
      try {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        if (body['error'] != null) {
          message = body['error'];
        }
      } catch (_) {}
      throw Exception(message);
    }
  }

  /// メールアドレス変更要求 (現在のメールアドレスにコード送信)
  ///
  /// [accessToken] - アクセストークン
  Future<void> requestEmailChange(String accessToken) async {
    final uri = Uri.parse('$baseUrl/request-email-change');

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode != 200) {
      String message = '送信に失敗しました';
      try {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        if (body['error'] != null) {
          message = body['error'];
        }
      } catch (_) {}
      throw Exception(message);
    }
  }

  /// メールアドレス変更実行
  ///
  /// [token] - メール(ログ)で受け取った変更コード
  /// [newEmail] - 新しいメールアドレス
  Future<void> confirmEmailChange(String token, String newEmail) async {
    final uri = Uri.parse('$baseUrl/confirm-email-change');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'token': token,
        'newEmail': newEmail,
      }),
    );

    if (response.statusCode != 200) {
      String message = 'メールアドレス変更に失敗しました';
      try {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        if (body['error'] != null) {
          message = body['error'];
        }
      } catch (_) {}
      throw Exception(message);
    }
  }
}
