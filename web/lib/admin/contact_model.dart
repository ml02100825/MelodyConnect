class Contact {
  final String id;
  final String name;
  final String email;
  final String category;
  final String status;
  final DateTime createdAt;
  final String content;
  final String? response;

  Contact({
    required this.id,
    required this.name,
    required this.email,
    required this.category,
    required this.status,
    required this.createdAt,
    required this.content,
    this.response,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      category: json['category'] ?? '',
      status: json['status'] ?? '',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      content: json['content'] ?? '',
      response: json['response'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'category': category,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'content': content,
      'response': response,
    };
  }

  // ステータス変更メソッド
  Contact copyWith({
    String? status,
    String? response,
  }) {
    return Contact(
      id: id,
      name: name,
      email: email,
      category: category,
      status: status ?? this.status,
      createdAt: createdAt,
      content: content,
      response: response ?? this.response,
    );
  }
}