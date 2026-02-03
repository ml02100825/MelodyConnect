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

/// 回復アイテム情報モデル
class RecoveryItem {
  final int itemId;
  final String name;
  final String description;
  final int healAmount;
  final int quantity;

  RecoveryItem({
    required this.itemId,
    required this.name,
    required this.description,
    required this.healAmount,
    required this.quantity,
  });

  factory RecoveryItem.fromJson(Map<String, dynamic> json) {
    return RecoveryItem(
      itemId: json['itemId'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      healAmount: json['healAmount'] ?? 0,
      quantity: json['quantity'] ?? 0,
    );
  }
}

/// アイテム使用結果モデル
class UseItemResult {
  final bool success;
  final String message;
  final int newLife;
  final int newQuantity;

  UseItemResult({
    required this.success,
    required this.message,
    required this.newLife,
    required this.newQuantity,
  });

  factory UseItemResult.fromJson(Map<String, dynamic> json) {
    return UseItemResult(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      newLife: json['newLife'] ?? 0,
      newQuantity: json['newQuantity'] ?? 0,
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

  /// 回復アイテム情報を取得
  ///
  /// [userId] - ユーザーID
  /// [accessToken] - アクセストークン
  ///
  /// 返り値: 回復アイテム情報（名前、説明、回復量、所持数）
  /// エラーの場合は例外をスロー
  Future<RecoveryItem> getRecoveryItem({
    required int userId,
    required String accessToken,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/recovery-item?userId=$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return RecoveryItem.fromJson(json);
      } else if (response.statusCode == 404) {
        throw Exception('アイテムが見つかりません');
      } else {
        throw Exception('アイテム情報の取得に失敗しました');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('ネットワークエラーが発生しました');
    }
  }

  /// 回復アイテムを使用
  ///
  /// [userId] - ユーザーID
  /// [itemId] - アイテムID
  /// [accessToken] - アクセストークン
  ///
  /// 返り値: アイテム使用結果
  /// エラーの場合は例外をスロー
  Future<UseItemResult> useRecoveryItem({
    required int userId,
    required int itemId,
    required String accessToken,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/use-item'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'userId': userId,
          'itemId': itemId,
        }),
      );

      final json = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return UseItemResult.fromJson(json);
      } else if (response.statusCode == 400) {
        return UseItemResult.fromJson(json);
      } else if (response.statusCode == 404) {
        throw Exception('ユーザーまたはアイテムが見つかりません');
      } else {
        throw Exception('アイテムの使用に失敗しました');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('ネットワークエラーが発生しました');
    }
  }
}
