import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:flutter_webapp/config/app_config.dart';

/// プロフィールAPIサービス
/// バックエンドのプロフィールエンドポイントとの通信を行います
class ProfileApiService {
  String get baseUrl => '${AppConfig.apiBaseUrl}/api/profile';

  /// プロフィール更新（ステップ2: ユーザー名、ユーザーID、アイコン設定）
  ///
  /// [userId] - ユーザーID
  /// [username] - ユーザー名
  /// [userUuid] - ユーザーID（フレンド申請用）
  /// [imageUrl] - アイコン画像のURL（オプション）
  /// [accessToken] - アクセストークン
  ///
  /// 返り値: 更新されたユーザー情報
  /// エラーの場合は例外をスロー
  Future<Map<String, dynamic>> updateProfileMultipart({
  required int userId,
  required String username,
  required String userUuid,
  Uint8List? imageBytes,
  String? filename,
  required String accessToken,
}) async {
  final request = http.MultipartRequest(
    'PUT',
    Uri.parse('$baseUrl/$userId'),
  );

  request.headers['Authorization'] = 'Bearer $accessToken';

  request.fields['username'] = username;
  request.fields['userUuid'] = userUuid;

  if (imageBytes != null && filename != null) {
    request.files.add(
      http.MultipartFile.fromBytes('icon', imageBytes, filename: filename),
    );
  }

  final streamed = await request.send();
  final response = await http.Response.fromStream(streamed);

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    final error = jsonDecode(response.body);
    throw Exception(error['error'] ?? 'プロフィール更新に失敗しました');
  }
}


  /// プロフィール取得
  ///
  /// [userId] - ユーザーID
  /// [accessToken] - アクセストークン
  ///
  /// 返り値: ユーザー情報
  /// エラーの場合は例外をスロー
  Future<Map<String, dynamic>> getProfile({
    required int userId,
    required String accessToken,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'プロフィール取得に失敗しました');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('ネットワークエラーが発生しました');
    }
  }
}
