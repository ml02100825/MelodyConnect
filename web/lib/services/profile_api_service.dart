import 'dart:convert';
import 'package:http/http.dart' as http;

class ProfileApiService {
  // 環境に合わせて変更してください
  static const String baseUrl = 'http://localhost:8080/api/profile';

  Future<Map<String, dynamic>> getProfile({
    required int userId,
    required String accessToken,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('プロフィール取得失敗: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> updateProfile({
    required int userId,
    required String username,
    required String userUuid,
    String? imageUrl,
    required String accessToken,
  }) async {
    return _putRequest(
      '$baseUrl/$userId',
      accessToken,
      {
        'username': username,
        'userUuid': userUuid,
        if (imageUrl != null) 'imageUrl': imageUrl,
      },
    );
  }

  // 音量更新メソッドは削除しました

  Future<void> updatePrivacy(int userId, int privacy, String accessToken) async {
    await _putRequest(
      '$baseUrl/$userId/privacy',
      accessToken,
      {'privacy': privacy},
    );
  }

  Future<Map<String, dynamic>> _putRequest(
      String url, String token, Map<String, dynamic> body) async {
    final response = await http.put(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('更新失敗: ${response.body}');
    }
  }
}