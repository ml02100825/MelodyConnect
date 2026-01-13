class User {
  String id;
  final String uuid;
  String username;
  final String email;
  final DateTime accountCreated;
  final DateTime lastLogin;
  DateTime? subscriptionRegistered;
  DateTime? subscriptionCancelled;
  String subscription;
  bool isFrozen;

  User({
    required this.id,
    required this.uuid,
    required this.username,
    required this.email,
    required this.accountCreated,
    required this.lastLogin,
    this.subscriptionRegistered,
    this.subscriptionCancelled,
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
}