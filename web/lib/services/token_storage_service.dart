import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// トークンストレージサービス
/// JWTトークンをローカルストレージに保存・取得・削除します
class TokenStorageService {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _emailKey = 'email';
  static const String _usernameKey = 'username';

  final ValueNotifier<int?> _userIdNotifier = ValueNotifier<int?>(null);

  // 後方互換性のためStreamも提供
  Stream<int?> get userIdStream => _userIdNotifier.toStream();

  // 同期的アクセス
  int? get currentUserId => _userIdNotifier.value;

  // ValueListenableアクセス
  ValueListenable<int?> get userIdListenable => _userIdNotifier;

  // コンストラクタで初期化
  TokenStorageService() {
    _initializeUserId();
  }

  Future<void> _initializeUserId() async {
    final userId = await getUserId();
    _userIdNotifier.value = userId;
  }

  /// アクセストークンを保存
  Future<void> saveAccessToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, token);
  }

  /// リフレッシュトークンを保存
  Future<void> saveRefreshToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_refreshTokenKey, token);
  }

  /// ユーザーIDを保存
  Future<void> saveUserId(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_userIdKey, userId);
    _userIdNotifier.value = userId;
  }

  /// メールアドレスを保存
  Future<void> saveEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_emailKey, email);
  }

  /// ユーザー名を保存
  Future<void> saveUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usernameKey, username);
  }

  /// 全ての認証情報を保存
  Future<void> saveAuthData({
    required String accessToken,
    required String refreshToken,
    required int userId,
    required String email,
    String? username,
  }) async {
    await saveAccessToken(accessToken);
    await saveRefreshToken(refreshToken);
    await saveUserId(userId);
    await saveEmail(email);
    if (username != null) {
      await saveUsername(username);
    }
  }

  /// アクセストークンを取得
  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  /// リフレッシュトークンを取得
  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  /// ユーザーIDを取得
  Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey);
  }

  /// メールアドレスを取得
  Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey);
  }

  /// ユーザー名を取得
  Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey);
  }

  /// 認証情報が保存されているかチェック
  Future<bool> hasAuthData() async {
    final accessToken = await getAccessToken();
    final refreshToken = await getRefreshToken();
    return accessToken != null && refreshToken != null;
  }

  /// 全ての認証情報を削除（ログアウト時）
  Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_usernameKey);
    _userIdNotifier.value = null;
  }
}

/// ValueNotifierをStreamに変換する拡張メソッド
extension ValueNotifierStream<T> on ValueNotifier<T> {
  Stream<T> toStream() {
    final controller = StreamController<T>.broadcast();

    // 現在値を即座に配信
    controller.add(value);

    // リスナーで変更を監視（効率的なリアクティブ通知）
    void listener() {
      controller.add(value);
    }
    addListener(listener);

    // ストリームがキャンセルされたらリスナーを削除
    controller.onCancel = () {
      removeListener(listener);
    };

    return controller.stream;
  }
}
