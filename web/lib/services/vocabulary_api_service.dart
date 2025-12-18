import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/vocabulary_model.dart';

/// 単語帳APIサービス
class VocabularyApiService {
  // ベースURL（環境に応じて変更）
  static const String _baseUrl = kDebugMode
      ? 'http://localhost:8080'
      : 'http://localhost:8080';

  /// ユーザーの単語一覧を取得
  Future<VocabularyResponse> getUserVocabularies(Long userId, String accessToken) async {
    final url = Uri.parse('$_baseUrl/api/vocabulary/user/$userId');
    
    debugPrint('Fetching vocabularies: $url');
    debugPrint('AccessToken: ${accessToken.isNotEmpty ? "${accessToken.substring(0, 20)}..." : "EMPTY"}');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return VocabularyResponse.fromJson(json);
      } else {
        return VocabularyResponse(
          success: false,
          message: 'サーバーエラー: ${response.statusCode}',
          vocabularies: [],
        );
      }
    } catch (e) {
      debugPrint('Error fetching vocabularies: $e');
      return VocabularyResponse(
        success: false,
        message: '通信エラー: $e',
        vocabularies: [],
      );
    }
  }

  /// お気に入りフラグを更新
  Future<bool> updateFavoriteFlag(int userVocabId, bool favorite, String accessToken) async {
    final url = Uri.parse('$_baseUrl/api/vocabulary/$userVocabId/favorite');
    
    debugPrint('Updating favorite: $url, favorite=$favorite');

    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({'favorite': favorite}),
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['success'] ?? false;
      }
      return false;
    } catch (e) {
      debugPrint('Error updating favorite: $e');
      return false;
    }
  }

  /// 学習済みフラグを更新
  Future<bool> updateLearnedFlag(int userVocabId, bool learned, String accessToken) async {
    final url = Uri.parse('$_baseUrl/api/vocabulary/$userVocabId/learned');
    
    debugPrint('Updating learned: $url, learned=$learned');

    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({'learned': learned}),
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['success'] ?? false;
      }
      return false;
    } catch (e) {
      debugPrint('Error updating learned: $e');
      return false;
    }
  }
}

/// Dart用のLong型（int）
typedef Long = int;