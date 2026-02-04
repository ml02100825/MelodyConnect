# 実装計画: クイズ結果画面の修正と単語帳登録機能

## 概要
1. 「もう一度挑戦」ボタンをquiz_selection_screen.dartに遷移するように変更
2. バトルモード降参時の不正解単語をUserVocabularyに登録（学習モードは既に実装済み）

---

## タスク1: 「もう一度挑戦」ボタンのナビゲーション変更

### 現状
- [quiz_result_screen.dart:478-481](web/lib/screens/quiz_result_screen.dart#L478-L481)の`_retryQuiz()`メソッド
- 現在: `Navigator.of(context).popUntil((route) => route.isFirst)` → ホーム画面に戻る

### 変更内容
`_retryQuiz()`メソッドを修正して`QuizSelectionScreen`に遷移させる

```dart
void _retryQuiz(BuildContext context) {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (context) => const QuizSelectionScreen(),
    ),
  );
}
```

### 修正ファイル
- [web/lib/screens/quiz_result_screen.dart](web/lib/screens/quiz_result_screen.dart)
  - import文を追加: `import 'quiz_selection_screen.dart';`
  - `_retryQuiz()`メソッドを修正

---

## タスク2: バトルモード降参時の単語帳登録修正

### 現状分析
- [BattleService.java:1036-1081](api/src/main/java/com/example/api/service/BattleService.java#L1036-L1081): 単語帳登録処理
- **問題点**: LISTENING問題で空回答の場合は登録されない（1099-1102行の`!userAnswer.isEmpty()`チェック）
- 学習モードは既に正しく動作している

### 修正ファイル
- [api/src/main/java/com/example/api/service/BattleService.java](api/src/main/java/com/example/api/service/BattleService.java)
  - `registerVocabularyForPlayer`メソッド (1088-1109行)を修正
  - 空回答チェックを削除し、学習モードと同じ挙動にする

### 修正内容
```java
private boolean registerVocabularyForPlayer(Long userId, Question question,
                                             QuestionFormat format,
                                             BattleStateService.PlayerAnswer playerAnswer,
                                             String correctAnswer) {
    try {
        if (QuestionFormat.FILL_IN_THE_BLANK.equals(format)) {
            userVocabularyService.registerFillInBlankAnswerAsync(userId, question.getAnswer());
            return true;
        } else if (QuestionFormat.LISTENING.equals(format) && !playerAnswer.isCorrect()) {
            // 空回答チェックを削除 - 学習モードと同じ挙動に
            String userAnswer = playerAnswer.getAnswer();
            userVocabularyService.registerListeningMistakesAsync(
                userId,
                userAnswer != null ? userAnswer : "",  // nullの場合は空文字
                correctAnswer
            );
            return true;
        }
    } catch (Exception e) {
        logger.debug("単語帳登録スキップ: userId={}, error={}", userId, e.getMessage());
    }
    return false;
}
```

---

## 検証方法

### タスク1の検証
1. 学習モードでクイズを完了
2. 結果画面で「もう一度挑戦」ボタンをクリック
3. quiz_selection_screen（学習設定画面）に遷移することを確認

### タスク2の検証
1. バトルモードで対戦中に降参
2. UserVocabularyテーブルに回答済みの不正解単語が追加されていることを確認

---

## 変更ファイル一覧
1. `web/lib/screens/quiz_result_screen.dart` - ナビゲーション修正
2. `api/src/main/java/com/example/api/service/BattleService.java` - 単語帳登録修正
