# バトル終了後も「バトル中」と表示される不具合 - 原因特定と修正計画

## Context

ルームマッチの招待画面（フレンド一覧）で、バトルが終了しているユーザーが「バトル中」と表示され続ける不具合。

## 原因特定

### 根本原因: WebSocket切断ハンドラーがランクマッチのバトル状態をクリーンアップしない

[RoomWebSocketEventListener.java:232-239](api/src/main/java/com/example/api/listener/RoomWebSocketEventListener.java#L232-L239) の切断処理:

```java
Optional<Room> activeRoom = roomService.getActiveRoom(userId);
if (activeRoom.isEmpty()) {
    logger.debug("切断ユーザーにはアクティブな部屋がありません: userId={}", userId);
    return;  // ← ランクマッチの場合、Roomが存在しないためここで早期リターン！
}
```

**ランクマッチはRoom（部屋）エンティティを使わない。** そのため、ランクマッチ中のユーザーがWebSocket切断した場合:
1. `getActiveRoom(userId)` が空を返す
2. 切断ハンドラーが早期リターン
3. `BattleStateService.activeBattles` マップ内のバトル状態がクリーンアップされない
4. ステータスが `IN_PROGRESS` または `WAITING_FOR_PLAYERS` のまま残る

### ステータス判定の流れ

[RoomController.java:343-367](api/src/main/java/com/example/api/controller/RoomController.java#L343-L367) の `getUserStatus()`:
1. オフラインチェック → パス（再接続済み）
2. `getActiveRoom()` → 空（ランクマッチにRoomはない）
3. `matchingQueueService.isInQueue()` → false
4. **`battleService.isUserInRankBattle()` → `true`** ← ここで「バトル中」と判定

[BattleStateService.java:334-351](api/src/main/java/com/example/api/service/BattleStateService.java#L334-L351):
```java
// status != FINISHED のバトル状態が残っていれば true を返す
if (state.isParticipant(userId) && !state.isRoomMatch()
        && state.getStatus() != Status.FINISHED) {
    return true;
}
```

### 発生シナリオ

**シナリオ1: ランクマッチ中にWebSocket切断**
1. ユーザーA・Bがランクマッチ中（`activeBattles` にバトル状態あり、status=`IN_PROGRESS`）
2. ユーザーAが切断（アプリ閉じる、ネットワーク不安定等）
3. 切断ハンドラーが発火 → `getActiveRoom(A)` が空 → 早期リターン（**バトル状態未クリーンアップ**）
4. ユーザーAから見ればバトルは終了（アプリを閉じた/再起動した）
5. 残ったユーザーBは回答タイムアウトにより試合が進行（各ラウンド90秒 × 最大10ラウンド = 最大15分+）
6. その間、ユーザーAはフレンドの招待画面で「バトル中」と表示される
7. 全ラウンドがタイムアウト処理された後ようやく`finalizeBattle()`→`removeBattle()`でクリーンアップされる

**シナリオ2: バトル開始前の両者切断（永久リーク）**
1. マッチング成立 → バトル画面遷移 → `/api/battle/start/{matchId}` 呼出で`initializeBattle()` → status=`WAITING_FOR_PLAYERS`
2. 両ユーザーが`/app/battle/ready`を送信する前に切断
3. バトル状態が`WAITING_FOR_PLAYERS`のまま`activeBattles`に永久に残る
4. **タイムアウト機構は`IN_PROGRESS`のみ対象** → `WAITING_FOR_PLAYERS`は掃除されない
5. 対象ユーザーは永久に「バトル中」と表示される

## 修正計画

### 1. WebSocket切断ハンドラーにランクマッチのクリーンアップを追加
**ファイル:** [RoomWebSocketEventListener.java](api/src/main/java/com/example/api/listener/RoomWebSocketEventListener.java)

`handleWebSocketDisconnectListener()` 内で、`getActiveRoom()` が空の場合でもランクマッチのバトル状態をチェック・クリーンアップする。

```java
// 既存コードの早期リターン前に追加:
// ランクマッチ中のバトル状態をクリーンアップ
handleRankBattleDisconnect(userId);
```

### 2. ランクマッチ用の切断処理メソッドを追加
**ファイル:** [RoomWebSocketEventListener.java](api/src/main/java/com/example/api/listener/RoomWebSocketEventListener.java)

```java
private void handleRankBattleDisconnect(Long userId) {
    // activeBattlesからユーザーが参加中のランクマッチを検索
    // 見つかったらhandleDisconnection()で切断処理
}
```

### 3. BattleStateServiceにユーザーIDからバトルを検索するメソッドを追加
**ファイル:** [BattleStateService.java](api/src/main/java/com/example/api/service/BattleStateService.java)

```java
public String getMatchUuidByUserId(Long userId) {
    // activeBattlesから、参加者にuserIdを含むバトルのmatchUuidを返す
    // (ランクマッチのみ、FINISHED以外)
}
```

### 4. 古いバトル状態のクリーンアップ用スケジュールタスクを追加
**ファイル:** [BattleStateService.java](api/src/main/java/com/example/api/service/BattleStateService.java) または [BattleController.java](api/src/main/java/com/example/api/controller/BattleController.java)

`WAITING_FOR_PLAYERS` のまま一定時間（例: 5分）経過したバトル状態を自動削除する安全策。

### 5. デバッグログの削除
**ファイル:** [BattleStateService.java:338-343](api/src/main/java/com/example/api/service/BattleStateService.java#L338-L343)

調査用に追加されたデバッグログを削除する。

## 修正対象ファイル

1. [RoomWebSocketEventListener.java](api/src/main/java/com/example/api/listener/RoomWebSocketEventListener.java) - 切断ハンドラーの修正
2. [BattleStateService.java](api/src/main/java/com/example/api/service/BattleStateService.java) - ユーザーID検索メソッド追加 + デバッグログ削除
3. [BattleController.java](api/src/main/java/com/example/api/controller/BattleController.java) - WAITING_FOR_PLAYERSクリーンアップタスク追加（任意）

## 検証方法

1. ランクマッチ中にWebSocket切断を模擬 → バトル状態がクリーンアップされることを確認
2. 切断後、フレンド招待画面で「バトル中」ではなく「オフライン」または「オンライン」と表示されることを確認
3. 既存のルームマッチ切断処理が引き続き正常に動作することを確認
