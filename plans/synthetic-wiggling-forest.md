# 管理画面不具合修正・機能追加 実装計画

## 概要
複数の管理画面で不足している情報の表示とフィルタリング機能を追加します。

## 修正対象

### 1. badge_admin.dart - modeの表示とフィルタリング修正
**問題1**: テーブルにmodeが数値（"1", "2"など）で表示され、意味が分からない
**問題2**: modeでフィルタリングすると何も表示されなくなる
**修正内容**:
- modeを意味のあるテキスト（「コンティニュー」「バトル」など）に変換して表示
- フィルタリングロジックを修正（必要に応じて）

### 2. badge_detail_admin.dart - 削除確認ダイアログにmode表示追加
**問題**: 削除確認ダイアログにバッジのモード情報が表示されていない
**修正内容**: 削除確認ダイアログにmodeのチェックボックスを追加

### 3. user_list_admin.dart - サブスク登録日・解約日の機能追加
**問題**: UIにはフィルタが存在するが、APIに送信されず、テーブルにも表示されていない
**修正内容**: バックエンド・フロントエンド両方を修正して完全に機能させる

### 4. contact_admin.dart - 単語ID・問題IDの表示追加
**問題**: 単語報告と問題報告のテーブルに、それぞれの単語ID・問題IDが表示されていない
**修正内容**: テーブルに「単語ID」列と「問題ID」列を追加

### 5. genre_admin.dart - 追加日の表示追加
**問題**: ジャンル一覧テーブルに追加日が表示されていない
**修正内容**: テーブルに「追加日」列を追加

**注意**: badge_detail_admin2.dartというファイルは存在しません（badge_detail_admin.dartのみ修正）

---

## 実装詳細

### タスク1: badge_admin.dart修正 - modeの表示とフィルタリング

**ファイル**: [web/lib/admin/badge_admin.dart](web/lib/admin/badge_admin.dart)

**問題の原因**:
- バックエンドは`mode`をInteger（1-5）でAPIレスポンスに返す
- DB内は"CONTINUE", "BATTLE", "RANKING", "COLLECT", "SPECIAL"として保存
- フロントエンドは数値を文字列（"1", "2"など）として表示している
- ユーザーには意味が分からない

**変更箇所**:

1. モード変換関数を追加（行438付近、`_convertModeToInt`メソッドの後）
   ```dart
   String _convertModeToDisplay(String mode) {
     if (mode.isEmpty) return '';
     switch (mode) {
       case '1':
         return 'コンティニュー';
       case '2':
         return 'バトル';
       case '3':
         return 'ランキング';
       case '4':
         return 'コレクト';
       case '5':
         return 'スペシャル';
       default:
         return mode;
     }
   }
   ```

2. テーブル表示でmode変換を適用（行657）
   ```dart
   // 変更前
   Text(badge.mode, style: const TextStyle(fontSize: 13), textAlign: TextAlign.center),

   // 変更後
   Text(_convertModeToDisplay(badge.mode), style: const TextStyle(fontSize: 13), textAlign: TextAlign.center),
   ```

3. フィルタドロップダウンのラベルを変更（行107-114）
   ```dart
   // 変更前
   final List<String> _modeOptions = [
     'モード',
     '1',
     '2',
     '3',
     '4',
     '5',
   ];

   // 変更後
   final List<String> _modeOptions = [
     'モード',
     '1 - コンティニュー',
     '2 - バトル',
     '3 - ランキング',
     '4 - コレクト',
     '5 - スペシャル',
   ];
   ```

4. `_convertModeToInt`メソッドを修正して新しいフォーマットに対応（行439-442）
   ```dart
   int? _convertModeToInt(String modeStr) {
     if (modeStr == 'モード' || modeStr.isEmpty) return null;
     // "1 - コンティニュー" から "1" を抽出
     final parts = modeStr.split(' - ');
     if (parts.isNotEmpty) {
       return int.tryParse(parts[0]);
     }
     return int.tryParse(modeStr);
   }
   ```

---

### タスク2: badge_detail_admin.dart修正

**ファイル**: [web/lib/admin/badge_detail_admin.dart](web/lib/admin/badge_detail_admin.dart)

**変更箇所**:
1. 削除確認用の状態変数を追加（行43-46付近）
   ```dart
   bool modeChecked = false;
   ```

2. `allChecked`の判定にmodeCheckedを追加（行530）
   ```dart
   bool allChecked = idChecked && nameChecked && conditionChecked && modeChecked;
   ```

3. 削除確認ダイアログにmodeのCheckboxListTileを追加（conditionの次、行589-601付近）
   ```dart
   CheckboxListTile(
     title: Text('モード: $selectedMode', style: TextStyle(fontSize: 14)),
     value: modeChecked,
     onChanged: (bool? value) {
       setState(() {
         modeChecked = value ?? false;
       });
     },
   ),
   ```

---

### タスク3: user_list_admin.dart修正（バックエンド）

#### 3-1: AdminUserListResponse.java修正

**ファイル**: [api/src/main/java/com/example/api/dto/admin/AdminUserListResponse.java](api/src/main/java/com/example/api/dto/admin/AdminUserListResponse.java)

**変更箇所**: AdminUserSummaryクラス（行29-57）にフィールドを追加

```java
private LocalDateTime expiresAt;      // サブスク登録日（有効期限）
private LocalDateTime canceledAt;     // サブスク解約日

// Getters and Setters
public LocalDateTime getExpiresAt() { return expiresAt; }
public void setExpiresAt(LocalDateTime expiresAt) { this.expiresAt = expiresAt; }
public LocalDateTime getCanceledAt() { return canceledAt; }
public void setCanceledAt(LocalDateTime canceledAt) { this.canceledAt = canceledAt; }
```

#### 3-2: AdminUserService.java修正

**ファイル**: [api/src/main/java/com/example/api/service/admin/AdminUserService.java](api/src/main/java/com/example/api/service/admin/AdminUserService.java)

**変更箇所1**: getUsersメソッドのシグネチャを拡張（パラメータ追加）
```java
public AdminUserListResponse getUsers(
    int page, int size, Long id, String userUuid, String username, String email,
    Boolean banFlag, Boolean subscribeFlag,
    LocalDateTime createdFrom, LocalDateTime createdTo,
    LocalDateTime offlineFrom, LocalDateTime offlineTo,
    LocalDateTime expiresFrom, LocalDateTime expiresTo,      // 追加
    LocalDateTime canceledFrom, LocalDateTime canceledTo,    // 追加
    String sortDirection) {
```

**変更箇所2**: Specificationの構築で検索条件を追加
```java
if (expiresFrom != null) {
    spec = spec.and((root, query, cb) -> cb.greaterThanOrEqualTo(root.get("expiresAt"), expiresFrom));
}
if (expiresTo != null) {
    spec = spec.and((root, query, cb) -> cb.lessThanOrEqualTo(root.get("expiresAt"), expiresTo));
}
if (canceledFrom != null) {
    spec = spec.and((root, query, cb) -> cb.greaterThanOrEqualTo(root.get("canceledAt"), canceledFrom));
}
if (canceledTo != null) {
    spec = spec.and((root, query, cb) -> cb.lessThanOrEqualTo(root.get("canceledAt"), canceledTo));
}
```

**変更箇所3**: toUserSummaryメソッドでフィールドを設定（行146-157）
```java
summary.setExpiresAt(user.getExpiresAt());
summary.setCanceledAt(user.getCanceledAt());
```

#### 3-3: AdminUserController.java修正

**ファイル**: [api/src/main/java/com/example/api/controller/admin/AdminUserController.java](api/src/main/java/com/example/api/controller/admin/AdminUserController.java)

**変更箇所1**: getUsersメソッドのパラメータを追加（行34-48）
```java
@GetMapping
public ResponseEntity<?> getUsers(
    // ... 既存のパラメータ ...
    @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime offlineFrom,
    @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime offlineTo,
    @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime expiresFrom,
    @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime expiresTo,
    @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime canceledFrom,
    @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime canceledTo,
    @RequestParam(defaultValue = "desc") String sortDirection) {
```

**変更箇所2**: サービス呼び出しにパラメータを追加（行51-53）
```java
AdminUserListResponse response = adminUserService.getUsers(
    page, size, id, userUuid, username, email,
    banFlag, subscribeFlag, createdFrom, createdTo, offlineFrom, offlineTo,
    expiresFrom, expiresTo, canceledFrom, canceledTo, sortDirection);
```

---

### タスク4: user_list_admin.dart修正（フロントエンド）

#### 4-1: admin_api_service.dart修正

**ファイル**: [web/lib/admin/services/admin_api_service.dart](web/lib/admin/services/admin_api_service.dart)

**変更箇所**: getUsersメソッドにパラメータを追加
```dart
static Future<Map<String, dynamic>> getUsers({
  // ... 既存のパラメータ ...
  DateTime? offlineFrom,
  DateTime? offlineTo,
  DateTime? expiresFrom,        // 追加
  DateTime? expiresTo,          // 追加
  DateTime? canceledFrom,       // 追加
  DateTime? canceledTo,         // 追加
  String sortDirection = 'desc',
}) async {
```

クエリパラメータに追加:
```dart
if (expiresFrom != null) queryParams['expiresFrom'] = expiresFrom.toIso8601String();
if (expiresTo != null) queryParams['expiresTo'] = expiresTo.toIso8601String();
if (canceledFrom != null) queryParams['canceledFrom'] = canceledFrom.toIso8601String();
if (canceledTo != null) queryParams['canceledTo'] = canceledTo.toIso8601String();
```

#### 4-2: user_model.dart修正

**ファイル**: [web/lib/admin/models/user_model.dart](web/lib/admin/models/user_model.dart)

**変更箇所**: JSONキーを修正（行41-46）
```dart
subscriptionRegistered: json['expiresAt'] != null      // 'subscriptionRegisteredAt' → 'expiresAt'
    ? DateTime.parse(json['expiresAt'])
    : null,
subscriptionCancelled: json['canceledAt'] != null     // 'subscriptionCancelledAt' → 'canceledAt'
    ? DateTime.parse(json['canceledAt'])
    : null,
```

#### 4-3: user_list_admin.dart修正

**ファイル**: [web/lib/admin/user_list_admin.dart](web/lib/admin/user_list_admin.dart)

**変更箇所1**: API呼び出しにパラメータを追加（行54-95）
```dart
final response = await AdminApiService.getUsers(
  // ... 既存のパラメータ ...
  offlineFrom: lastLoginStart,
  offlineTo: lastLoginEnd,
  expiresFrom: subscRegistStart,     // 追加
  expiresTo: subscRegistEnd,         // 追加
  canceledFrom: subscCancelStart,    // 追加
  canceledTo: subscCancelEnd,        // 追加
  sortDirection: _sortAscending ? 'asc' : 'desc',
);
```

**変更箇所2**: テーブルヘッダーに列を追加（行691-735、最終ログイン日の後）
```dart
_buildTableHeader('サブスク登録日', 180),
_buildTableHeader('サブスク解約日', 180),
```

**変更箇所3**: テーブルデータ行に列を追加（行775-823、offlineAtの後）
```dart
_buildTableCell(
  user.subscriptionRegistered != null
      ? '${user.subscriptionRegistered!.year}/${user.subscriptionRegistered!.month.toString().padLeft(2, '0')}/${user.subscriptionRegistered!.day.toString().padLeft(2, '0')} ${user.subscriptionRegistered!.hour.toString().padLeft(2, '0')}:${user.subscriptionRegistered!.minute.toString().padLeft(2, '0')}'
      : '-',
  180,
),
_buildTableCell(
  user.subscriptionCancelled != null
      ? '${user.subscriptionCancelled!.year}/${user.subscriptionCancelled!.month.toString().padLeft(2, '0')}/${user.subscriptionCancelled!.day.toString().padLeft(2, '0')} ${user.subscriptionCancelled!.hour.toString().padLeft(2, '0')}:${user.subscriptionCancelled!.minute.toString().padLeft(2, '0')}'
      : '-',
  180,
),
```

---

### タスク5: contact_admin.dart修正

**ファイル**: [web/lib/admin/contact_admin.dart](web/lib/admin/contact_admin.dart)

#### 5-1: 単語報告テーブル修正（行370-440）

**変更箇所1**: ヘッダー行に「単語ID」列を追加（行381-389、IDの次）
```dart
_buildTableHeader('ID', 1),
_buildTableHeader('単語ID', 1),     // 追加
_buildTableHeader('単語', 2),
```

**変更箇所2**: データ行に単語ID列を追加（行410-432、IDの次）
```dart
_buildTableCell(item['id'] ?? '', 1),
_buildTableCell(item['vocabularyId']?.toString() ?? '', 1),  // 追加
_buildTableCell(item['word'] ?? '', 2),
```

#### 5-2: 問題報告テーブル修正（行442-512）

**変更箇所1**: ヘッダー行に「問題ID」列を追加（行453-461、IDの次）
```dart
_buildTableHeader('ID', 1),
_buildTableHeader('問題ID', 1),     // 追加
_buildTableHeader('問題文', 3),
```

**変更箇所2**: データ行に問題ID列を追加（行482-504、IDの次）
```dart
_buildTableCell(item['id'] ?? '', 1),
_buildTableCell(item['questionId']?.toString() ?? '', 1),  // 追加
_buildTableCell(item['questionText'] ?? '', 3),
```

---

### タスク6: genre_admin.dart修正

**ファイル**: [web/lib/admin/genre_admin.dart](web/lib/admin/genre_admin.dart)

**変更箇所1**: テーブルヘッダーに「追加日」列を追加（行618-625、ジャンル名の後）
```dart
_buildTableHeader('', 1),             // チェックボックス
_buildTableHeader('ID', 2),
_buildTableHeader('ジャンル名', 3),
_buildTableHeader('追加日', 2),       // 追加
_buildTableHeader('状態', 2),
```

**変更箇所2**: データ行に追加日セルを追加（行648-664、genre.nameの後）
```dart
_buildTableCell(genre.id.toString(), 2),
_buildTableCell(genre.name, 3),
_buildTableCell(                                                               // 追加
  '${genre.addedDate.year}/${genre.addedDate.month.toString().padLeft(2, '0')}/${genre.addedDate.day.toString().padLeft(2, '0')}',
  2,
  TextAlign.center,
),
_buildTableCell(genre.enabled ? '有効' : '無効', 2, TextAlign.center),
```

---

## 検証方法

### 1. badge_admin.dart
1. バッジ一覧画面を開く
2. 「モード」列に意味のあるテキスト（「コンティニュー」「バトル」など）が表示されることを確認
3. モードフィルタのドロップダウンを開く
4. 「1 - コンティニュー」「2 - バトル」などのラベルが表示されることを確認
5. いずれかのモードを選択してフィルタリング
6. 該当するバッジのみが表示されることを確認（何も表示されない問題が解消されていることを確認）

### 2. badge_detail_admin.dart
1. 管理画面でバッジ詳細を開く
2. 「バッジ削除」ボタンをクリック
3. 削除確認ダイアログに「モード: X」（Xは1-5）のチェックボックスが表示されることを確認
4. すべてのチェックボックス（ID、バッジ名、取得条件、モード）をチェックするまで削除ボタンが無効化されることを確認

### 3. user_list_admin.dart
1. アプリケーションを再起動（バックエンド修正を反映）
2. ユーザー一覧画面を開く
3. サブスク登録日フィルタで期間を指定して検索
4. フィルタが正しく機能することを確認
5. テーブルに「サブスク登録日」「サブスク解約日」列が表示されることを確認
6. サブスク未登録ユーザーは「-」と表示されることを確認
7. サブスク解約日フィルタでも同様に動作確認

### 4. contact_admin.dart
1. お問い合わせ管理画面を開く
2. 単語報告タブを開き、テーブルに「単語ID」列が表示されることを確認
3. 単語IDが正しく表示されることを確認
4. 問題報告タブを開き、テーブルに「問題ID」列が表示されることを確認
5. 問題IDが正しく表示されることを確認

### 5. genre_admin.dart
1. ジャンル管理画面を開く
2. テーブルに「追加日」列が表示されることを確認
3. 追加日が「YYYY/MM/DD」形式で正しく表示されることを確認

---

## Critical Files

### フロントエンド
- [web/lib/admin/badge_admin.dart](web/lib/admin/badge_admin.dart)
- [web/lib/admin/badge_detail_admin.dart](web/lib/admin/badge_detail_admin.dart)
- [web/lib/admin/user_list_admin.dart](web/lib/admin/user_list_admin.dart)
- [web/lib/admin/models/user_model.dart](web/lib/admin/models/user_model.dart)
- [web/lib/admin/services/admin_api_service.dart](web/lib/admin/services/admin_api_service.dart)
- [web/lib/admin/contact_admin.dart](web/lib/admin/contact_admin.dart)
- [web/lib/admin/genre_admin.dart](web/lib/admin/genre_admin.dart)

### バックエンド
- [api/src/main/java/com/example/api/dto/admin/AdminUserListResponse.java](api/src/main/java/com/example/api/dto/admin/AdminUserListResponse.java)
- [api/src/main/java/com/example/api/service/admin/AdminUserService.java](api/src/main/java/com/example/api/service/admin/AdminUserService.java)
- [api/src/main/java/com/example/api/controller/admin/AdminUserController.java](api/src/main/java/com/example/api/controller/admin/AdminUserController.java)

---

## 実装順序

1. **badge_admin.dart** - 独立した修正、他に影響なし
2. **badge_detail_admin.dart** - 独立した修正、他に影響なし
3. **contact_admin.dart** - 独立した修正、他に影響なし
4. **genre_admin.dart** - 独立した修正、他に影響なし
5. **バックエンド修正**（AdminUserListResponse → AdminUserService → AdminUserController）
6. **フロントエンド修正**（user_model.dart → admin_api_service.dart → user_list_admin.dart）

タスク1-4は並行実装可能。タスク5-6は順序が重要（バックエンド→フロントエンド）。
