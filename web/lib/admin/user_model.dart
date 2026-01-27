class User {
  int numericId;
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
    required this.numericId,
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

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      numericId: json['id'] ?? 0,
      id: json['id']?.toString().padLeft(5, '0') ?? '00000',
      uuid: json['userUuid'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      accountCreated: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      lastLogin: json['offlineAt'] != null
          ? DateTime.parse(json['offlineAt'])
          : DateTime.now(),
      subscriptionRegistered: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'])
          : null,
      subscriptionCancelled: json['canceledAt'] != null
          ? DateTime.parse(json['canceledAt'])
          : null,
      subscription: json['subscribeFlag'] == true ? '加入中' : '×',
      isFrozen: json['banFlag'] == true,
    );
  }

  // 状態変更メソッドを追加
  void freeze() {
    isFrozen = true;
  }

  void unfreeze() {
    isFrozen = false;
  }
}
