import 'package:flutter/material.dart';
import 'services/admin_token_storage_service.dart';

/// 管理者ルートガード
/// 管理者トークンが存在しない場合はログイン画面へリダイレクト
class AdminRouteGuard extends StatefulWidget {
  final Widget child;

  const AdminRouteGuard({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  _AdminRouteGuardState createState() => _AdminRouteGuardState();
}

class _AdminRouteGuardState extends State<AdminRouteGuard> {
  bool _isChecking = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    final hasToken = await AdminTokenStorageService.hasToken();

    if (mounted) {
      if (hasToken) {
        setState(() {
          _isAuthenticated = true;
          _isChecking = false;
        });
      } else {
        // 未認証の場合はログイン画面へリダイレクト
        Navigator.of(context).pushReplacementNamed('/admin/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_isAuthenticated) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return widget.child;
  }
}
