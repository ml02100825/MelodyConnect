# VocabularyReport / QuestionReport 管理機能の実装計画

## 概要
管理者画面に単語報告(VocabularyReport)と問題報告(QuestionReport)の管理機能を追加する。

## 重要な発見事項
- **両エンティティには現在 `status` と `adminMemo` フィールドが存在しない**
- リポジトリは既に存在するが、`JpaSpecificationExecutor` を追加する必要あり

---

## Phase 1: バックエンド - エンティティ修正

### 1.1 VocabularyReport.java
**ファイル:** `api/src/main/java/com/example/api/entity/VocabularyReport.java`

追加フィールド:
- `status` (String, 20文字, デフォルト="未対応")
- `adminMemo` (String, TEXT, @Lob)
- インデックス: `idx_vocabulary_report_status`

### 1.2 QuestionReport.java
**ファイル:** `api/src/main/java/com/example/api/entity/QuestionReport.java`

追加フィールド: (VocabularyReportと同様)

---

## Phase 2: バックエンド - リポジトリ修正

### 2.1 VocabularyReportRepository.java
`JpaSpecificationExecutor<VocabularyReport>` を追加

### 2.2 QuestionReportRepository.java
`JpaSpecificationExecutor<QuestionReport>` を追加

---

## Phase 3: バックエンド - DTO作成

### 3.1 AdminVocabularyReportResponse.java
**ファイル:** `api/src/main/java/com/example/api/dto/admin/AdminVocabularyReportResponse.java`

フィールド:
- vocabularyReportId, vocabularyId, word, meaningJa (Vocabularyから取得)
- userId, userEmail (Userから取得)
- reportContent, status, adminMemo, addedAt

内部クラス `ListResponse`: vocabularyReports, page, size, totalElements, totalPages

### 3.2 AdminQuestionReportResponse.java
**ファイル:** `api/src/main/java/com/example/api/dto/admin/AdminQuestionReportResponse.java`

フィールド:
- questionReportId, questionId, questionText, answer, songName, artistName (Question/Songから取得)
- userId, userEmail (Userから取得)
- reportContent, status, adminMemo, addedAt

内部クラス `ListResponse`: questionReports, page, size, totalElements, totalPages

### 3.3 VocabularyReportStatusUpdateRequest.java
**ファイル:** `api/src/main/java/com/example/api/dto/admin/VocabularyReportStatusUpdateRequest.java`

フィールド: status (@NotBlank), adminMemo (任意)

### 3.4 QuestionReportStatusUpdateRequest.java
**ファイル:** `api/src/main/java/com/example/api/dto/admin/QuestionReportStatusUpdateRequest.java`

フィールド: (同様)

---

## Phase 4: バックエンド - サービス作成

### 4.1 AdminVocabularyReportService.java
**ファイル:** `api/src/main/java/com/example/api/service/admin/AdminVocabularyReportService.java`

メソッド:
- `getVocabularyReports(int page, int size, String status)` → ListResponse
- `getVocabularyReport(Long reportId)` → Response
- `updateVocabularyReportStatus(Long reportId, Request)` → Response (@Transactional)

### 4.2 AdminQuestionReportService.java
**ファイル:** `api/src/main/java/com/example/api/service/admin/AdminQuestionReportService.java`

メソッド: (同様のパターン)

---

## Phase 5: バックエンド - コントローラ作成

### 5.1 AdminVocabularyReportController.java
**ファイル:** `api/src/main/java/com/example/api/controller/admin/AdminVocabularyReportController.java`

ベースパス: `/api/admin/vocabulary-reports`

エンドポイント:
- `GET /` - 一覧取得 (page, size, status パラメータ)
- `GET /{id}` - 詳細取得
- `PUT /{id}/status` - ステータス更新

### 5.2 AdminQuestionReportController.java
**ファイル:** `api/src/main/java/com/example/api/controller/admin/AdminQuestionReportController.java`

ベースパス: `/api/admin/question-reports`

エンドポイント: (同様)

---

## Phase 6: フロントエンド - APIサービス

### 6.1 admin_api_service.dart
**ファイル:** `web/lib/admin/services/admin_api_service.dart`

追加メソッド:
```dart
// 単語報告
static Future<Map<String, dynamic>> getVocabularyReports({page, size, status})
static Future<Map<String, dynamic>> getVocabularyReport(int reportId)
static Future<Map<String, dynamic>> updateVocabularyReportStatus(int reportId, String status, String? adminMemo)

// 問題報告
static Future<Map<String, dynamic>> getQuestionReports({page, size, status})
static Future<Map<String, dynamic>> getQuestionReport(int reportId)
static Future<Map<String, dynamic>> updateQuestionReportStatus(int reportId, String status, String? adminMemo)
```

---

## Phase 7: フロントエンド - UI変更

### 7.1 contact_admin.dart の修正
**ファイル:** `web/lib/admin/contact_admin.dart`

変更内容:
1. 新しいstate変数追加: `String selectedTopTab = 'お問い合わせ';`
2. `_buildMainContent()` を修正して上部タブを追加
3. タブに応じたデータ読み込みとテーブル表示の切り替え

UI構造:
```
+-------------------------------------------+
| お問い合わせ | 単語報告 | 問題報告          |  ← 新規追加（上部タブ）
+-------------------------------------------+
| 未読 | 進行中 | 完了                       |  ← 既存（ステータスフィルタ）
+-------------------------------------------+
| DataTable (選択されたタブに応じた内容)      |
+-------------------------------------------+
| Pagination                                 |
+-------------------------------------------+
```

各タブのテーブルカラム:
- **お問い合わせ**: ID, ユーザー名, 件名, ステータス, 受信日時, 詳細
- **単語報告**: ID, 単語, 報告者, 報告内容(truncated), ステータス, 報告日時, 詳細
- **問題報告**: ID, 問題文(truncated), 曲名, 報告者, ステータス, 報告日時, 詳細

### 7.2 詳細ページの作成

**vocabulary_report_detail.dart** (新規作成)
**ファイル:** `web/lib/admin/vocabulary_report_detail.dart`

表示内容 (全カラム):
- 報告ID, 単語ID, 単語, 意味
- ユーザーID, ユーザーメール
- 報告内容 (全文)
- ステータス (ドロップダウン)
- 管理者メモ (テキストエリア)
- 報告日時
- 保存ボタン, 完了ボタン

**question_report_detail.dart** (新規作成)
**ファイル:** `web/lib/admin/question_report_detail.dart`

表示内容 (全カラム):
- 報告ID, 問題ID, 問題文, 回答
- 曲名, アーティスト名
- ユーザーID, ユーザーメール
- 報告内容 (全文)
- ステータス (ドロップダウン)
- 管理者メモ (テキストエリア)
- 報告日時
- 保存ボタン, 完了ボタン

---

## 実装順序

1. **エンティティ修正** (VocabularyReport.java, QuestionReport.java)
2. **リポジトリ修正** (JpaSpecificationExecutor追加)
3. **DTO作成** (4ファイル)
4. **サービス作成** (2ファイル)
5. **コントローラ作成** (2ファイル)
6. **フロントエンドAPI** (admin_api_service.dart)
7. **フロントエンドUI** (contact_admin.dart修正、詳細ページ2ファイル作成)

---

## 作成/修正ファイル一覧

### バックエンド (10ファイル)
| 操作 | ファイルパス |
|------|-------------|
| 修正 | `api/src/main/java/com/example/api/entity/VocabularyReport.java` |
| 修正 | `api/src/main/java/com/example/api/entity/QuestionReport.java` |
| 修正 | `api/src/main/java/com/example/api/repository/VocabularyReportRepository.java` |
| 修正 | `api/src/main/java/com/example/api/repository/QuestionReportRepository.java` |
| 新規 | `api/src/main/java/com/example/api/dto/admin/AdminVocabularyReportResponse.java` |
| 新規 | `api/src/main/java/com/example/api/dto/admin/AdminQuestionReportResponse.java` |
| 新規 | `api/src/main/java/com/example/api/dto/admin/VocabularyReportStatusUpdateRequest.java` |
| 新規 | `api/src/main/java/com/example/api/dto/admin/QuestionReportStatusUpdateRequest.java` |
| 新規 | `api/src/main/java/com/example/api/service/admin/AdminVocabularyReportService.java` |
| 新規 | `api/src/main/java/com/example/api/service/admin/AdminQuestionReportService.java` |
| 新規 | `api/src/main/java/com/example/api/controller/admin/AdminVocabularyReportController.java` |
| 新規 | `api/src/main/java/com/example/api/controller/admin/AdminQuestionReportController.java` |

### フロントエンド (4ファイル)
| 操作 | ファイルパス |
|------|-------------|
| 修正 | `web/lib/admin/services/admin_api_service.dart` |
| 修正 | `web/lib/admin/contact_admin.dart` |
| 新規 | `web/lib/admin/vocabulary_report_detail.dart` |
| 新規 | `web/lib/admin/question_report_detail.dart` |

---

## 検証方法

1. **バックエンドAPI確認**
   - `GET /api/admin/vocabulary-reports?status=未対応` で一覧取得
   - `GET /api/admin/question-reports?status=未対応` で一覧取得
   - 各詳細エンドポイントとステータス更新エンドポイントの動作確認

2. **フロントエンドUI確認**
   - `/admin/contacts` にアクセス
   - 上部タブ（お問い合わせ/単語報告/問題報告）の切り替え確認
   - 各タブでステータスフィルタ（未読/進行中/完了）の動作確認
   - 詳細ページでの全カラム表示確認
   - ステータス更新と管理者メモの保存確認

3. **データベース確認**
   - `vocabulary_report` テーブルに `status`, `admin_memo` カラムが追加されていること
   - `question_report` テーブルに `status`, `admin_memo` カラムが追加されていること
