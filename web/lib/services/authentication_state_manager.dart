import 'package:flutter/foundation.dart';
import 'token_storage_service.dart';

/// 認証状態
enum AuthenticationStatus {
  unauthenticated, // 未認証
  authenticating, // 認証中
  authenticated, // 認証済み
}

/// 認証状態管理サービス
class AuthenticationStateManager {
  static final AuthenticationStateManager _instance =
      AuthenticationStateManager._internal();
  factory AuthenticationStateManager() => _instance;
  AuthenticationStateManager._internal();

  final TokenStorageService _tokenStorage = TokenStorageService();

  final ValueNotifier<AuthenticationStatus> _statusNotifier =
      ValueNotifier<AuthenticationStatus>(AuthenticationStatus.unauthenticated);

  final ValueNotifier<int?> _userIdNotifier = ValueNotifier<int?>(null);

  /// 現在の認証状態
  AuthenticationStatus get status => _statusNotifier.value;
  ValueListenable<AuthenticationStatus> get statusListenable => _statusNotifier;

  /// 現在のユーザーID
  int? get userId => _userIdNotifier.value;
  ValueListenable<int?> get userIdListenable => _userIdNotifier;

  /// 認証済みかつuserIdが存在するか
  bool get isAuthenticatedWithUserId =>
      _statusNotifier.value == AuthenticationStatus.authenticated &&
      _userIdNotifier.value != null;

  /// 初期化（アプリ起動時に呼び出し）
  Future<void> initialize() async {
    final userId = await _tokenStorage.getUserId();
    final hasAuth = await _tokenStorage.hasAuthData();

    if (userId != null && hasAuth) {
      _userIdNotifier.value = userId;
      _statusNotifier.value = AuthenticationStatus.authenticated;
      debugPrint('AuthenticationStateManager: Initialized with userId=$userId');
    } else {
      _userIdNotifier.value = null;
      _statusNotifier.value = AuthenticationStatus.unauthenticated;
      debugPrint('AuthenticationStateManager: Initialized as unauthenticated');
    }
  }

  /// ログイン開始
  void startAuthentication() {
    _statusNotifier.value = AuthenticationStatus.authenticating;
    debugPrint('AuthenticationStateManager: Authentication started');
  }

  /// ログイン完了
  Future<void> completeAuthentication(int userId) async {
    _userIdNotifier.value = userId;
    _statusNotifier.value = AuthenticationStatus.authenticated;
    debugPrint('AuthenticationStateManager: Authentication completed with userId=$userId');
  }

  /// ログアウト
  Future<void> logout() async {
    _userIdNotifier.value = null;
    _statusNotifier.value = AuthenticationStatus.unauthenticated;
    debugPrint('AuthenticationStateManager: Logged out');
  }

  /// TokenStorageServiceの変更を監視して同期
  void syncWithTokenStorage() {
    _tokenStorage.userIdListenable.addListener(() {
      final newUserId = _tokenStorage.currentUserId;
      if (newUserId != _userIdNotifier.value) {
        _userIdNotifier.value = newUserId;
        if (newUserId != null) {
          _statusNotifier.value = AuthenticationStatus.authenticated;
          debugPrint('AuthenticationStateManager: Synced userId=$newUserId from TokenStorage');
        } else {
          _statusNotifier.value = AuthenticationStatus.unauthenticated;
          debugPrint('AuthenticationStateManager: Synced logout from TokenStorage');
        }
      }
    });
  }
}
