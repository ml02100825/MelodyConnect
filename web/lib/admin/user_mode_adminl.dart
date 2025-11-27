class User {
  String id;
  final String uuid;
  String username;
  final String email;
  final DateTime lastLogin;
  String subscription;
  bool isFrozen;

  User({
    required this.id,
    required this.uuid,
    required this.username,
    required this.email,
    required this.lastLogin,
    required this.subscription,
    required this.isFrozen,
  });

  // 状態変更メソッドを追加
  void freeze() {
    isFrozen = true;
  }

  void unfreeze() {
    isFrozen = false;
  }

  // 既存のメソッドはそのまま...
}