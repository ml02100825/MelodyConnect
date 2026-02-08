# Fix: DataIntegrityViolationException を @Transactional 内で握りつぶしている問題

## Context

JPA/Hibernate では、UNIQUE 制約違反で `DataIntegrityViolationException` が発生すると、その時点で Hibernate セッションが汚染され、トランザクションが rollback-only になる。現在のコードは同一トランザクション内でこの例外を catch して続行しているが、メソッド終了時のコミットで `UnexpectedRollbackException` が発生する。

並行登録時に既存レコードへフォールバックする意図自体は正しいので、**制約違反が起きうる save 操作を `Propagation.REQUIRES_NEW` の別トランザクションに分離する**ことで解決する。

## 修正対象（3箇所）

### 1. VocabularyService — `saveVocabulary()` (line 69)
- `saveIncorrectWords()` (line 39, `@Transactional`) → ループ内で `saveVocabulary()` を呼ぶ
- `saveVocabulary()` も `@Transactional` だが同一トランザクション (REQUIRED)
- 制約違反後にループが継続 → コミット時に失敗

### 2. UserVocabularyService — `createVocabularyFromWordnik()` (line 329)
- `registerWordToUserVocabulary()` (line 263, `@Transactional`) から呼ばれる private メソッド
- `vocabularyRepository.save()` (line 368) で制約違反 → catch 後に `userVocabularyRepository.save()` (line 308) が失敗

### 3. SpotifyApiClientImpl — `getOrCreateArtist()` (line 1141)
- `ArtistSyncService.syncArtistSongs()` (line 41, `@Transactional`) → `spotifyApiClient.getAllSongsByArtist()` → `getOrCreateArtist()`
- `artistRepository.saveAndFlush()` (line 1154) で制約違反 → 後続の `songRepository.save()` が全て失敗

## 修正方針

制約違反が起きうる save を `@Transactional(propagation = Propagation.REQUIRES_NEW)` メソッドに分離する。内側のトランザクションだけがロールバックされ、外側のトランザクションは汚染されない。

---

## 実装手順

### Step 1: VocabularyService.java を修正

**ファイル**: `api/src/main/java/com/example/api/service/VocabularyService.java`

1. import 追加:
   - `org.springframework.transaction.annotation.Propagation`
   - `org.springframework.context.annotation.Lazy`
   - `com.example.api.dto.WordnikWordInfo`
   - `com.example.api.entity.Vocabulary` (既存)

2. self-injection フィールド追加 (self-invocation 問題の回避):
   ```java
   @Autowired
   @Lazy
   private VocabularyService self;
   ```

3. `saveVocabulary()` (line 69): `@Transactional` → `@Transactional(propagation = Propagation.REQUIRES_NEW)`

4. `saveIncorrectWords()` (line 57): `saveVocabulary(correctWord)` → `self.saveVocabulary(correctWord)` (プロキシ経由で呼ぶ)

5. 新規メソッド `saveVocabularyFromWordInfo()` を追加 (Step 2 で UserVocabularyService から利用):
   ```java
   @Transactional(propagation = Propagation.REQUIRES_NEW)
   public Vocabulary saveVocabularyFromWordInfo(String word, WordnikWordInfo wordInfo) {
       // 再チェック → save → catch DataIntegrityViolationException → findFirst
   }
   ```

### Step 2: UserVocabularyService.java を修正

**ファイル**: `api/src/main/java/com/example/api/service/UserVocabularyService.java`

1. `VocabularyService` の DI を追加:
   ```java
   @Autowired
   private VocabularyService vocabularyService;
   ```

2. `createVocabularyFromWordnik()` (line 329-381) を修正:
   - Wordnik API 呼び出し・バリデーションはそのまま (外側トランザクション内)
   - `vocabularyRepository.save(vocab)` + `DataIntegrityViolationException` catch ブロック (line 353-376) を削除
   - 代わりに `vocabularyService.saveVocabularyFromWordInfo(word, wordInfo)` を呼ぶ
   - 制約違反は `saveVocabularyFromWordInfo` 内の独立トランザクションで処理されるため、外側トランザクションは汚染されない

### Step 3: ArtistService.java に `getOrCreateArtist()` を追加

**ファイル**: `api/src/main/java/com/example/api/service/ArtistService.java`

1. import 追加:
   - `org.springframework.dao.DataIntegrityViolationException`
   - `org.springframework.transaction.annotation.Propagation`
   - `java.util.Optional`

2. 新規メソッド追加:
   ```java
   @Transactional(propagation = Propagation.REQUIRES_NEW)
   public Artist getOrCreateArtist(String artistApiId, String artistName) {
       // findByArtistApiId → save → catch DataIntegrityViolationException → findByArtistApiId
   }
   ```
   SpotifyApiClientImpl の既存 private メソッド (line 1141-1176) のロジックを移植。ただし汎用的な `catch (Exception e)` のフォールバック（デフォルトアーティスト返却）は除去し、予期せぬ例外はそのまま伝播させる。

### Step 4: SpotifyApiClientImpl.java を修正

**ファイル**: `api/src/main/java/com/example/api/client/impl/SpotifyApiClientImpl.java`

1. `ArtistService` の DI を追加 (`@Lazy` 付き — 循環参照回避: SpotifyApiClientImpl ↔ ArtistService):
   ```java
   @Autowired
   @Lazy
   private ArtistService artistService;
   ```

2. `parseTrackToSongWithArtist()` (line 1114): `getOrCreateArtist(...)` → `artistService.getOrCreateArtist(...)`

3. private `getOrCreateArtist()` メソッド (line 1131-1176) を削除

---

## 検証方法

1. `mvn compile` でコンパイルエラーがないことを確認
2. `mvn test` で既存テストが通ることを確認
3. 手動検証: 同じ単語/アーティストの並行登録で `UnexpectedRollbackException` が発生しないことを確認
