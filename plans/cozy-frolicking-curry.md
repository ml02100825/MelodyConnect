# 実装プラン

## 概要
3つのタスクに対応します：
1. クイズ完了時に `total_play` と `lessonsNum` を増加（リタイア時は除外）
2. quiz_question_screen.dart にアーティスト名と曲名を表示
3. バトルモードの無限ローディング問題の原因特定

---

## タスク1: クイズ完了時のカウント増加

### 現状分析
- `QuizService.completeQuiz()` は結果を保存するが、`total_play` と `lessonsNum` を増加していない
- リタイア時は残りの問題を不正解として `_completeQuiz()` を呼び出している
- バックエンドはリタイアかどうかを判別できない

### 修正ファイル

#### 1. QuizCompleteRequest.java
パス: `api/src/main/java/com/example/api/dto/QuizCompleteRequest.java`

変更内容: `retired` フラグを追加
```java
// 追加するフィールド
private Boolean retired = false;
```

#### 2. QuizService.java
パス: `api/src/main/java/com/example/api/service/QuizService.java`

変更内容:
- `UserRepository` と `WeeklyLessonsRepository` を注入
- `completeQuiz()` 内で `retired=false` の場合のみカウントを増加

```java
// 注入追加
@Autowired
private UserRepository userRepository;

@Autowired
private WeeklyLessonsRepository weeklyLessonsRepository;

// completeQuiz() 内（結果保存後、リタイアでない場合）
if (request.getRetired() == null || !request.getRetired()) {
    // User.totalPlay を +1
    User user = userRepository.findById(request.getUserId())
        .orElseThrow(() -> new IllegalArgumentException("ユーザーが見つかりません"));
    user.setTotalPlay(user.getTotalPlay() + 1);
    userRepository.save(user);

    // WeeklyLessons.lessonsNum を +1
    WeeklyLessons weeklyLessons = weeklyLessonsRepository
        .findByUserAndWeekFlag(user, true)
        .stream()
        .findFirst()
        .orElseGet(() -> {
            WeeklyLessons newWl = new WeeklyLessons(user);
            return weeklyLessonsRepository.save(newWl);
        });
    weeklyLessons.setLessonsNum(weeklyLessons.getLessonsNum() + 1);
    weeklyLessonsRepository.save(weeklyLessons);
}
```

#### 3. quiz_question_screen.dart
パス: `web/lib/screens/quiz_question_screen.dart`

変更内容: `_retire()` でリタイアフラグを送信

#### 4. quiz_api_service.dart
パス: `web/lib/services/quiz_api_service.dart`

変更内容: `completeQuiz()` に `retired` パラメータを追加

#### 5. quiz_models.dart
パス: `web/lib/models/quiz_models.dart`

変更内容: `QuizCompleteRequest` に `retired` フィールドを追加

---

## タスク2: アーティスト名と曲名の表示

### 現状分析
UIコードは実装済みだが、**データが正しく渡されていない可能性が高い**

#### 問題の原因（推定）
1. **フロントエンドの型不一致**: `SongInfo.artistName`が非nullableだが、バックエンドがnullを返す可能性
2. **バックエンドの問題**: `getArtistNameFromSong()`がnullを返す場合がある
3. **モード依存**: `COMPLETE_RANDOM`モードでは`songInfo`自体がnull

#### 該当コード
- バックエンド: `QuizService.java` lines 76-84, 144-153
- フロントエンド: `quiz_models.dart` lines 103-124

### 修正ファイル

#### 1. quiz_models.dart
パス: `web/lib/models/quiz_models.dart`

変更内容: `artistName`をnullable型に変更
```dart
class SongInfo {
  final int songId;
  final String songName;
  final String? artistName;  // nullable に変更
  final String? genre;
  // ...
}
```

#### 2. quiz_question_screen.dart
パス: `web/lib/screens/quiz_question_screen.dart`

変更内容: null安全な表示処理
```dart
Widget _buildSongInfoChip() {
  final artistName = widget.songInfo?.artistName ?? '不明なアーティスト';
  final songName = widget.songInfo?.songName ?? '不明な曲';
  // ...
  Text('$artistName - $songName', ...)
}
```

#### 3. QuizService.java（オプション）
パス: `api/src/main/java/com/example/api/service/QuizService.java`

変更内容: artistNameがnullの場合のフォールバック
```java
String artistName = getArtistNameFromSong(actualSong);
if (artistName == null) {
    artistName = "Unknown Artist";
}
```

---

## タスク3: バトル無限ローディング問題

### 原因特定結果

**根本原因**: サーバー側に回答フェーズのタイムアウトハンドラがない

#### 詳細
1. **クライアント側**: 90秒タイマーが完了すると `/app/battle/timeout` にWebSocket通知を送信
2. **問題のシナリオ**: 両プレイヤーがタイムアウト通知を送信しない場合（アプリクラッシュ、ネットワーク切断、バックグラウンド化）
3. **サーバー側の欠陥**:
   - `BattleController.checkRoundResultTimeouts()` は「ラウンド結果待ち」のタイムアウトのみチェック
   - 「回答待ち」フェーズのタイムアウトをチェックする Scheduled タスクがない

#### 影響を受けるファイル
- `BattleStateService.java`: `isRoundTimedOut()` メソッドは存在するが、定期呼び出しされていない
- `BattleController.java`: 回答フェーズのタイムアウトチェックがない
- `BattleService.java`: 回答フェーズのタイムアウトハンドラがない

### 修正ファイル

#### 1. BattleStateService.java
パス: `api/src/main/java/com/example/api/service/BattleStateService.java`

変更内容: 回答フェーズタイムアウトチェック用メソッド追加
```java
/**
 * 回答フェーズでタイムアウトしている試合を取得
 * roundStartTimeが設定されており、90秒以上経過し、
 * かつroundResultStartTimeがnull（まだラウンド処理されていない）の試合
 */
public List<String> getTimedOutAnswerPhaseMatches() {
    List<String> timedOutMatches = new ArrayList<>();
    for (Map.Entry<String, BattleState> entry : activeBattles.entrySet()) {
        BattleState state = entry.getValue();
        if (state.getStatus() == Status.IN_PROGRESS &&
            state.getRoundStartTime() != null &&
            state.getRoundResultStartTime() == null &&
            isRoundTimedOut(entry.getKey())) {
            timedOutMatches.add(entry.getKey());
        }
    }
    return timedOutMatches;
}
```

#### 2. BattleService.java
パス: `api/src/main/java/com/example/api/service/BattleService.java`

変更内容: 委譲メソッド追加
```java
public List<String> getTimedOutAnswerPhaseMatches() {
    return stateService.getTimedOutAnswerPhaseMatches();
}
```

#### 3. BattleController.java
パス: `api/src/main/java/com/example/api/controller/BattleController.java`

変更内容: 回答フェーズのタイムアウトチェック用Scheduledタスク追加（lines 274付近に追加）
```java
/**
 * 定期的に回答フェーズのタイムアウトをチェック（5秒ごと）
 * 90秒経過しても両者が回答していない場合、強制的にラウンドを処理
 */
@Scheduled(fixedRate = 5000)
public void checkAnswerPhaseTimeouts() {
    try {
        List<String> timedOutMatches = battleService.getTimedOutAnswerPhaseMatches();
        for (String matchId : timedOutMatches) {
            logger.info("回答フェーズタイムアウト、強制的にラウンド処理: matchId={}", matchId);
            processRoundEnd(matchId);  // 既存のラウンド終了処理を再利用
        }
    } catch (Exception e) {
        logger.error("回答フェーズタイムアウトチェックエラー", e);
    }
}
```

---

## 検証方法

### タスク1の検証
1. クイズを最後まで完了し、DBで `total_play` と `lessonsnum` が +1 されていることを確認
2. リタイアボタンでクイズを終了し、カウントが増加しないことを確認

### タスク2の検証
1. クイズ画面でアーティスト名と曲名が紫色のチップで表示されることを確認
2. songInfo が null の場合にチップが表示されないことを確認

### タスク3の検証
1. 修正後、両プレイヤーがタイムアウトした場合に90秒後にラウンドが処理されることを確認
2. 無限ローディングが発生しないことを確認

---

## 実装の優先順位
1. **タスク1** (重要度: 高) - 学習記録に直接影響
2. **タスク2** (重要度: 高) - UI表示のバグ修正
3. **タスク3** (重要度: 高) - ユーザー体験に直接影響

## 修正対象ファイル一覧
| タスク | ファイル | 変更種別 |
|--------|----------|----------|
| 1 | `api/.../dto/QuizCompleteRequest.java` | フィールド追加 |
| 1 | `api/.../service/QuizService.java` | ロジック追加 |
| 1 | `web/.../models/quiz_models.dart` | フィールド追加 |
| 1 | `web/.../services/quiz_api_service.dart` | パラメータ追加 |
| 1 | `web/.../screens/quiz_question_screen.dart` | リタイアフラグ送信 |
| 2 | `web/.../models/quiz_models.dart` | 型変更 (nullable) |
| 2 | `web/.../screens/quiz_question_screen.dart` | null安全処理 |
| 2 | `api/.../service/QuizService.java` | フォールバック追加（オプション） |
| 3 | `api/.../service/BattleStateService.java` | メソッド追加 |
| 3 | `api/.../service/BattleService.java` | 委譲メソッド追加 |
| 3 | `api/.../controller/BattleController.java` | Scheduledタスク追加 |
