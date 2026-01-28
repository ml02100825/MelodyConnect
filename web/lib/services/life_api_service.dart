import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_webapp/config/app_config.dart';

/// ライフ状態モデル
class LifeStatus {
  final int currentLife;
  final int maxLife;
  final int nextRecoveryInSeconds;
  final bool isSubscriber;

  LifeStatus({
    required this.currentLife,
    required this.maxLife,
    required this.nextRecoveryInSeconds,
    required this.isSubscriber,
  });

  factory LifeStatus.fromJson(Map<String, dynamic> json) {
    return LifeStatus(
      currentLife: json['currentLife'] ?? 0,
      maxLife: json['maxLife'] ?? 5,
      nextRecoveryInSeconds: json['nextRecoveryInSeconds'] ?? 0,
      isSubscriber: json['subscriber'] ?? false,
    );
  }
}

/// ライフAPIサービス
/// バックエンドのライフエンドポイントとの通信を行います
class LifeApiService {
  String get baseUrl => '${AppConfig.apiBaseUrl}/api/life';

  /// ライフ状態を取得
  ///
  /// [userId] - ユーザーID
  /// [accessToken] - アクセストークン
  ///
  /// 返り値: ライフ状態
  /// エラーの場合は例外をスロー
  Future<LifeStatus> getLifeStatus({
    required int userId,
    required String accessToken,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?userId=$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return LifeStatus.fromJson(json);
      } else if (response.statusCode == 404) {
        throw Exception('ユーザーが見つかりません');
      } else {
        throw Exception('ライフ状態の取得に失敗しました');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('ネットワークエラーが発生しました');
    }
  }
}
