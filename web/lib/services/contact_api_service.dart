import 'dart:convert';
import 'package:http/http.dart' as http;

class ContactApiService {
  // 環境に合わせて変更してください
  static const String baseUrl = 'http://localhost:8080/api/contacts';

  Future<void> createContact({
    required String title,
    required String content, // 画面側はcontentという名前で扱っていますが、送信時に変換します
    String? imageUrl,
    required String accessToken,
  }) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({
        // Java側のContactRequestクラスのフィールド名に合わせる
        'title': title,
        'contactDetail': content, 
        'imageUrl': imageUrl,
      }),
    );

    if (response.statusCode != 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(body['error'] ?? '送信に失敗しました (Status: ${response.statusCode})');
    }
  }
}