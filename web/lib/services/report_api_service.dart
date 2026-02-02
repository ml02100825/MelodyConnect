import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/report_models.dart';
import '../config/app_config.dart';

String get baseUrl => AppConfig.apiBaseUrl;

class ReportApiService {
  /// 通報を送信
  Future<ReportResponse> submitReport(ReportRequest request, String accessToken) async {
    final response = await http.post(
      Uri.parse("$baseUrl/api/reports"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $accessToken",
      },
      body: json.encode(request.toJson()),
    );

    if (response.statusCode != 200) {
      // エラーレスポンスもReportResponseとしてパースを試みる
      try {
        return ReportResponse.fromJson(json.decode(response.body));
      } catch (e) {
        throw Exception("通報の送信に失敗しました: ${response.statusCode}");
      }
    }

    return ReportResponse.fromJson(json.decode(response.body));
  }
}
