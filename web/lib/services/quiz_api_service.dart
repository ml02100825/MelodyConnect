import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/quiz_models.dart';
import '../config/app_config.dart';

class QuizApiService {
  /// クイズを開始
  Future<QuizStartResponse> startQuiz(QuizStartRequest request, String accessToken) async {
    final response = await http.post(
      Uri.parse("${AppConfig.apiBaseUrl}/api/quiz/start"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $accessToken",
      },
      body: json.encode(request.toJson()),
    );

    if (response.statusCode != 200) {
      // エラーレスポンスからメッセージを取得
      String errorMessage = 'クイズの開始に失敗しました';
      try {
        final errorBody = json.decode(response.body);
        if (errorBody['message'] != null) {
          errorMessage = errorBody['message'];
        }
      } catch (_) {
        // JSONパースに失敗した場合はデフォルトメッセージを使用
      }
      throw Exception(errorMessage);
    }

    return QuizStartResponse.fromJson(json.decode(response.body));
  }

  /// クイズを完了
  Future<QuizCompleteResponse> completeQuiz(QuizCompleteRequest request, String accessToken) async {
    final response = await http.post(
      Uri.parse("${AppConfig.apiBaseUrl}/api/quiz/complete"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $accessToken",
      },
      body: json.encode(request.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception("クイズの完了に失敗しました: ${response.statusCode}");
    }

    return QuizCompleteResponse.fromJson(json.decode(response.body));
  }
}
