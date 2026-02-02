import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'token_storage_service.dart';

/// S3画像アップロードサービス
///
/// 画像をS3にアップロードする共通処理を提供します。
/// バックエンドの /api/upload/image エンドポイントを使用します。
class S3ImageUploadService {
  String get baseUrl => '${AppConfig.apiBaseUrl}/api/upload';

  /// 画像をS3にアップロードしてURLを取得
  ///
  /// [imageBytes] - 画像のバイトデータ
  /// [filename] - ファイル名
  ///
  /// 返り値: アップロードされた画像のURL
  /// エラーの場合は例外をスロー
  Future<String> uploadImage({
    required Uint8List imageBytes,
    required String filename,
  }) async {
    try {
      final token = await TokenStorageService().getAccessToken();
      if (token == null) {
        throw Exception('認証トークンが見つかりません');
      }

      final uri = Uri.parse('$baseUrl/image');
      final request = http.MultipartRequest('POST', uri);

      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: filename,
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['imageUrl'];
      } else {
        final error = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(error['error'] ?? '画像のアップロードに失敗しました');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('ネットワークエラーが発生しました');
    }
  }
}
