# API_BASE_URL を AppConfig 仕様に統一するリファクタリング

## 概要
フロントエンドの全ファイルで `String.fromEnvironment("API_BASE_URL", ...)` を使用している箇所を、`AppConfig.apiBaseUrl` を使用する形式に統一する。

## 現状
- **AppConfig を使用中（変更不要）**: 9ファイル
- **String.fromEnvironment を使用中（変更が必要）**: 6ファイル

## 変更対象ファイル

### 1. [quiz_api_service.dart](web/lib/services/quiz_api_service.dart)
```dart
// 変更前 (Line 5-8)
const baseUrl = String.fromEnvironment(
  "API_BASE_URL",
  defaultValue: "http://localhost:8080",
);

// 変更後
import '../config/app_config.dart';
// baseUrl 定数を削除し、使用箇所で AppConfig.apiBaseUrl を直接使用
```

### 2. [history_api_service.dart](web/lib/services/history_api_service.dart)
```dart
// 変更前 (Line 5-8)
const baseUrl = String.fromEnvironment(
  "API_BASE_URL",
  defaultValue: "http://localhost:8080",
);

// 変更後
import '../config/app_config.dart';
// 以下同様
```

### 3. [report_api_service.dart](web/lib/services/report_api_service.dart)
```dart
// 変更前 (Line 5-8)
const baseUrl = String.fromEnvironment(
  "API_BASE_URL",
  defaultValue: "http://localhost:8080",
);

// 変更後
import '../config/app_config.dart';
```

### 4. [quiz_question_screen.dart](web/lib/screens/quiz_question_screen.dart)
```dart
// 変更前 (Line 8-12)
const String _apiBaseUrl = String.fromEnvironment(
  "API_BASE_URL",
  defaultValue: "http://localhost:8080",
);

// 変更後
import '../config/app_config.dart';
// _apiBaseUrl を削除し、AppConfig.apiBaseUrl を使用
```

### 5. [admin_api_service.dart](web/lib/admin/services/admin_api_service.dart)
```dart
// 変更前 (Line 8-11)
static const String _baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8080',
);

// 変更後
import '../../config/app_config.dart';
static String get _baseUrl => AppConfig.apiBaseUrl;
```

### 6. [admin_auth_service.dart](web/lib/admin/services/admin_auth_service.dart)
```dart
// 変更前 (Line 7-10)
static const String _baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8080',
);

// 変更後
import '../../config/app_config.dart';
static String get _baseUrl => AppConfig.apiBaseUrl;
```

## 実装手順

1. **quiz_api_service.dart** を修正
2. **history_api_service.dart** を修正
3. **report_api_service.dart** を修正
4. **quiz_question_screen.dart** を修正
5. **admin_api_service.dart** を修正
6. **admin_auth_service.dart** を修正

## 検証方法

1. `flutter analyze` でコンパイルエラーがないことを確認
2. アプリを起動し、以下の機能が正常に動作することを確認:
   - クイズ機能（start/complete API）
   - 履歴機能（battle/learning history）
   - 通報機能
   - 管理者ログイン/API呼び出し
