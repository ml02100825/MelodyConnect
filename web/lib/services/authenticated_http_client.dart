import 'dart:convert';
import 'package:http/http.dart' as http;
import 'token_storage_service.dart';
import 'auth_api_service.dart';

/// 認証済みHTTPクライアント
/// 自動的にAuthorizationヘッダーを追加し、401/403時にトークンリフレッシュを試みます
class AuthenticatedHttpClient {
  final TokenStorageService _tokenStorage = TokenStorageService();
  final AuthApiService _authService = AuthApiService();

  /// リトライ中かどうか（無限リトライ防止）
  bool _isRetrying = false;

  /// ログアウトコールバック（UIからナビゲーションするために設定）
  Function? onLogout;

  /// GETリクエスト
  Future<http.Response> get(String url, {Map<String, String>? headers}) async {
    return _requestWithRetry(
      () async => http.get(
        Uri.parse(url),
        headers: await _buildHeaders(headers),
      ),
    );
  }

  /// POSTリクエスト
  Future<http.Response> post(
    String url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final encodedBody = body is String ? body : jsonEncode(body);
    return _requestWithRetry(
      () async => http.post(
        Uri.parse(url),
        headers: await _buildHeaders(headers),
        body: encodedBody,
      ),
    );
  }

  /// PUTリクエスト
  Future<http.Response> put(
    String url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final encodedBody = body is String ? body : jsonEncode(body);
    return _requestWithRetry(
      () async => http.put(
        Uri.parse(url),
        headers: await _buildHeaders(headers),
        body: encodedBody,
      ),
    );
  }

  /// DELETEリクエスト
  Future<http.Response> delete(String url, {Map<String, String>? headers}) async {
    return _requestWithRetry(
      () async => http.delete(
        Uri.parse(url),
        headers: await _buildHeaders(headers),
      ),
    );
  }

  /// ヘッダーを構築（Authorizationヘッダーを追加）
  Future<Map<String, String>> _buildHeaders(Map<String, String>? customHeaders) async {
    final accessToken = await _tokenStorage.getAccessToken();
    final headers = {
      'Content-Type': 'application/json',
      if (accessToken != null) 'Authorization': 'Bearer $accessToken',
      ...?customHeaders,
    };
    return headers;
  }

  /// リクエストを実行（401/403時はトークンリフレッシュを試みて1回だけリトライ）
  Future<http.Response> _requestWithRetry(
    Future<http.Response> Function() requestFn,
  ) async {
    final response = await requestFn();

    // 401/403の場合、トークンリフレッシュを試みる（1回のみ）
    if ((response.statusCode == 401 || response.statusCode == 403) && !_isRetrying) {
      final refreshed = await _tryRefreshToken();
      if (refreshed) {
        // リフレッシュ成功、新しいトークンでリトライ
        _isRetrying = true;
        try {
          // requestFnを再実行すると、_buildHeadersが呼ばれて新しいトークンが使われる
          final retryResponse = await requestFn();
          return retryResponse;
        } finally {
          _isRetrying = false;
        }
      } else {
        // リフレッシュ失敗、ログアウト
        await _handleLogout();
      }
    }

    return response;
  }

  /// トークンリフレッシュを試みる
  Future<bool> _tryRefreshToken() async {
    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken == null) {
        return false;
      }

      final response = await _authService.refreshToken(refreshToken);

      // 新しいトークンを保存
      await _tokenStorage.saveAuthData(
        accessToken: response['accessToken'],
        refreshToken: response['refreshToken'] ?? refreshToken,
        userId: response['userId'],
        email: response['email'],
        username: response['username'],
      );

      return true;
    } catch (e) {
      // リフレッシュ失敗
      return false;
    }
  }

  /// ログアウト処理
  Future<void> _handleLogout() async {
    await _tokenStorage.clearAuthData();
    onLogout?.call();
  }
}

/// グローバルインスタンス（シングルトン的に使用）
final authenticatedHttpClient = AuthenticatedHttpClient();
