# Vocabulary重複によるNonUniqueResultException修正計画

## Context

バトル終了時の単語帳登録処理で、`VocabularyRepository.findByWord("love")`が2件のレコードを返し、`NonUniqueResultException`が発生している。これにより、間違えた単語の単語帳登録が失敗している。

**根本原因**: `vocabulary`テーブルの`word`カラムにUNIQUE制約がない。バトル終了時に両プレイヤーの単語登録が非同期(`vocab-async-1`, `vocab-async-2`)で同時実行されるため、同じ単語が同時に`findByWord` → null → `save`の流れで重複作成される。

## 修正内容

### Step 1: `findByWord`を重複に強くする

**ファイル**: `api/src/main/java/com/example/api/repository/VocabularyRepository.java`

- `findByWord` → `findFirstByWordOrderByVocabIdAsc` に変更（重複があっても1件だけ返す）
- 既存の`findByWord`も残し、呼び出し元を全て新メソッドに切り替え

**ファイル**: `api/src/main/java/com/example/api/service/UserVocabularyService.java`

- L323: `findVocabularyByWordCached`内の`vocabularyRepository.findByWord(word)` → `findFirstByWordOrderByVocabIdAsc(word)` に変更

### Step 2: `createVocabularyFromWordnik`にrace condition対策を追加

**ファイル**: `api/src/main/java/com/example/api/service/UserVocabularyService.java`

- `createVocabularyFromWordnik`内（L361の`save`の前）に `existsByWord` チェックを追加
- `save`を`try/catch`で囲み、`DataIntegrityViolationException`が発生した場合は既存レコードを取得して返す（UNIQUE制約追加後のrace condition対策）

### Step 3: Vocabulary Entityに`@Column(unique = true)`を追加

**ファイル**: `api/src/main/java/com/example/api/entity/Vocabulary.java`

- L26: `@Column(name = "word", nullable = false, length = 50)` → `@Column(name = "word", nullable = false, length = 50, unique = true)` に変更
- `ddl-auto=update`なので、アプリ起動時に自動でUNIQUE制約が追加される
- **注意**: 既存の重複データがあるとアプリ起動時にエラーになるため、先にStep 4のデータクリーンアップが必要

### Step 4: 既存の重複データのクリーンアップSQL

デプロイ前にDBで実行するSQL:

```sql
-- 重複確認
SELECT word, COUNT(*) as cnt FROM vocabulary
WHERE is_active = true AND is_deleted = false
GROUP BY word HAVING cnt > 1;

-- 重複のうち新しい方を論理削除（古い方=vocab_idが小さい方を残す）
UPDATE vocabulary v1
JOIN (
    SELECT word, MIN(vocab_id) as keep_id
    FROM vocabulary
    WHERE is_active = true AND is_deleted = false
    GROUP BY word
    HAVING COUNT(*) > 1
) v2 ON v1.word = v2.word AND v1.vocab_id != v2.keep_id
SET v1.is_deleted = true
WHERE v1.is_active = true AND v1.is_deleted = false;

-- user_vocabularyの参照先を残す方に付け替え
-- (重複のvocab_idを参照しているuser_vocabularyレコードがある場合)
```

## 修正ファイル一覧

| ファイル | 変更内容 |
|---------|---------|
| `api/src/main/java/com/example/api/entity/Vocabulary.java` | `word`に`unique = true`追加 |
| `api/src/main/java/com/example/api/repository/VocabularyRepository.java` | `findFirstByWordOrderByVocabIdAsc`メソッド追加 |
| `api/src/main/java/com/example/api/service/UserVocabularyService.java` | `findByWord`呼び出し変更 + race condition対策 |

## 検証方法

1. 重複クリーンアップSQL実行後、`SELECT word, COUNT(*) FROM vocabulary GROUP BY word HAVING COUNT(*) > 1`で重複が0件であることを確認
2. アプリ起動時にUNIQUE制約追加のDDLがエラーなく実行されることを確認
3. バトルでリスニング問題を間違えた後、`UserVocabulary登録中にエラー`のログが出ないことを確認
4. 単語帳画面で間違えた単語が表示されることを確認
