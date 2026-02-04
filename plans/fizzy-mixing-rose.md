# ライフ回復アイテム使用機能 実装計画

## 概要
ライフが0の場合のみ、ホーム画面のライフ表示の右に「+」ボタンを表示し、タップすると回復アイテムの使用確認ダイアログを表示する。

## 修正対象ファイル

### バックエンド（Java/Spring Boot）
| ファイル | 変更内容 |
|---------|---------|
| `api/src/main/java/com/example/api/dto/RecoveryItemResponse.java` | **新規** アイテム情報レスポンスDTO |
| `api/src/main/java/com/example/api/dto/UseItemRequest.java` | **新規** アイテム使用リクエストDTO |
| `api/src/main/java/com/example/api/dto/UseItemResponse.java` | **新規** アイテム使用レスポンスDTO |
| `api/src/main/java/com/example/api/repository/UserItemRepository.java` | クエリメソッド追加 |
| `api/src/main/java/com/example/api/service/LifeService.java` | アイテム取得・使用メソッド追加 |
| `api/src/main/java/com/example/api/controller/LifeController.java` | 2エンドポイント追加 |

### フロントエンド（Flutter）
| ファイル | 変更内容 |
|---------|---------|
| `web/lib/services/life_api_service.dart` | モデル2つとメソッド2つ追加 |
| `web/lib/screens/home_screen.dart` | +ボタンとダイアログ実装 |

---

## 実装詳細

### 1. バックエンドAPI

#### 1.1 新規DTO（3ファイル）

**RecoveryItemResponse.java**
```java
public class RecoveryItemResponse {
    private Integer itemId;
    private String name;
    private String description;
    private Integer healAmount;
    private Integer quantity;  // 所持数
}
```

**UseItemRequest.java**
```java
public class UseItemRequest {
    private Long userId;
    private Integer itemId;
}
```

**UseItemResponse.java**
```java
public class UseItemResponse {
    private boolean success;
    private String message;
    private int newLife;
    private int newQuantity;
}
```

#### 1.2 UserItemRepository追加メソッド
```java
Optional<UserItem> findByUserIdAndItemItemId(Long userId, Integer itemId);
```

#### 1.3 LifeService追加メソッド
```java
// 回復アイテム情報取得（itemId=1固定）
public RecoveryItemResponse getRecoveryItem(Long userId)

// アイテム使用してライフ回復
public UseItemResponse useRecoveryItem(Long userId, Integer itemId)
```

#### 1.4 LifeController追加エンドポイント
```
GET  /api/life/recovery-item?userId={userId}  → RecoveryItemResponse
POST /api/life/use-item                       → UseItemResponse
```

---

### 2. フロントエンド

#### 2.1 life_api_service.dart

**新規モデル**
- `RecoveryItem`: itemId, name, description, healAmount, quantity
- `UseItemResult`: success, message, newLife, newQuantity

**新規メソッド**
- `getRecoveryItem()`: GET /api/life/recovery-item
- `useRecoveryItem()`: POST /api/life/use-item

#### 2.2 home_screen.dart

**+ボタン追加（行304付近、ライフアイコンの後に）**
```dart
// ライフが0の場合のみ+ボタンを表示
if (_currentLife == 0) ...[
  const SizedBox(width: 4),
  GestureDetector(
    onTap: _showRecoveryItemDialog,
    child: Container(
      width: 24, height: 24,
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.add, color: Colors.white, size: 16),
    ),
  ),
],
```

**確認ダイアログ（画面中央に表示）**
- アイテム名・説明文・所持数を表示
- 所持数が0の場合：「アイテムがありません」と赤字表示、「はい」ボタン非表示
- 所持数が1以上：「はい」「いいえ」ボタン表示
- 「はい」選択→アイテム消費+ライフ回復

---

## 実装順序

1. **バックエンドDTO作成**（3ファイル新規）
2. **UserItemRepository拡張**
3. **LifeService拡張**
4. **LifeController拡張**
5. **Flutterのlife_api_service拡張**
6. **home_screenに+ボタンとダイアログ実装**

---

## 検証方法

1. ライフを0にした状態でホーム画面を開く
2. ライフ表示の右に緑の+ボタンが表示されることを確認
3. +ボタンをタップしてダイアログが表示されることを確認
4. アイテム名・説明・所持数が正しく表示されることを確認
5. 「はい」を選択してライフが回復することを確認
6. アイテム使用後、所持数が1減っていることを確認
7. ライフが1以上の状態では+ボタンが非表示になることを確認
