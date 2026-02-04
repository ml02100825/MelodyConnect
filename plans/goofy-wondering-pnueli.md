# Genius検索結果の検証ロジック追加

## 問題
Geniusの検索で全く関係ない曲を取得している。
- 検索: `artist=初星学園, song=ハッピーミルフィーユ`
- 取得した曲: `"List of Virtual YouTubers (VTubers)"` by `"Genius Japan"`

## 原因
`GeniusApiClientImpl.searchAndGetLyricsWithMetadata()`（行321-392）で、検索結果の候補が要求されたアーティスト/曲名と一致するかの検証がない。「romanized」フィルターのみで、最初にヒットした候補をそのまま使用している。

## 解決策
アーティスト名と曲名の**厳密な一致チェック**を追加。一致しない場合はスキップし、全候補が不一致なら歌詞取得失敗としてエラーを返す。

## 変更ファイル
- [GeniusApiClientImpl.java](api/src/main/java/com/example/api/client/impl/GeniusApiClientImpl.java)

## 実装詳細

### 1. 一致チェック用のヘルパーメソッドを追加（行393付近に追加）

```java
/**
 * 曲名が一致するかチェック
 * 正規化後に完全一致または部分一致（どちらかが他方を含む）を判定
 */
private boolean isTitleMatch(String searchTitle, String resultTitle) {
    String normalizedSearch = normalizeForComparison(searchTitle);
    String normalizedResult = normalizeForComparison(resultTitle);

    if (normalizedSearch.isEmpty() || normalizedResult.isEmpty()) {
        return false;
    }

    // 完全一致
    if (normalizedSearch.equals(normalizedResult)) {
        return true;
    }

    // 部分一致（どちらかが他方を含む）
    return normalizedSearch.contains(normalizedResult) ||
           normalizedResult.contains(normalizedSearch);
}

/**
 * アーティスト名が一致するかチェック
 */
private boolean isArtistMatch(String searchArtist, String resultArtist) {
    String normalizedSearch = normalizeForComparison(searchArtist);
    String normalizedResult = normalizeForComparison(resultArtist);

    if (normalizedSearch.isEmpty() || normalizedResult.isEmpty()) {
        return false;
    }

    // "Genius"で始まるアーティストは公式アカウント（歌詞提供者）なので常に不一致
    if (normalizedResult.startsWith("genius")) {
        return false;
    }

    // 完全一致
    if (normalizedSearch.equals(normalizedResult)) {
        return true;
    }

    // 部分一致
    return normalizedSearch.contains(normalizedResult) ||
           normalizedResult.contains(normalizedSearch);
}

/**
 * 比較用に文字列を正規化
 * - 小文字化
 * - 空白を正規化（全角含む）
 * - 記号を除去
 */
private String normalizeForComparison(String str) {
    if (str == null) {
        return "";
    }
    return str.toLowerCase()
              .replaceAll("[\\s　]+", " ")  // 空白正規化（全角含む）
              .replaceAll("[^\\p{L}\\p{N}\\s]", "")  // 記号除去（Unicode文字・数字・空白以外）
              .trim();
}
```

### 2. searchAndGetLyricsWithMetadataメソッド内で一致チェックを追加（行361-362の間）

```java
// ローマ字版をスキップ（既存コード：行355-361）の後に追加:

// 曲名とアーティスト名の一致チェック
if (!isTitleMatch(songTitle, title)) {
    logger.info("候補をスキップ（曲名不一致）: 検索=\"{}\", 結果=\"{}\"",
                songTitle, title);
    continue;
}
if (!isArtistMatch(artistName, primaryArtistName)) {
    logger.info("候補をスキップ（アーティスト不一致）: 検索=\"{}\", 結果=\"{}\"",
                artistName, primaryArtistName);
    continue;
}
```

## エラーハンドリング（エラーメッセージの改善）

### 変更ファイル
- [QuestionGeneratorService.java](api/src/main/java/com/example/api/service/QuestionGeneratorService.java) 行247-248

### 変更内容
```java
// 変更前
if (lyrics == null || lyrics.isEmpty()) {
    throw new IllegalStateException("歌詞の取得に失敗しました");
}

// 変更後
if (lyrics == null || lyrics.isEmpty()) {
    throw new IllegalStateException("歌詞が取得できませんでした。Geniusに歌詞が存在するかご確認ください。");
}
```

このメッセージは`QuizController`（行47-51）で`"クイズの開始に失敗しました: " + e.getMessage()`としてレスポンスに含まれる。

## フロントエンドのエラーメッセージ表示修正

### 問題
`quiz_api_service.dart`でエラー時にレスポンスボディを読み取っていない。固定メッセージ「クイズの開始に失敗しました: 500」のみ表示される。

### 変更ファイル
- [quiz_api_service.dart](web/lib/services/quiz_api_service.dart) 行17-18

### 変更内容
```dart
// 変更前
if (response.statusCode != 200) {
  throw Exception("クイズの開始に失敗しました: ${response.statusCode}");
}

// 変更後
if (response.statusCode != 200) {
  try {
    final errorBody = json.decode(response.body);
    final message = errorBody['message'] ?? 'クイズの開始に失敗しました';
    throw Exception(message);
  } catch (e) {
    if (e is Exception && e.toString().contains('クイズの開始に失敗しました') == false) {
      throw Exception('クイズの開始に失敗しました: ${response.statusCode}');
    }
    rethrow;
  }
}
```

## Genius検索で日本語版歌詞を優先取得

### 問題
Geniusの検索結果で、最初に歌詞が取得できた候補を返している。英語版（翻訳）が先にヒットすると、日本語版があっても英語版を返してしまう。

### 解決策
1. 検索結果を増やす（per_page: 10 → 20）
2. 歌詞取得後に言語をチェックし、日本語版を優先
3. 英語版はスキップして次の候補を試す
4. 一度試したGeniusSongIdは除外する

### 変更ファイル
- [GeniusApiClientImpl.java](api/src/main/java/com/example/api/client/impl/GeniusApiClientImpl.java)

### 変更内容

#### 1. 検索結果数を増やす（行336）
```java
// 変更前
.queryParam("per_page", 10)

// 変更後
.queryParam("per_page", 20)
```

#### 2. 歌詞取得後に日本語チェックを追加（行380-388付近）
```java
// 変更前
if (lyrics != null && !lyrics.isEmpty()) {
    String detectedLanguage = detectLanguage(lyrics);
    logger.info("歌詞取得成功: ...");
    return new LyricsResult(lyrics, songId, detectedLanguage);
}

// 変更後
if (lyrics != null && !lyrics.isEmpty()) {
    String detectedLanguage = detectLanguage(lyrics);

    // 日本語の歌詞を優先（英語版はスキップして次を試す）
    if ("en".equals(detectedLanguage)) {
        logger.info("英語版をスキップ（日本語版を探します）: geniusSongId={}, title=\"{}\"",
                    songId, title);
        // 英語版を一時保存（日本語版が見つからなかった場合のフォールバック用）
        if (fallbackResult == null) {
            fallbackResult = new LyricsResult(lyrics, songId, detectedLanguage);
        }
        continue;
    }

    logger.info("歌詞取得成功: geniusSongId={}, title=\"{}\", lyrics_length={}, language={}",
        songId, title, lyrics.length(), detectedLanguage);
    return new LyricsResult(lyrics, songId, detectedLanguage);
}
```

#### 3. フォールバック用変数とループ後の処理を追加
```java
// ループ前に追加
LyricsResult fallbackResult = null;

// ループ後（全候補を試した後）に追加
if (fallbackResult != null) {
    logger.info("日本語版が見つからないため英語版を使用: geniusSongId={}",
                fallbackResult.getGeniusSongId());
    return fallbackResult;
}
```

#### 4. 既に試したGeniusSongIdを除外（オプション）
```java
// ループ前に追加
Set<Long> triedSongIds = new HashSet<>();

// ループ内でスキップ
if (triedSongIds.contains(songId)) {
    continue;
}
triedSongIds.add(songId);
```

## 検証方法
1. APIを再起動
2. 同じ曲（初星学園/ハッピーミルフィーユ）でクイズを開始
3. ログで以下を確認：
   - `曲選択試行 1/5` などのログが出力される
   - 歌詞取得失敗時に `別の曲を試します` が出力され、次の曲が選択される
   - 最大5回まで試行される
4. 5回すべて失敗した場合のみ「歌詞が取得できませんでした」エラーが表示される
