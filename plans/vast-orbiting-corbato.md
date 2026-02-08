# バトル画面でFILL_IN_BLANK問題に歌詞の原文を表示する

## Context

学習モード（`quiz_question_screen.dart`）ではFILL_IN_BLANK問題で「元の歌詞」（`sourceFragment`）が表示されるが、バトル画面（`battle_screen.dart`）では表示されていない。バトル画面にも同様の表示を追加する。

## 現状の問題

`sourceFragment`がバトルのデータフローに含まれていない:

1. **Question entity** は `sourceFragment` を持っている ([Question.java:101-102](api/src/main/java/com/example/api/entity/Question.java#L101-L102))
2. **QuizStartResponse DTO** (学習用) は `sourceFragment` を含む ([QuizStartResponse.java:64](api/src/main/java/com/example/api/dto/QuizStartResponse.java#L64))
3. **QuestionResponse DTO** (バトル用) には `sourceFragment` が**存在しない** ([QuestionResponse.java](api/src/main/java/com/example/api/dto/battle/QuestionResponse.java))
4. **BattleQuestion** (Flutter) にも `sourceFragment` が**存在しない** ([battle_models.dart:56-119](web/lib/models/battle_models.dart#L56-L119))

## 修正計画

### Step 1: バックエンド - QuestionResponse DTOに`sourceFragment`を追加

**ファイル:** [QuestionResponse.java](api/src/main/java/com/example/api/dto/battle/QuestionResponse.java)

- `sourceFragment` フィールド + getter/setter を追加
- コンストラクタに `sourceFragment` パラメータを追加

### Step 2: バックエンド - BattleControllerで`sourceFragment`を渡す

**ファイル:** [BattleController.java:442-483](api/src/main/java/com/example/api/controller/BattleController.java#L442-L483)

`sendQuestionToPlayers()` 内の `QuestionResponse` 生成時に `question.getSourceFragment()` を渡す。

### Step 3: フロントエンド - BattleQuestionモデルに`sourceFragment`を追加

**ファイル:** [battle_models.dart:56-119](web/lib/models/battle_models.dart#L56-L119)

- `sourceFragment` フィールドを追加
- `fromJson` でパース

### Step 4: フロントエンド - バトル画面の虫食い問題に歌詞原文を表示

**ファイル:** [battle_screen.dart:1348-1395](web/lib/screens/battle_screen.dart#L1348-L1395)

`_buildFillInBlankQuestion()` に、`quiz_question_screen.dart:388-428` と同様の「元の歌詞」表示を追加。問題文（`text`）の前に表示する。

参考実装（[quiz_question_screen.dart:388-428](web/lib/screens/quiz_question_screen.dart#L388-L428)):
```dart
if (_currentQuestion.sourceFragment != null &&
    _currentQuestion.sourceFragment!.isNotEmpty) ...[
  Container(
    // 紫色背景のカード内に「元の歌詞」ラベル + sourceFragment テキスト
  ),
  const SizedBox(height: 16),
],
```

## 修正対象ファイル

1. [QuestionResponse.java](api/src/main/java/com/example/api/dto/battle/QuestionResponse.java) - `sourceFragment` フィールド追加
2. [BattleController.java](api/src/main/java/com/example/api/controller/BattleController.java) - `sourceFragment` を渡す
3. [battle_models.dart](web/lib/models/battle_models.dart) - `sourceFragment` フィールド追加
4. [battle_screen.dart](web/lib/screens/battle_screen.dart) - 歌詞原文の表示追加

## 検証方法

1. バトル画面でFILL_IN_BLANK問題が表示された時、`sourceFragment`がある問題では「元の歌詞」セクションが表示される
2. `sourceFragment`がnull/空の問題では「元の歌詞」セクションが表示されない
3. LISTENING問題には影響しない
