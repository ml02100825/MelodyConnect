import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/history_models.dart';
import '../config/app_config.dart';

String get baseUrl => AppConfig.apiBaseUrl;

/// 履歴APIサービス
class HistoryApiService {
  // ========== 対戦履歴 ==========

  /// 対戦履歴一覧を取得
  Future<List<BattleHistoryItem>> getBattleHistory(int userId, String accessToken) async {
    final response = await http.get(
      Uri.parse("$baseUrl/api/history/battle/$userId"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $accessToken",
      },
    );

    if (response.statusCode != 200) {
      throw Exception("対戦履歴の取得に失敗しました: ${response.statusCode}");
    }

    final List<dynamic> data = json.decode(response.body);
    return data.map((e) => BattleHistoryItem.fromJson(e)).toList();
  }

  /// 対戦履歴詳細を取得
  Future<BattleHistoryDetail> getBattleHistoryDetail(int resultId, String accessToken) async {
    final response = await http.get(
      Uri.parse("$baseUrl/api/history/battle/detail/$resultId"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $accessToken",
      },
    );

    if (response.statusCode != 200) {
      throw Exception("対戦履歴詳細の取得に失敗しました: ${response.statusCode}");
    }

    return BattleHistoryDetail.fromJson(json.decode(response.body));
  }

  // ========== 学習履歴 ==========

  /// 学習履歴一覧を取得
  Future<List<LearningHistoryItem>> getLearningHistory(int userId, String accessToken) async {
    final response = await http.get(
      Uri.parse("$baseUrl/api/history/learning/$userId"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $accessToken",
      },
    );

    if (response.statusCode != 200) {
      throw Exception("学習履歴の取得に失敗しました: ${response.statusCode}");
    }

    final List<dynamic> data = json.decode(response.body);
    return data.map((e) => LearningHistoryItem.fromJson(e)).toList();
  }

  /// 学習履歴詳細を取得
  Future<LearningHistoryDetail> getLearningHistoryDetail(int historyId, String accessToken) async {
    final response = await http.get(
      Uri.parse("$baseUrl/api/history/learning/detail/$historyId"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $accessToken",
      },
    );

    if (response.statusCode != 200) {
      throw Exception("学習履歴詳細の取得に失敗しました: ${response.statusCode}");
    }

    return LearningHistoryDetail.fromJson(json.decode(response.body));
  }
}
