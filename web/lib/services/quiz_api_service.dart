import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/quiz_models.dart';

const baseUrl = String.fromEnvironment(
  "API_BASE_URL",
  defaultValue: "http://10.0.2.2:8080",
);

class QuizApiService {
  /// クイズを開始
  Future<QuizStartResponse> startQuiz(QuizStartRequest request) async {
    final response = await http.post(
      Uri.parse("$baseUrl/api/quiz/start"),
      headers: {"Content-Type": "application/json"},
      body: json.encode(request.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception("クイズの開始に失敗しました: ${response.statusCode}");
    }

    return QuizStartResponse.fromJson(json.decode(response.body));
  }

  /// クイズを完了
  Future<QuizCompleteResponse> completeQuiz(QuizCompleteRequest request) async {
    final response = await http.post(
      Uri.parse("$baseUrl/api/quiz/complete"),
      headers: {"Content-Type": "application/json"},
      body: json.encode(request.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception("クイズの完了に失敗しました: ${response.statusCode}");
    }

    return QuizCompleteResponse.fromJson(json.decode(response.body));
  }
}
