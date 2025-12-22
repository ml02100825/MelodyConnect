# MelodyConnect 対戦機能 修正プラン

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
