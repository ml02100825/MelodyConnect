# MelodyConnect 対戦機能 修正プラン

---

## Phase 5: スタミナ（life）機能の実装

### 概要
ランクマッチの連続プレイを制限するため、life（スタミナ）の消費・回復システムを追加する。

---

### 1. 追加/変更するカラム

| カラム名 | 型 | 説明 | デフォルト |
|---------|-----|------|-----------|
| `life` | INT | 現在のlife残数（既存） | 5 |
| `life_last_recovered_at` | TIMESTAMP | 最後にlife回復計算を行った基準時刻 | NULL → 初回アクセス時に現在時刻をセット |
| `subscribe_flag` | BOOLEAN | サブスク判定（既存） | false |

**備考:**
- `life` はすでに `User.java` に存在（デフォルト5）
- `life_last_recovered_at` を新規追加

---

### 2. life上限の定義

| ユーザー種別 | 上限 |
|-------------|------|
| 通常ユーザー (`subscribe_flag = false`) | 5 |
| サブスクユーザー (`subscribe_flag = true`) | 10 |

---

### 3. 回復計算の式

```
経過時間 = 現在時刻 - life_last_recovered_at
回復数 = floor(経過時間 / 10分)
新life = min(現在life + 回復数, 上限)
新life_last_recovered_at = life_last_recovered_at + (回復数 * 10分)
```

**ポイント:**
- **Lazy回復方式**: lifeを参照/消費するタイミングで回復計算を実行
- 回復計算後、`life_last_recovered_at` は「最後に回復が発生した時刻」に更新（現在時刻ではなく）
- 次回回復までの残り時間 = `10分 - (現在時刻 - life_last_recovered_at)`

---

### 4. 消費処理の原子性担保

**方法: 条件付きUPDATE（楽観的ロックに近いアプローチ）**

```sql
UPDATE users
SET life = life - 1,
    life_last_recovered_at = :newRecoveredAt
WHERE user_id = :userId
  AND life >= 1
  AND delete_flag = false
```

**利点:**
- 単一SQLで原子的に消費
- `life >= 1` の条件で二重消費やマイナスを防止
- 更新行数が0の場合 = life不足 → エラー返却

**代替案（より厳密な場合）:**
- `@Lock(LockModeType.PESSIMISTIC_WRITE)` による行ロック
- 本プロジェクトでは条件付きUPDATEで十分と判断

---

### 5. 影響範囲

#### バックエンド

| ファイル | 変更内容 |
|---------|---------|
| `entity/User.java` | `lifeLastRecoveredAt` カラム追加、getter/setter |
| `repository/UserRepository.java` | 条件付きUPDATEメソッド追加 |
| `service/LifeService.java` | **新規作成** - life回復計算、消費処理、状態取得 |
| `controller/LifeController.java` | **新規作成** - REST API `/api/life` |
| `service/MatchingService.java` | `joinQueue()` でlife消費処理を呼び出し |
| `controller/MatchingController.java` | life不足時のエラーレスポンス追加 |
| `dto/LifeStatusResponse.java` | **新規作成** - life状態レスポンスDTO |

#### フロントエンド

| ファイル | 変更内容 |
|---------|---------|
| `services/life_api_service.dart` | **新規作成** - life状態取得APIクライアント |
| `screens/battle_mode_selection_screen.dart` | life表示UI追加、0時の開始不可処理 |
| `screens/matching_screen.dart` | life不足エラーハンドリング |

---

### 6. APIエンドポイント設計

#### GET `/api/life`
life状態を取得（回復計算込み）

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
マッチング参加時にlife消費を行う

**エラーレスポンス（life不足時）:**
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
- [ ] Task 5-1-1: `User.java` に `lifeLastRecoveredAt` カラム追加
- [ ] Task 5-1-2: `LifeStatusResponse.java` DTO作成
- [ ] Task 5-1-3: `UserRepository.java` に条件付きUPDATEメソッド追加
- [ ] Task 5-1-4: `LifeService.java` 作成（回復計算、消費処理、状態取得）
- [ ] Task 5-1-5: `LifeController.java` 作成（GET `/api/life`）

#### Phase 5-2: マッチング統合
- [ ] Task 5-2-1: `MatchingService.joinQueue()` にlife消費処理統合
- [ ] Task 5-2-2: `MatchingController.joinMatching()` にlife不足エラー追加

#### Phase 5-3: フロントエンド
- [ ] Task 5-3-1: `life_api_service.dart` 作成
- [ ] Task 5-3-2: `battle_mode_selection_screen.dart` にlife表示追加
- [ ] Task 5-3-3: life不足時のUI制御（ボタン無効化/メッセージ表示）
- [ ] Task 5-3-4: `matching_screen.dart` にlife不足エラーハンドリング追加

#### Phase 5-4: テスト・検証
- [ ] Task 5-4-1: 単体テスト（回復計算、消費処理）
- [ ] Task 5-4-2: 統合テスト（マッチング開始フロー）
- [ ] Task 5-4-3: 同時実行テスト（二重消費防止の確認）

---

### 9. Done条件

1. **通常ユーザーのlife上限が5、サブスクユーザーは10**
   - `subscribe_flag` に応じて正しい上限が返される
2. **ランクマッチ開始時のみlifeが1消費される**
   - カジュアル/ルーム/CPU/学習モードでは消費しない
3. **10分経過で1回復、上限で停止**
   - 回復計算が正しく動作する
4. **life=0のときランクマッチ開始不可**
   - サーバーでエラー返却
   - UIでボタン無効または説明表示
5. **同時リクエストで二重消費しない**
   - 条件付きUPDATEにより原子的に処理
6. **サブスク解約時にlife上限が5に丸められる**
   - `life > 5` の場合は5に調整

---

### 10. リスク・注意点

| リスク | 対策 |
|--------|------|
| 時刻ずれ（サーバー/クライアント） | 回復計算はすべてサーバー側で実施、クライアントは表示のみ |
| 同時リクエストによる二重消費 | 条件付きUPDATEで原子的に処理（WHERE life >= 1） |
| life_last_recovered_atがNULL | 初回アクセス時に現在時刻をセット（NULLチェック実装） |
| トランザクション境界 | life消費とキュー参加を同一トランザクションで管理 |
| WebSocket切断時のrollback | キュー参加失敗時はlife返却を検討（Phase 2で対応可） |

---

## Phase 4: タイマー・勝敗判定・ナビゲーション修正

### 1) 更新すると制限時間がリセットされる問題

#### 現象
- 画面更新（リビルド/再取得/再表示）でタイマーが初期値(90秒)に戻る

#### 原因分析
| 箇所 | 現状 | 問題点 |
|------|------|--------|
| Server | `BattleStateService.roundStartTime` に `Instant.now()` を保持 | クライアントに送信していない |
| Client | 問題受信時に `_remainingSeconds = 90` で初期化 | サーバー時刻と非同期 |
| WebSocket | `questionMessage` に `roundStartTimestamp` が含まれない | 再接続時に残り時間を計算できない |

#### タスク
- [x] Task 1-1: QuestionResponse に `roundStartTimestamp` を追加
- [x] Task 1-2: Controller で question 送信時に timestamp を含める
- [x] Task 1-3: Flutter の BattleQuestion モデルに roundStartTimestamp 追加
- [x] Task 1-4: _handleQuestionMessage で残り時間を計算して設定

---

### 2) 10問終了時の勝敗判定

#### 仕様
- 10問終わっても両者が3本取れていない場合:
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
