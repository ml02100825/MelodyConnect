# battle_screen.dart 4つの問題修正計画

## Context

battle_screen.dart に以下の4つの問題が報告されている:
1. 問題一覧で「問題文を取得できません」エラーが表示される
2. 降参すると解いた問題しか表示されない（全問題を表示すべき）
3. 一部のスマホで画面下部が押せない・アイコンサイズがおかしい
4. タイマーが常にカウントされている（問題表示中のみにすべき）

---

## Issue 1 & 2: 問題一覧のquestionText欠落 + 降参時に全問題が表示されない

**原因:** [BattleService.java:671-755](api/src/main/java/com/example/api/service/BattleService.java#L671-L755) の `createRoundResultResponses` メソッドに2つのバグがある:

- **通常パス (682-714行):** `r.setQuestionText()` が呼ばれておらず、常にnull → フロントで「問題文を取得できません」
- **降参時:** `state.getRoundResults()` が空でない場合（=1問以上プレイ済み）、通常パスに入り714行でreturnしてしまい、降参フォールバック(717-751行)に到達しない → 解いた問題しか返らない

**修正内容:** `createRoundResultResponses` を以下のように変更:

```java
// 修正後の構造:
private List<RoundResultResponse> createRoundResultResponses(...) {
    Map<Integer, Question> questionMap = ...;
    List<RoundResultResponse> responses = new ArrayList<>();

    // ① 既存ラウンドがある場合は通常通り（+ questionText追加）
    if (!state.getRoundResults().isEmpty()) {
        Set<Integer> playedQuestionIds = new HashSet<>();
        for (BattleStateService.RoundResult rr : state.getRoundResults()) {
            Question q = questionMap.get(rr.getQuestionId());
            // ... 既存コード ...
            r.setQuestionText(q != null ? q.getText() : null);  // ★追加
            playedQuestionIds.add(rr.getQuestionId());
            responses.add(r);
        }

        // ② 降参/切断の場合、未プレイの問題も追加
        if (outcomeReason == Result.OutcomeReason.surrender ||
            outcomeReason == Result.OutcomeReason.disconnect) {
            String p1Msg = buildFallbackAnswer(outcomeReason, state.getPlayer1Id(), loserId);
            String p2Msg = buildFallbackAnswer(outcomeReason, state.getPlayer2Id(), loserId);
            int round = responses.size() + 1;
            for (Question q : state.getQuestions()) {
                if (playedQuestionIds.contains(q.getQuestionId())) continue;
                // フォールバックのRoundResultResponse作成（既存717-751と同じ）
                ...
            }
        }
        return responses;
    }

    // ③ 既存ラウンドが無い場合の降参/切断フォールバック（既存コードそのまま）
    ...
}
```

**対象ファイル:** [BattleService.java](api/src/main/java/com/example/api/service/BattleService.java) - `createRoundResultResponses` メソッド (671-755行)

---

## Issue 3: 一部スマホで画面下部が押せない・アイコンサイズ異常

**原因:**
- `_buildRoundResultContent()` と `_buildMatchFinishedContent()` が `SingleChildScrollView` で囲まれていない → 小さい画面でオーバーフロー
- アイコン(80,100)、フォントサイズ(28,36,40)が固定値でスケーリングされていない

**修正内容:**

### 3a: SingleChildScrollViewで囲む

`_buildRoundResultContent()` (1380行) と `_buildMatchFinishedContent()` (1548行) を `LayoutBuilder` + `SingleChildScrollView` + `ConstrainedBox` + `Center` で囲む:

```dart
return LayoutBuilder(
  builder: (context, constraints) {
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: Center(
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.of(context).padding.bottom),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [ ... 既存の中身 ... ],
            ),
          ),
        ),
      ),
    );
  },
);
```

### 3b: レスポンシブスケーリング

各メソッドの先頭でスケールファクターを算出:
```dart
final screenHeight = MediaQuery.of(context).size.height;
final scaleFactor = screenHeight < 700 ? 0.8 : 1.0;
```

適用箇所:
- `_buildRoundResultContent()`: アイコン80→`80*scale`, フォント28→`28*scale`, 22→`22*scale`, 24→`24*scale`
- `_buildMatchFinishedContent()`: アイコン100→`100*scale`, フォント36→`36*scale`, 40→`40*scale`, 28→`28*scale`

**対象ファイル:** [battle_screen.dart](web/lib/screens/battle_screen.dart) - `_buildRoundResultContent` (1370-1538行), `_buildMatchFinishedContent` (1541-1745行)

---

## Issue 4: タイマーが常にバックグラウンドで動いている

**原因:** `Timer.periodic` が回答送信後もキャンセルされず、バックグラウンドで毎秒コールバックが走り続ける。
タイマーがキャンセルされるのは `_handleRoundResult` (449行), `_handleBattleResult` (477行), `_handleOpponentSurrendered` (488行) のみで、`_submitAnswer()` ではキャンセルされていない。

**修正内容:** 回答送信時にタイマーを完全停止し、次の問題受信時にのみ再開する:

### 4a: `_submitAnswer()` でタイマーをキャンセル

```dart
void _submitAnswer() {
    // ... 既存コード ...
    setState(() {
      _status = BattleStatus.submitting;
    });

    _roundTimer?.cancel();  // ★追加: 回答送信時にタイマー完全停止

    _stompClient?.send(
      destination: '/app/battle/answer',
      // ...
    );
}
```

### 4b: `_onTimeout()` でもタイマーをキャンセル（安全策）

```dart
void _onTimeout() {
    _roundTimer?.cancel();  // ★追加: タイムアウト時にも確実にキャンセル
    setState(() {
      _isTimedOut = true;
    });
    // ... 既存コード ...
}
```

### タイマーのライフサイクル（修正後）

| イベント | タイマー動作 |
|---------|------------|
| 問題受信 (`_handleQuestionMessage`) | `_startRoundTimer()` で新規開始 |
| 回答送信 (`_submitAnswer`) | `_roundTimer?.cancel()` で停止 |
| タイムアウト (`_onTimeout`) | `_roundTimer?.cancel()` で停止 |
| ラウンド結果受信 (`_handleRoundResult`) | `_roundTimer?.cancel()` で停止（既存） |
| 試合結果受信 (`_handleBattleResult`) | `_roundTimer?.cancel()` で停止（既存） |
| 降参 (`_surrender`, `_handleOpponentSurrendered`) | `_roundTimer?.cancel()` で停止（既存） |

### 4c: 問題受信時にフルの制限時間からタイマー開始

`_handleQuestionMessage()` (417-420行) で `calculateRemainingSeconds()` を使うと、サーバーの `roundStartTimestamp`（答え合わせ時点で設定される）から経過時間が引かれ、問題表示前に時間が消費される。

```dart
// 修正前 (417-420行):
_remainingSeconds = _currentQuestion?.calculateRemainingSeconds()
    ?? _battleInfo?.roundTimeLimitSeconds
    ?? 90;

// 修正後: 問題表示時にフルの制限時間から開始
_remainingSeconds = _battleInfo?.roundTimeLimitSeconds ?? 90;
```

**対象ファイル:** [battle_screen.dart](web/lib/screens/battle_screen.dart) - `_handleQuestionMessage` (417-420行)

### 4d: ラウンド結果画面・試合終了画面でタイマーを非表示にする

`_buildBattleContent()` (800行付近) で `_buildTimer()` が常に表示されているため、ラウンド結果画面でもタイマーバーが見えてカウントダウンが進む。

```dart
// 修正前 (807行):
_buildTimer(),

// 修正後:
if (_status != BattleStatus.roundResult && _status != BattleStatus.matchFinished)
  _buildTimer(),
```

これにより、タイマーは問題表示中（answering/submitting/waitingOpponent）のみ表示され、ラウンド結果画面や試合終了画面では完全に非表示になる。

**対象ファイル:** [battle_screen.dart](web/lib/screens/battle_screen.dart) - `_submitAnswer` (568行付近), `_onTimeout` (544行付近), `_buildBattleContent` (807行付近)

---

## 実装順序

1. **Issue 1 + 2 (バックエンド)** - `createRoundResultResponses` を一括修正
2. **Issue 4 (フロントエンド・タイマー)** - 小さい変更
3. **Issue 3 (フロントエンド・レイアウト)** - 最も行数が多い変更

## 検証方法

| Issue | テスト方法 |
|-------|-----------|
| 1 | 通常対戦を最後までプレイ →「問題一覧を見る」で全問題にquestionTextが表示されるか確認 |
| 2 | 1-2問解いてから降参 →「問題一覧を見る」でプレイ済み+未プレイの全問題が表示されるか確認 |
| 3 | 小画面端末(iPhone SE等)でラウンド結果/試合結果画面をスクロールでき、ボタンが押せるか確認 |
| 4 | 問題に回答後、タイマーが停止するか確認。次の問題受信時にリセットされるか確認 |
