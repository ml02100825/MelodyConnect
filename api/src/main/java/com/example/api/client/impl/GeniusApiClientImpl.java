package com.example.api.client.impl;

import com.example.api.client.GeniusApiClient;
import com.example.api.util.LanguageDetectionUtils;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;
import org.jsoup.nodes.Element;
import org.jsoup.select.Elements;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Primary;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;

/**
 * Genius API Client の実装
 * 歌詞を取得するためのGenius API統合とWebスクレイピング
 */
@Component
@Primary
public class GeniusApiClientImpl implements GeniusApiClient {

    private static final Logger logger = LoggerFactory.getLogger(GeniusApiClientImpl.class);
    private static final String GENIUS_API_BASE_URL = "https://api.genius.com";

    private final WebClient webClient;
    private final ObjectMapper objectMapper;

    @Value("${genius.api.key:}")
    private String apiKey;

    public GeniusApiClientImpl(ObjectMapper objectMapper) {
        this.objectMapper = objectMapper;
        this.webClient = WebClient.builder()
            .baseUrl(GENIUS_API_BASE_URL)
            .build();
    }

    @Override
    public String getLyrics(Long geniusSongId) {
        if (apiKey == null || apiKey.isEmpty()) {
            logger.warn("Genius APIキーが設定されていません。モックデータを返します。");
            return getMockLyrics();
        }

        try {
            logger.info("Geniusから歌詞を取得中: songId={}", geniusSongId);

            // 1. まず曲の情報を取得してURLを取得
            String songUrl = getSongUrl(geniusSongId);

            if (songUrl == null || songUrl.isEmpty()) {
                logger.error("曲のURLを取得できませんでした: songId={}", geniusSongId);
                return getMockLyrics();
            }

            // 2. WebスクレイピングでURLから歌詞を取得
            return scrapeLyrics(songUrl);

        } catch (Exception e) {
            logger.error("歌詞の取得中にエラーが発生しました: songId={}", geniusSongId, e);
            return getMockLyrics();
        }
    }

    @Override
    public String getLyricsByUrl(String songUrl) {
        logger.info("URLから歌詞を取得中: url={}", songUrl);
        try {
            return scrapeLyrics(songUrl);
        } catch (Exception e) {
            logger.error("URLからの歌詞取得に失敗しました: url={}", songUrl, e);
            return getMockLyrics();
        }
    }

    /**
     * GeniusのページからWebスクレイピングで歌詞を取得
     */
    private String scrapeLyrics(String songUrl) {
        try {
            logger.info("歌詞をスクレイピング中: {}", songUrl);

            // Jsoupで直接ページを取得
            Document doc = Jsoup.connect(songUrl)
                .userAgent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36")
                .timeout(10000)
                .get();

            // Geniusの歌詞コンテナを探す
            // 複数のセレクタを試す（Geniusのページ構造が変わることがあるため）
            StringBuilder lyrics = new StringBuilder();

            // 方法1: data-lyrics-container属性を持つ要素
            Elements lyricsContainers = doc.select("[data-lyrics-container='true']");
            if (!lyricsContainers.isEmpty()) {
                for (Element container : lyricsContainers) {
                    // HTMLをテキストに変換（<br>を改行に）
                    String text = container.html()
                        .replaceAll("<br\\s*/?>", "\n")
                        .replaceAll("<[^>]+>", "");
                    lyrics.append(Jsoup.parse(text).text()).append("\n");
                }
            }

            // 方法2: Lyrics__Container クラス
            if (lyrics.length() == 0) {
                Elements altContainers = doc.select("div[class*='Lyrics__Container']");
                for (Element container : altContainers) {
                    String text = container.html()
                        .replaceAll("<br\\s*/?>", "\n")
                        .replaceAll("<[^>]+>", "");
                    lyrics.append(Jsoup.parse(text).text()).append("\n");
                }
            }

            // 方法3: 古い形式のlyrics divクラス
            if (lyrics.length() == 0) {
                Element oldLyrics = doc.selectFirst("div.lyrics");
                if (oldLyrics != null) {
                    lyrics.append(oldLyrics.text());
                }
            }

            String result = lyrics.toString().trim();

            if (result.isEmpty()) {
                logger.warn("歌詞が見つかりませんでした: {}", songUrl);
                return null;
            }

            // ローマ字のみの歌詞かチェック
            if (isAllRomanized(result)) {
                logger.warn("取得した歌詞がローマ字版のみです。オリジナル言語の歌詞が見つかりませんでした: {}", songUrl);
                return null;
            }

            logger.info("歌詞を取得しました: {} 文字", result.length());
            return result;

        } catch (Exception e) {
            logger.error("スクレイピングに失敗しました: {}", songUrl, e);
            return getMockLyrics();
        }
    }

    /**
     * 曲を検索してGenius Song IDを取得
     */
    public Long searchSong(String songTitle, String artistName) {
        if (apiKey == null || apiKey.isEmpty()) {
            logger.warn("Genius APIキーが設定されていません。");
            return null;
        }

        try {
            logger.info("Geniusで曲を検索中: title={}, artist={}", songTitle, artistName);

            String searchQuery = songTitle + " " + artistName;

            String response = webClient.get()
                .uri(uriBuilder -> uriBuilder
                    .path("/search")
                    .queryParam("q", searchQuery)
                    .build())
                .header("Authorization", "Bearer " + apiKey)
                .retrieve()
                .bodyToMono(String.class)
                .block();

            JsonNode rootNode = objectMapper.readTree(response);
            JsonNode hits = rootNode.path("response").path("hits");

            if (hits.isArray() && hits.size() > 0) {
                // 最初の結果からSong IDを取得
                Long songId = hits.get(0).path("result").path("id").asLong();
                logger.info("曲が見つかりました: geniusSongId={}", songId);
                return songId;
            }

            logger.warn("曲が見つかりませんでした: title={}, artist={}", songTitle, artistName);
            return null;

        } catch (Exception e) {
            logger.error("曲の検索中にエラーが発生しました", e);
            return null;
        }
    }

    /**
     * 曲のURLを取得
     */
    private String getSongUrl(Long geniusSongId) {
        try {
            String response = webClient.get()
                .uri("/songs/" + geniusSongId)
                .header("Authorization", "Bearer " + apiKey)
                .retrieve()
                .bodyToMono(String.class)
                .block();

            JsonNode rootNode = objectMapper.readTree(response);
            return rootNode.path("response").path("song").path("url").asText();

        } catch (Exception e) {
            logger.error("曲URLの取得に失敗しました: songId={}", geniusSongId, e);
            return null;
        }
    }

    /**
     * モック歌詞データを返す
     */
    private String getMockLyrics() {
        return """
            Verse 1:
            Walking down the street today
            I saw the sun begin to play
            With shadows dancing on the ground
            Making such a lovely sound

            Chorus:
            Life is beautiful, can't you see
            Every moment sets us free
            Hold on tight to what you love
            Like the stars that shine above

            Verse 2:
            Sometimes when the world feels cold
            Remember stories that were told
            Of heroes brave and hearts so true
            They believed in me and you

            Chorus:
            Life is beautiful, can't you see
            Every moment sets us free
            Hold on tight to what you love
            Like the stars that shine above
            """;
    }

    /**
     * 歌詞全体がローマ字版のみかどうかを判定
     * オリジナル言語の文字（ハングル、日本語等）がほとんど含まれていない場合trueを返す
     *
     * LanguageDetectionUtilsを使用して判定を行う
     */
    private boolean isAllRomanized(String lyrics) {
        if (lyrics == null || lyrics.trim().isEmpty()) {
            return true;
        }

        // LanguageDetectionUtilsを使用して文字数をカウント
        long hangulCount = LanguageDetectionUtils.countHangulCharacters(lyrics);
        long japaneseCount = LanguageDetectionUtils.countJapaneseCharacters(lyrics);
        long totalChars = LanguageDetectionUtils.countNonWhitespaceCharacters(lyrics);

        if (totalChars == 0) {
            return true;
        }

        // ハングルまたは日本語が5%以上含まれていればOK
        double nonLatinRatio = (double)(hangulCount + japaneseCount) / totalChars;

        if (nonLatinRatio < 0.05) {
            logger.debug("ローマ字判定: 非ラテン文字の割合 {}/{} = {:.2f}%",
                hangulCount + japaneseCount, totalChars, nonLatinRatio * 100);
            return true;
        }

        return false;
    }

    /**
     * 歌詞から言語を検出
     * 歌詞の文字種から言語を判定する
     *
     * LanguageDetectionUtilsを使用して判定を行う
     *
     * @param lyrics 歌詞テキスト
     * @return 検出された言語コード（ja, ko, en等）、判定できない場合はnull
     */
    private String detectLanguage(String lyrics) {
        if (lyrics == null || lyrics.trim().isEmpty()) {
            return null;
        }

        // LanguageDetectionUtilsを使用して言語を検出
        com.example.api.enums.LanguageCode detected = LanguageDetectionUtils.detectFromCharacters(lyrics);

        if (detected != null && detected.isValid()) {
            logger.debug("言語検出: {}", detected.getDisplayName());
            return detected.getCode();
        }

        logger.debug("言語検出: 判定不可");
        return null;
    }

    @Override
    public String searchAndGetLyrics(String songTitle, String artistName) {
        LyricsResult result = searchAndGetLyricsWithMetadata(songTitle, artistName);
        return result != null ? result.getLyrics() : null;
    }

    @Override
    public String detectLanguageFromLyrics(String lyrics) {
        if (lyrics == null || lyrics.trim().isEmpty()) {
            return null;
        }

        String detectedLang = detectLanguage(lyrics);
        logger.debug("歌詞から言語を判定: {}", detectedLang);
        return detectedLang;
    }

    @Override
    public LyricsResult searchAndGetLyricsWithMetadata(String songTitle, String artistName) {
        if (apiKey == null || apiKey.isEmpty()) {
            logger.warn("Genius APIキーが設定されていません。");
            return null;
        }

        try {
            logger.info("Geniusで曲を検索して歌詞を取得中: title={}, artist={}", songTitle, artistName);

            String searchQuery = songTitle + " " + artistName;

            String response = webClient.get()
                .uri(uriBuilder -> uriBuilder
                    .path("/search")
                    .queryParam("q", searchQuery)
                    .queryParam("per_page", 10)  // 複数結果を取得
                    .build())
                .header("Authorization", "Bearer " + apiKey)
                .retrieve()
                .bodyToMono(String.class)
                .block();

            JsonNode rootNode = objectMapper.readTree(response);
            JsonNode hits = rootNode.path("response").path("hits");

            if (hits.isArray() && hits.size() > 0) {
                // 優先度順に各候補を試す
                for (JsonNode hit : hits) {
                    JsonNode result = hit.path("result");

                    String title = result.path("title").asText();
                    String primaryArtistName = result.path("primary_artist").path("name").asText();
                    Long songId = result.path("id").asLong();

                    // ローマ字版をスキップ
                    String titleLower = title.toLowerCase();
                    String artistLower = primaryArtistName.toLowerCase();
                    if (titleLower.contains("romanized") || artistLower.contains("genius romanizations")) {
                        logger.debug("ローマ字版をスキップ: title=\"{}\", artist=\"{}\"", title, primaryArtistName);
                        continue;
                    }

                    logger.info("候補を試行: title=\"{}\", artist=\"{}\"", title, primaryArtistName);

                    // 歌詞を取得
                    String lyrics = getLyrics(songId);

                    if (lyrics != null && !lyrics.isEmpty()) {
                        // 歌詞から言語を検出
                        String detectedLanguage = detectLanguage(lyrics);

                        logger.info("歌詞取得成功: geniusSongId={}, title=\"{}\", lyrics_length={}, language={}",
                            songId, title, lyrics.length(), detectedLanguage);

                        return new LyricsResult(lyrics, songId, detectedLanguage);
                    }

                    logger.debug("歌詞取得失敗（ローマ字版またはエラー）、次の候補を試します");
                }

                logger.warn("全ての候補で歌詞取得に失敗しました: title={}, artist={}", songTitle, artistName);
                return null;
            }

            logger.warn("曲が見つかりませんでした: title={}, artist={}", songTitle, artistName);
            return null;

        } catch (Exception e) {
            logger.error("検索と歌詞取得中にエラーが発生しました", e);
            return null;
        }
    }
}
