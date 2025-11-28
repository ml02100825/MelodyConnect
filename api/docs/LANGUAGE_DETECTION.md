# 音楽言語検出システム

楽曲の言語を自動判定する機能のドキュメント

## 概要

MelodyConnectアプリケーションでは、楽曲の言語を自動的に判定する機能を提供しています。この機能は、以下の複数のソースから情報を収集し、複合的なアプローチで言語を判定します。

### 判定の優先度

1. **文字種判定**（最も高速で信頼性が高い）
   - トラック名・アーティスト名に含まれる文字種から判定
   - 日本語（ひらがな・カタカナ・漢字）、韓国語（ハングル）、ロシア語（キリル文字）などを識別

2. **Spotifyジャンル情報**
   - アーティストの`genres`フィールドから判定
   - "j-pop", "k-pop", "c-pop"などのジャンル名をキーワードマッチング

3. **歌詞分析**（Genius API）
   - 実際の歌詞テキストから文字種を分析して判定

4. **デフォルト**
   - どの方法でも判定できない場合は英語（ENGLISH）

## 使用方法

### 基本的な使用例

```java
@Autowired
private MusicLanguageService musicLanguageService;

// トラック名とアーティスト名から言語を判定
LanguageCode language = musicLanguageService.detectLanguageFromNames(
    "夜に駆ける",  // トラック名
    "YOASOBI"      // アーティスト名
);

System.out.println(language); // JAPANESE (ja)
```

### 歌詞から直接判定

```java
String lyrics = "君と見た夢を\n僕は覚えている\n二人で歩いた道を";
LanguageCode language = musicLanguageService.detectLanguageFromLyrics(lyrics);

System.out.println(language); // JAPANESE (ja)
```

### Spotify Track IDから判定

```java
String spotifyTrackId = "3BQHpFgAp4l80e1XslIjNI";
LanguageCode language = musicLanguageService.detectLanguage(spotifyTrackId);
```

### 言語コードの操作

```java
// 文字列コードから言語を取得
LanguageCode lang = LanguageCode.fromCode("ja");

// 言語コードと表示名を取得
String code = lang.getCode();         // "ja"
String display = lang.getDisplayName(); // "日本語"

// 有効な言語かチェック
boolean isValid = lang.isValid(); // true (UNKNOWN以外)
```

## サポート言語

| 言語コード | 言語名 | 判定方法 |
|-----------|-------|---------|
| `ja` | 日本語 | ひらがな・カタカナ・漢字の検出 |
| `ko` | 韓国語 | ハングル文字の検出 |
| `en` | 英語 | 一般的な英単語の検出、デフォルト |
| `zh` | 中国語 | CJK統合漢字の検出 |
| `es` | スペイン語 | ジャンル判定（latin, reggaeton等） |
| `fr` | フランス語 | ジャンル判定（french, chanson） |
| `de` | ドイツ語 | ジャンル判定（german） |
| `pt` | ポルトガル語 | - |
| `it` | イタリア語 | - |
| `ru` | ロシア語 | キリル文字の検出 |
| `unknown` | 不明 | 判定不可の場合 |

## ユーティリティクラス

### LanguageDetectionUtils

言語判定の共通ロジックを提供する静的ユーティリティクラスです。

```java
import com.example.api.util.LanguageDetectionUtils;

// 日本語文字数をカウント
long count = LanguageDetectionUtils.countJapaneseCharacters("こんにちは");

// 文字種から言語を判定
LanguageCode lang = LanguageDetectionUtils.detectFromCharacters("안녕하세요");

// ジャンルリストから言語を判定
List<String> genres = Arrays.asList("j-pop", "japanese indie");
LanguageCode lang2 = LanguageDetectionUtils.detectFromGenres(genres);

// 複数のテキストから判定
List<String> texts = Arrays.asList("夜に駆ける", "YOASOBI");
LanguageCode lang3 = LanguageDetectionUtils.detectFromMultipleTexts(texts);
```

## 実装例：QuestionGeneratorServiceでの統合

```java
@Service
public class QuestionGeneratorService {

    @Autowired
    private MusicLanguageService musicLanguageService;

    public QuestionGenerationResponse generateQuestions(QuestionGenerationRequest request) {
        Song selectedSong = selectSong(request);

        // 言語を自動判定
        LanguageCode detectedLang = musicLanguageService.detectLanguageFromNames(
            selectedSong.getSongname(),
            selectedSong.getTempArtistName()
        );

        // Songエンティティに言語を設定
        selectedSong.setLanguage(detectedLang.getCode());

        // 以降の処理...
    }
}
```

## テスト

### 単体テスト

```bash
# ユーティリティクラスのテスト
mvn test -Dtest=LanguageDetectionUtilsTest

# サービスクラスのテスト
mvn test -Dtest=MusicLanguageServiceTest
```

### テストケース例

```java
@Test
public void testDetectJapanese() {
    // YOASOBI - 夜に駆ける
    LanguageCode result = service.detectLanguageFromNames("夜に駆ける", "YOASOBI");
    assertEquals(LanguageCode.JAPANESE, result);
}

@Test
public void testDetectKorean() {
    // BTS
    LanguageCode result = service.detectLanguageFromNames("Dynamite", "방탄소년단");
    assertEquals(LanguageCode.KOREAN, result);
}

@Test
public void testDetectFromGenres() {
    List<String> genres = Arrays.asList("j-pop", "japanese indie pop");
    LanguageCode result = LanguageDetectionUtils.detectFromGenres(genres);
    assertEquals(LanguageCode.JAPANESE, result);
}
```

## パフォーマンス考慮事項

1. **文字種判定が最速**: トラック名・アーティスト名から判定できる場合、APIコールなしで即座に判定可能
2. **歌詞分析はフォールバック**: 文字種判定で判定できない場合のみ歌詞を取得
3. **キャッシュの活用**: 同じトラックの言語判定結果はキャッシュすることを推奨

## 拡張方法

### 新しい言語の追加

1. `LanguageCode` enumに新しい言語を追加
2. `LanguageDetectionUtils.detectFromCharacters()`に判定ロジックを追加
3. 必要に応じて`detectFromGenres()`にジャンルマッピングを追加

例：アラビア語を追加する場合

```java
// 1. LanguageCode.javaに追加
ARABIC("ar", "アラビア語"),

// 2. LanguageDetectionUtils.javaに文字判定を追加
public static long countArabicCharacters(String text) {
    return text.chars()
        .filter(c -> c >= 0x0600 && c <= 0x06FF)  // アラビア文字
        .count();
}

// 3. detectFromCharacters()に追加
long arabicCount = countArabicCharacters(text);
if ((double) arabicCount / totalChars >= LANGUAGE_DETECTION_THRESHOLD) {
    return LanguageCode.ARABIC;
}
```

## トラブルシューティング

### 判定精度が低い場合

- **文字種が少ない場合**: 閾値（5%）を下回ると判定されません
- **混在テキスト**: 複数言語が混在する場合、最も多い言語が選ばれます
- **英語デフォルト**: 判定できない場合は英語になります

### ログ出力

詳細なログは`DEBUG`レベルで出力されます：

```properties
# application.properties
logging.level.com.example.api.util.LanguageDetectionUtils=DEBUG
logging.level.com.example.api.service.impl.MusicLanguageServiceImpl=DEBUG
```

## API仕様

### MusicLanguageService

```java
public interface MusicLanguageService {
    /**
     * Spotifyトラックから言語を判定
     */
    LanguageCode detectLanguage(String spotifyTrackId);

    /**
     * トラック名とアーティスト名から言語を判定
     */
    LanguageCode detectLanguageFromNames(String trackName, String artistName);

    /**
     * 歌詞から言語を判定
     */
    LanguageCode detectLanguageFromLyrics(String lyrics);
}
```

## 参考資料

- [Unicode文字範囲](https://unicode.org/charts/)
- [ISO 639-1 言語コード](https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes)
- [Spotify Web API](https://developer.spotify.com/documentation/web-api/)
- [Genius API](https://docs.genius.com/)
