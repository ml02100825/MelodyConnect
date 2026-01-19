# MelodyConnect 対戦機能 修正プラ

---

## Phase 5: スタミナ（life）機能の実装

### 概要

ランクマッチの連続プレイを制限するため、life（スタミナ）の消費・回復システムを追加する。

---

### 1. 追加/変更するカラム

| カラム名                 | 型        | 説明                                 | デフォルト                              |
| ------------------------ | --------- | ------------------------------------ | --------------------------------------- |
| `life`                   | INT       | 現在の life 残数（既存）             | 5                                       |
| `life_last_recovered_at` | TIMESTAMP | 最後に life 回復計算を行った基準時刻 | NULL → 初回アクセス時に現在時刻をセット |
| `subscribe_flag`         | BOOLEAN   | サブスク判定（既存）                 | false                                   |

**備考:**

- `life` はすでに `User.java` に存在（デフォルト 5）
- `life_last_recovered_at` を新規追加

---

### 2. life 上限の定義

| ユーザー種別                               | 上限 |
| ------------------------------------------ | ---- |
| 通常ユーザー (`subscribe_flag = false`)    | 5    |
| サブスクユーザー (`subscribe_flag = true`) | 10   |

---

### 3. 回復計算の式

```
経過時間 = 現在時刻 - life_last_recovered_at
回復数 = floor(経過時間 / 10分)
新life = min(現在life + 回復数, 上限)
新life_last_recovered_at = life_last_recovered_at + (回復数 * 10分)
```

**ポイント:**

- **Lazy 回復方式**: life を参照/消費するタイミングで回復計算を実行
- 回復計算後、`life_last_recovered_at` は「最後に回復が発生した時刻」に更新（現在時刻ではなく）
- 次回回復までの残り時間 = `10分 - (現在時刻 - life_last_recovered_at)`

---

### 4. 消費処理の原子性担保

**方法: 条件付き UPDATE（楽観的ロックに近いアプローチ）**

```sql
UPDATE users
SET life = life - 1,
    life_last_recovered_at = :newRecoveredAt
WHERE user_id = :userId
  AND life >= 1
  AND delete_flag = false
```

**利点:**

- 単一 SQL で原子的に消費
- `life >= 1` の条件で二重消費やマイナスを防止
- 更新行数が 0 の場合 = life 不足 → エラー返却

**代替案（より厳密な場合）:**

- `@Lock(LockModeType.PESSIMISTIC_WRITE)` による行ロック
- 本プロジェクトでは条件付き UPDATE で十分と判断

---

### 5. 影響範囲

#### バックエンド

| ファイル                             | 変更内容                                         |
| ------------------------------------ | ------------------------------------------------ |
| `entity/User.java`                   | `lifeLastRecoveredAt` カラム追加、getter/setter  |
| `repository/UserRepository.java`     | 条件付き UPDATE メソッド追加                     |
| `service/LifeService.java`           | **新規作成** - life 回復計算、消費処理、状態取得 |
| `controller/LifeController.java`     | **新規作成** - REST API `/api/life`              |
| `service/MatchingService.java`       | `joinQueue()` で life 消費処理を呼び出し         |
| `controller/MatchingController.java` | life 不足時のエラーレスポンス追加                |
| `dto/LifeStatusResponse.java`        | **新規作成** - life 状態レスポンス DTO           |

#### フロントエンド

| ファイル                                    | 変更内容                                       |
| ------------------------------------------- | ---------------------------------------------- |
| `services/life_api_service.dart`            | **新規作成** - life 状態取得 API クライアント  |
| `screens/home_screen.dart`                  | life リアルタイム表示（タイマー+復帰時再取得） |
| `screens/battle_mode_selection_screen.dart` | life 表示 UI 追加、0 時の開始不可処理          |
| `screens/matching_screen.dart`              | life 不足エラーハンドリング                    |

---

### 6. API エンドポイント設計

#### GET `/api/life`

life 状態を取得（回復計算込み）

**レスポンス:**

```json
{
  "currentLife": 3,
  "maxLife": 5,
  "nextRecoveryInSeconds": 420,
  "isSubscriber": false
}
```

#### 既存 WebSocket `/app/matching/join`

マッチング参加時に life 消費を行う

**エラーレスポンス（life 不足時）:**

```json
{
  "status": "error",
  "code": "INSUFFICIENT_LIFE",
  "message": "ライフが不足しています",
  "currentLife": 0,
  "nextRecoveryInSeconds": 180
}
```

---

### 7. サブスク状態変更時の処理

サブスク解約時（上限 10 → 5）に `life > 5` の場合：

```java
if (!user.isSubscribeFlag() && user.getLife() > 5) {
    user.setLife(5);
}
```

**実装箇所:** サブスク状態変更処理（既存の場所があれば追加、なければ別途検討）

---

### 8. タスク分解

#### Phase 5-1: バックエンド基盤

- [x] Task 5-1-1: `User.java` に `lifeLastRecoveredAt` カラム追加
- [x] Task 5-1-2: `LifeStatusResponse.java` DTO 作成
- [x] Task 5-1-3: `UserRepository.java` に条件付き UPDATE メソッド追加
- [x] Task 5-1-4: `LifeService.java` 作成（回復計算、消費処理、状態取得）
- [x] Task 5-1-5: `LifeController.java` 作成（GET `/api/life`）

#### Phase 5-2: マッチング統合

- [x] Task 5-2-1: `MatchingService.joinQueue()` に life 消費処理統合
- [x] Task 5-2-2: `MatchingController.joinMatching()` に life 不足エラー追加

#### Phase 5-3: フロントエンド

- [x] Task 5-3-1: `life_api_service.dart` 作成
- [x] Task 5-3-2: `battle_mode_selection_screen.dart` に life 表示追加
- [x] Task 5-3-3: life 不足時の UI 制御（ボタン無効化/メッセージ表示）
- [x] Task 5-3-4: `matching_screen.dart` に life 不足エラーハンドリング追加
- [x] Task 5-3-5: `home_screen.dart` の life 表示をリアルタイム更新対応

#### Phase 5-4: テスト・検証

- [ ] Task 5-4-1: 単体テスト（回復計算、消費処理）
- [ ] Task 5-4-2: 統合テスト（マッチング開始フロー）
- [ ] Task 5-4-3: 同時実行テスト（二重消費防止の確認）

---

### 9. Done 条件

1. **通常ユーザーの life 上限が 5、サブスクユーザーは 10**
   - `subscribe_flag` に応じて正しい上限が返される
2. **ランクマッチ開始時のみ life が 1 消費される**
   - カジュアル/ルーム/CPU/学習モードでは消費しない
3. **10 分経過で 1 回復、上限で停止**
   - 回復計算が正しく動作する
4. **life=0 のときランクマッチ開始不可**
   - サーバーでエラー返却
   - UI でボタン無効または説明表示
5. **同時リクエストで二重消費しない**
   - 条件付き UPDATE により原子的に処理
6. **サブスク解約時に life 上限が 5 に丸められる**
   - `life > 5` の場合は 5 に調整

---

### 10. HomeScreen life リアルタイム更新

#### 現状

`home_screen.dart:154-166` で固定の音符アイコン 5 個を表示:

```dart
Row(
  children: List.generate(5, (index) {
    return Icon(Icons.music_note, color: Colors.blue[600], size: 20);
  }),
)
```

#### 更新方式: クライアント側タイマー + 画面復帰時再取得

**方針:**

- サーバーから取得した `nextRecoveryInSeconds` を使い、クライアント側でカウントダウン
- 回復タイミングで `currentLife` を +1（上限まで）
- 画面復帰時（`didChangeAppLifecycleState`）やナビゲーション復帰時に再取得
- 過剰な API コールを避ける（ポーリングは不採用）

#### 実装詳細

**1. State 変数追加:**

```dart
int _currentLife = 5;
int _maxLife = 5;
int _nextRecoveryInSeconds = 0;
Timer? _recoveryTimer;
```

**2. ライフサイクル管理:**

```dart
class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchLifeStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _recoveryTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _fetchLifeStatus(); // バックグラウンドから戻ったら再取得
    }
  }
}
```

**3. クライアント側タイマー:**

```dart
void _startRecoveryTimer() {
  _recoveryTimer?.cancel();
  if (_currentLife >= _maxLife || _nextRecoveryInSeconds <= 0) return;

  _recoveryTimer = Timer.periodic(Duration(seconds: 1), (timer) {
    setState(() {
      _nextRecoveryInSeconds--;
      if (_nextRecoveryInSeconds <= 0 && _currentLife < _maxLife) {
        _currentLife++;
        _nextRecoveryInSeconds = 600; // 10分
        if (_currentLife >= _maxLife) {
          timer.cancel();
        }
      }
    });
  });
}
```

**4. UI 更新（AppBar 内）:**

```dart
Row(
  children: [
    // life表示（例: 3/5）
    ...List.generate(_maxLife, (index) {
      final isFilled = index < _currentLife;
      return Icon(
        Icons.music_note,
        color: isFilled ? Colors.blue[600] : Colors.grey[300],
        size: 20,
      );
    }),
    const SizedBox(width: 8),
    // 次回回復までの時間（life < maxのとき）
    if (_currentLife < _maxLife)
      Text(
        _formatRecoveryTime(_nextRecoveryInSeconds),
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
  ],
)
```

**5. 他画面からの復帰時:**

```dart
// Navigator.pop後に再取得
Navigator.push(...).then((_) => _fetchLifeStatus());
```

#### 表示仕様

| 状態           | 表示例                           |
| -------------- | -------------------------------- |
| life 満タン    | ♪♪♪♪♪ (青 5 個)                  |
| life=3/5       | ♪♪♪♫♫ (青 3 個+灰 2 個) + "7:30" |
| life=0/5       | ♫♫♫♫♫ (灰 5 個) + "9:45"         |
| サブスク満タン | ♪♪♪♪♪♪♪♪♪♪ (青 10 個)            |

#### Done 条件（Task 5-3-5）

1. HomeScreen 表示時に API から life 状態を取得
2. 現在 life/上限に応じて音符アイコンの色を切り替え
3. life < 上限のとき、次回回復までの残り時間を表示
4. クライアント側タイマーで残り時間をカウントダウン
5. 回復タイミングで life 表示が+1 される
6. バックグラウンド復帰時に再取得して同期
7. 対戦画面から戻った際にも再取得

---

### 11. リスク・注意点

| リスク                            | 対策                                                     |
| --------------------------------- | -------------------------------------------------------- |
| 時刻ずれ（サーバー/クライアント） | 回復計算はすべてサーバー側で実施、クライアントは表示のみ |
| 同時リクエストによる二重消費      | 条件付き UPDATE で原子的に処理（WHERE life >= 1）        |
| life_last_recovered_at が NULL    | 初回アクセス時に現在時刻をセット（NULL チェック実装）    |
| トランザクション境界              | life 消費とキュー参加を同一トランザクションで管理        |
| WebSocket 切断時の rollback       | キュー参加失敗時は life 返却を検討（Phase 2 で対応可）   |

---

## Phase 4: タイマー・勝敗判定・ナビゲーション修正

### 1) 更新すると制限時間がリセットされる問題

#### 現象

- 画面更新（リビルド/再取得/再表示）でタイマーが初期値(90 秒)に戻る

#### 原因分析

| 箇所      | 現状                                                          | 問題点                           |
| --------- | ------------------------------------------------------------- | -------------------------------- |
| Server    | `BattleStateService.roundStartTime` に `Instant.now()` を保持 | クライアントに送信していない     |
| Client    | 問題受信時に `_remainingSeconds = 90` で初期化                | サーバー時刻と非同期             |
| WebSocket | `questionMessage` に `roundStartTimestamp` が含まれない       | 再接続時に残り時間を計算できない |

#### タスク

- [x] Task 1-1: QuestionResponse に `roundStartTimestamp` を追加
- [x] Task 1-2: Controller で question 送信時に timestamp を含める
- [x] Task 1-3: Flutter の BattleQuestion モデルに roundStartTimestamp 追加
- [x] Task 1-4: \_handleQuestionMessage で残り時間を計算して設定

---

### 2) 10 問終了時の勝敗判定

#### 仕様

- 10 問終わっても両者が 3 本取れていない場合:
  - 取得本数が多い方が勝ち
  - 同数なら引き分け

#### 現状

サーバー側は既に正しく実装済み（BattleStateService.getWinnerId()）

#### タスク

- [x] Task 2-1: 実装確認・必要なら修正

---

### 3) BottomNav case2 の遷移先変更

#### 現状

case 2 → LearningScreen (プレースホルダー)

#### タスク

- [x] Task 3-1: case 2 を QuizSelectionScreen に変更
