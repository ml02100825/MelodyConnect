import 'dart:convert';
import 'package:http/http.dart' as http;

/// プロフィールAPIサービス
/// バックエンドのプロフィールエンドポイントとの通信を行います
class ProfileApiService {
  // 開発環境のAPIベースURL（本番環境では適切なURLに変更してください）
  static const String baseUrl = 'http://localhost:8080/api/profile';

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
  Future<Map<String, dynamic>> updateProfile({
    required int userId,
    required String username,
    required String userUuid,
    String? imageUrl,
    required String accessToken,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'username': username,
          'userUuid': userUuid,
          if (imageUrl != null && imageUrl.isNotEmpty) 'imageUrl': imageUrl,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'プロフィール更新に失敗しました');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('ネットワークエラーが発生しました');
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
