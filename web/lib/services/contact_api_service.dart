import 'dart:convert';
import 'package:http/http.dart' as http;
import 'token_storage_service.dart';

class ContactApiService {
  // 環境に合わせてURLを変更してください
  static const String _baseUrl = 'http://localhost:8080/api/contacts';
  final TokenStorageService _tokenStorage = TokenStorageService();

  Future<void> submitContact({
    required String title,
    required String detail,
    String? imageUrl,
  }) async {
    final token = await _tokenStorage.getAccessToken();
    if (token == null) {
      throw Exception('ログインしてください');
    }

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'title': title,
        'contactDetail': detail,
        'imageUrl': imageUrl,
      }),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? '送信に失敗しました');
    }
  }
}