import 'dart:convert';
import 'package:flutter/services.dart';

/// アプリケーション設定クラス
/// assets/config.jsonから設定を読み込み、アプリ全体で使用する
class AppConfig {
  static late String apiBaseUrl;

  /// 設定ファイルを読み込む
  /// アプリ起動時（main.dart）に呼び出す必要がある
  static Future<void> load() async {
    try {
      final configString = await rootBundle.loadString('assets/config.json');
      final config = jsonDecode(configString);
      apiBaseUrl = config['apiBaseUrl'] ?? 'http://localhost:8080';
    } catch (e) {
      // config.jsonが存在しない場合はデフォルト値を使用
      apiBaseUrl = 'http://localhost:8080';
    }
  }

  /// WebSocket用のベースURL
  /// HTTPをWS、HTTPSをWSSに自動変換
  static String get wsBaseUrl {
    return apiBaseUrl
        .replaceFirst('http://', 'ws://')
        .replaceFirst('https://', 'wss://');
  }
}
