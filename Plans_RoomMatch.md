# ルームマッチ機能 実装計画（PLAN）

## 1. 調査結果サマリー

### 既存実装の状況

| コンポーネント | 状況 | ファイルパス |
|--------------|------|-------------|
| Room エンティティ | ✅ 存在 | `api/.../entity/Room.java` |
| RoomRepository | ❌ 未実装 | - |
| Friend エンティティ | ✅ 存在 | `api/.../entity/Friend.java` |
| FriendRepository | ❌ 未実装 | - |
| Result エンティティ | ✅ matchType 対応済み | `api/.../entity/Result.java` |
| BattleService | ✅ 完成 | `api/.../service/BattleService.java` |
| BattleStateService | ✅ 完成（先取数固定） | `api/.../service/BattleStateService.java` |
| MatchingQueueService | ✅ 完成（`isInQueue`メソッドあり） | `api/.../service/MatchingQueueService.java` |
| battle_mode_selection_screen | ✅ 存在（Room Match は「準備中」） | `web/.../battle_mode_selection_screen.dart` |

### 既存の対戦フロー（ランクマッチ）
```
1. MatchingController.joinMatching() → キュー参加
2. performMatching() [1秒ごと] → マッチング成立
3. BattleController.startBattle() → 対戦開始
4. BattleController.submitAnswer() → 回答処理
5. BattleService.finalizeBattle() → 結果保存（Result テーブル）
```

### 既存のRoom.status定義
```java
enum Status { WAITING, READY, PLAYING, FINISHED, CANCELED }
```

### 既存のRoom.match_type
- Integer型、デフォルト値 3
- **ルームマッチでは「先取数」（5/7/9）として使用**

---

## 2. タスク分解

### Phase 1: バックエンド基盤（Repository/Service/Controller）

#### 2.1 Repository作成
- [ ] `RoomRepository.java` - Room CRUD
- [ ] `FriendRepository.java` - フレンド一覧/検索

#### 2.2 招待管理エンティティ（新規）
- [ ] `RoomInvitation.java` - 招待の永続化
  - room_id, inviter_id, invitee_id, status (pending/accepted/rejected/expired), created_at

#### 2.3 Service作成
- [ ] `RoomService.java`
  - createRoom(hostId) - 部屋作成
  - inviteFriend(roomId, friendId) - 招待送信
  - joinRoom(roomId, guestId) - 部屋参加
  - setReady(roomId, userId) - 準備完了
  - startMatch(roomId) - 対戦開始
  - leaveRoom(roomId, userId) - 退出

- [ ] `RoomInvitationService.java`
  - createInvitation(roomId, inviterId, inviteeId)
  - getPendingInvitations(userId) - 受信招待一覧
  - acceptInvitation(invitationId)
  - rejectInvitation(invitationId)
  - canReceiveInvitation(userId) - ランク中でないかチェック

#### 2.4 Controller作成
- [ ] `RoomController.java` (REST + WebSocket)

### Phase 2: 対戦ロジック拡張

#### 2.5 BattleStateService拡張
- [ ] winsToVictory を動的設定可能に（コンストラクタ引数 or setterで対応）
- [ ] maxRounds も先取数に応じて調整（先取数 + 5）

#### 2.6 BattleService拡張
- [ ] ルームマッチ用対戦初期化メソッド
  - Result.matchType = room
  - updownRate = 0（レート変動なし）
- [ ] 問題取得数 = 先取数 + 5

### Phase 3: フロントエンド

#### 2.7 ルームマッチ画面
- [ ] `room_match_screen.dart` - ルームロビー画面
  - 部屋作成/待機
  - フレンド招待ダイアログ
  - ゲスト参加表示
  - 準備完了/開始ボタン
  - 先取数/言語/問題形式選択

#### 2.8 招待機能
- [ ] WebSocket で招待通知受信
- [ ] 招待一覧ダイアログ（battle_mode_selection_screen に統合）
- [ ] 招待受理/拒否処理

#### 2.9 既存画面修正
- [ ] `battle_mode_selection_screen.dart` - Room Match 有効化
- [ ] `battle_screen.dart` - 対戦終了後「ルームに戻る」オプション追加

---

## 3. 状態遷移とイベント一覧

### Room.status 遷移図
```
                    ┌─────────────────┐
                    │     (なし)       │
                    └────────┬────────┘
                             │ ホストが部屋作成
                             ▼
                    ┌─────────────────┐
         ┌─────────│    WAITING      │◄─────────┐
         │         └────────┬────────┘          │
         │                  │ ゲスト参加         │ ゲスト退出
         │                  ▼                    │
         │         ┌─────────────────┐          │
         │         │  (ゲスト準備)    │──────────┘
         │         └────────┬────────┘
         │                  │ 両者準備完了
         │                  ▼
         │         ┌─────────────────┐
         │         │     READY       │
         │         └────────┬────────┘
         │                  │ ホストが開始
         │                  ▼
         │         ┌─────────────────┐
         │         │    PLAYING      │
         │         └────────┬────────┘
         │                  │ 対戦終了
         │                  ▼
         │         ┌─────────────────┐
         └────────►│    FINISHED     │──► 再戦可能
                   └────────┬────────┘
                            │ ホスト退出
                            ▼
                   ┌─────────────────┐
                   │    CANCELED     │
                   └─────────────────┘
```

### イベント一覧

| イベント | トリガー | Room変更 | 通知先 |
|---------|---------|----------|--------|
| 部屋作成 | ホスト | status=WAITING | ホスト |
| 招待送信 | ホスト | (なし) | ゲスト(招待対象) |
| 招待受理 | ゲスト | guest_id設定 | ホスト |
| 招待拒否 | ゲスト | (なし) | ホスト |
| ゲスト準備完了 | ゲスト | guest_ready=true | ホスト |
| ホスト準備完了 | ホスト | host_ready=true | ゲスト |
| 対戦開始 | ホスト | status=PLAYING | 両者 |
| 対戦終了 | システム | status=FINISHED | 両者 |
| ゲスト退出 | ゲスト | guest_id=null, guest_ready=false, status=WAITING | ホスト |
| ホスト退出 | ホスト | status=CANCELED | ゲスト |

---

## 4. API/WSエンドポイント設計

### REST API

| Method | Path | 説明 | Request Body | Response |
|--------|------|------|--------------|----------|
| POST | `/api/rooms` | 部屋作成 | `{ matchType: 5, language: "en", problemType: "...", questionFormat: "..." }` | `{ roomId, status, ... }` |
| GET | `/api/rooms/{roomId}` | 部屋情報取得 | - | Room詳細 |
| POST | `/api/rooms/{roomId}/invite` | 招待送信 | `{ friendId }` | `{ invitationId }` |
| GET | `/api/rooms/invitations` | 受信招待一覧 | - | `[ { invitationId, room, inviter, ... } ]` |
| POST | `/api/rooms/invitations/{id}/accept` | 招待受理 | - | `{ roomId }` |
| POST | `/api/rooms/invitations/{id}/reject` | 招待拒否 | - | `{}` |
| DELETE | `/api/rooms/{roomId}/leave` | 退出 | - | `{}` |
| GET | `/api/friends` | フレンド一覧 | - | `[ { userId, username, ... } ]` |

### WebSocket Endpoints

| Destination | 説明 | Payload |
|-------------|------|---------|
| `/app/room/ready` | 準備完了 | `{ roomId, userId }` |
| `/app/room/start` | 対戦開始 | `{ roomId, userId }` |
| `/app/room/leave` | 退出通知 | `{ roomId, userId }` |

### WebSocket Topics (Server → Client)

| Topic | 説明 | Payload例 |
|-------|------|----------|
| `/topic/room/{userId}` | ルーム状態通知 | `{ type: "guest_joined", room: {...} }` |
| `/topic/room-invitation/{userId}` | 招待通知 | `{ type: "invitation", invitation: {...} }` |

---

## 5. 先取数と問題取得数の実装

### 設定値
| 先取数 | 取得問題数 | 最大ラウンド |
|-------|-----------|-------------|
| 5 | 10 | 10 |
| 7 | 12 | 12 |
| 9 | 14 | 14 |

### 実装箇所
1. **Room.match_type**: 先取数（5/7/9）を保存
2. **BattleStateService**:
   - `WINS_TO_VICTORY` を動的に設定（BattleState内で保持）
   - `MAX_ROUNDS` も動的に設定（先取数 + 5）
3. **BattleService.initializeBattle()**:
   - ルームマッチの場合、`room.match_type` から先取数を取得
   - 問題取得数 = 先取数 + 5

### BattleState拡張案
```java
public class BattleState {
    private final int winsToVictory;  // 追加（デフォルト3、ルームマッチでは5/7/9）
    private final int maxRounds;      // 追加（winsToVictory + 5）
    // ...
}
```

---

## 6. 例外・境界ケース

### 6.1 招待関連
| ケース | 処理 |
|-------|------|
| ランクマッチ待機中のユーザーへ招待 | 招待作成するが通知しない（後から確認可能） |
| 対戦中のユーザーへ招待 | 招待作成するが通知しない（後から確認可能） |
| 既に招待済みのユーザーへ再招待 | エラー返却 or 既存招待を返却 |
| 自分自身への招待 | エラー返却 |
| フレンドでないユーザーへの招待 | エラー返却 |
| 招待期限切れ | 24時間で自動期限切れ（status=expired） |

### 6.2 部屋関連
| ケース | 処理 |
|-------|------|
| ゲスト未参加で開始 | エラー返却（開始不可） |
| ゲスト未準備で開始 | エラー返却（開始不可） |
| 既に対戦中の部屋で再開始 | エラー返却 |
| 存在しない部屋へのアクセス | 404エラー |
| 権限のない操作（他人の部屋を開始など） | 403エラー |

### 6.3 対戦中
| ケース | 処理 |
|-------|------|
| ゲスト切断 | 既存のdisconnect処理を再利用（降参扱い or タイムアウト） |
| ホスト切断 | 同上 |
| 二重回答 | 既存の重複チェックで対応 |

### 6.4 同時実行
| ケース | 処理 |
|-------|------|
| 同時に準備完了 | DB/メモリのトランザクションで整合性確保 |
| 招待受理と部屋削除の競合 | 楽観的ロック or 先勝ち |

---

## 7. Done条件

### 必須要件
- [ ] ホストが部屋を作成できる
- [ ] ホストがフレンドを招待できる
- [ ] ゲストが招待一覧から招待を確認できる
- [ ] ゲストが招待を受理/拒否できる
- [ ] ゲストが準備完了を押せる
- [ ] ホストが開始ボタンで対戦を開始できる
- [ ] 対戦進行は既存ランクマッチと同じ動作
- [ ] 結果がResultテーブルに `match_type = room` で保存される
- [ ] 結果保存時、`updownRate = 0`（レート変動なし）
- [ ] 対戦終了後、「ルームに戻る」で部屋に戻れる
- [ ] ゲスト退出後、ホストは別フレンドを再招待できる
- [ ] ホスト退出で部屋が破棄される

### 追加要件
- [ ] 先取数（5/7/9）を選択できる
- [ ] 言語/問題形式を選択できる
- [ ] ランクマッチ中のユーザーには招待通知が届かない

---

## 8. 最低限のテスト項目

### 8.1 単体テスト
- [ ] RoomService.createRoom() - 部屋作成
- [ ] RoomService.joinRoom() - 参加処理
- [ ] RoomService.leaveRoom() - 退出処理（ホスト/ゲスト両パターン）
- [ ] RoomInvitationService.canReceiveInvitation() - ランク中判定

### 8.2 統合テスト
- [ ] 部屋作成 → 招待 → 受理 → 準備 → 開始 → 終了の基本フロー
- [ ] ゲスト退出後の再招待フロー
- [ ] ホスト退出時の部屋破棄確認
- [ ] 先取数5/7/9での問題数確認（10/12/14問）

### 8.3 E2Eテスト（手動）
- [ ] 2端末での実際の対戦フロー
- [ ] WebSocket通知の遅延・順序確認
- [ ] 切断時の挙動確認

---

## 9. リスクと対策

| リスク | 影響 | 対策 |
|-------|------|------|
| BattleStateServiceの変更がランクマッチに影響 | 高 | 既存のテストを事前に確認、ルーム専用の初期化メソッド追加 |
| WebSocket接続の安定性 | 中 | 既存のランクマッチで実績あり、同じ仕組みを再利用 |
| 招待通知の遅延 | 低 | 招待一覧からの確認をフォールバックとして提供 |
| 同時操作による競合 | 低 | synchronized + DB制約で対応 |

---

## 10. 実装順序（推奨）

### Step 1: バックエンド基盤
1. RoomRepository, FriendRepository 作成
2. RoomInvitation エンティティ作成
3. RoomService, RoomInvitationService 作成
4. RoomController (REST) 作成

### Step 2: 対戦ロジック拡張
5. BattleStateService に winsToVictory/maxRounds 動的設定追加
6. BattleService にルームマッチ対応追加
7. RoomController (WebSocket) 追加

### Step 3: フロントエンド
8. room_match_screen.dart 作成
9. 招待通知・一覧機能追加
10. battle_mode_selection_screen.dart 修正
11. battle_screen.dart 修正（ルームに戻る）

### Step 4: 統合・テスト
12. 統合テスト実施
13. バグ修正・調整
