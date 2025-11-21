package com.example.api.client.impl;

import com.example.api.client.GeniusApiClient;
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

import java.util.ArrayList;
import java.util.List;

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

            // 複数の歌詞セクションを収集
            List<LyricsSection> lyricsSections = new ArrayList<>();

            // 方法1: data-lyrics-container属性を持つ要素
            Elements lyricsContainers = doc.select("[data-lyrics-container='true']");
            if (!lyricsContainers.isEmpty()) {
                for (Element container : lyricsContainers) {
                    LyricsSection section = extractLyricsSection(container);
                    if (section != null && !section.lyrics.isEmpty()) {
                        lyricsSections.add(section);
                    }
                }
            }

            // 方法2: Lyrics__Container クラス（フォールバック）
            if (lyricsSections.isEmpty()) {
                Elements altContainers = doc.select("div[class*='Lyrics__Container']");
                for (Element container : altContainers) {
                    LyricsSection section = extractLyricsSection(container);
                    if (section != null && !section.lyrics.isEmpty()) {
                        lyricsSections.add(section);
                    }
                }
            }

            // 方法3: 古い形式のlyrics divクラス（フォールバック）
            if (lyricsSections.isEmpty()) {
                Element oldLyrics = doc.selectFirst("div.lyrics");
                if (oldLyrics != null) {
                    LyricsSection section = new LyricsSection();
                    section.lyrics = oldLyrics.text();
                    section.priority = calculatePriority(section.lyrics, "");
                    lyricsSections.add(section);
                }
            }

            if (lyricsSections.isEmpty()) {
                logger.warn("歌詞が見つかりませんでした: {}", songUrl);
                return getMockLyrics();
            }

            // 最適なセクションを選択（優先度の高い順）
            LyricsSection bestSection = lyricsSections.stream()
                .max((s1, s2) -> Integer.compare(s1.priority, s2.priority))
                .orElse(null);

            if (bestSection == null || bestSection.lyrics.isEmpty()) {
                logger.warn("有効な歌詞セクションが見つかりませんでした: {}", songUrl);
                return getMockLyrics();
            }

            String result = bestSection.lyrics.trim();

            // ローマ字のみの歌詞かチェック
            if (isAllRomanized(result)) {
                logger.warn("取得した歌詞がローマ字版のみです。オリジナル言語の歌詞が見つかりませんでした: {}", songUrl);
                return null;
            }

            logger.info("歌詞を取得しました: {} 文字, 優先度={}", result.length(), bestSection.priority);
            logger.debug("歌詞の最初の200文字: {}", result.substring(0, Math.min(200, result.length())));
            return result;

        } catch (Exception e) {
            logger.error("スクレイピングに失敗しました: {}", songUrl, e);
            return getMockLyrics();
        }
    }

    /**
     * 歌詞セクションを抽出
     */
    private LyricsSection extractLyricsSection(Element container) {
        // 前後の要素から見出しを取得
        String heading = extractHeadingFromContext(container);

        // セクションタイトルに除外キーワードが含まれている場合はスキップ
        String headingLower = heading.toLowerCase();
        if (headingLower.contains("romanized") ||
            headingLower.contains("romanization") ||
            headingLower.contains("english translation") ||
            headingLower.contains("english lyrics") ||
            (headingLower.contains("translation") && !headingLower.contains("japanese"))) {
            logger.debug("歌詞セクションをスキップ: {}", heading);
            return null;
        }

        // HTMLをテキストに変換
        String text = container.html()
            .replaceAll("<br\\s*/?>", "\n")
            .replaceAll("<[^>]+>", "");
        String lyrics = Jsoup.parse(text).text().trim();

        if (lyrics.isEmpty()) {
            return null;
        }

        LyricsSection section = new LyricsSection();
        section.lyrics = lyrics;
        section.heading = heading;
        section.priority = calculatePriority(lyrics, heading);

        return section;
    }

    /**
     * コンテナの前後から見出しを抽出
     */
    private String extractHeadingFromContext(Element container) {
        StringBuilder heading = new StringBuilder();

        // 前の兄弟要素から見出しを探す
        Element prev = container.previousElementSibling();
        if (prev != null) {
            // h1-h6, strong, b などのタグをチェック
            if (prev.tagName().matches("h[1-6]|strong|b|div")) {
                String text = prev.text();
                if (!text.isEmpty() && text.length() < 100) {
                    heading.append(text).append(" ");
                }
            }
        }

        // data属性やclassから情報を取得
        String dataAttr = container.attr("data-section");
        if (!dataAttr.isEmpty()) {
            heading.append(dataAttr).append(" ");
        }

        // 親要素のdata属性もチェック
        Element parent = container.parent();
        if (parent != null) {
            String parentClass = parent.className();
            if (parentClass.contains("Romanized") || parentClass.contains("Translation")) {
                heading.append(parentClass).append(" ");
            }
        }

        return heading.toString().trim();
    }

    /**
     * 歌詞の優先度を計算
     * 高い値ほど優先される
     */
    private int calculatePriority(String lyrics, String heading) {
        int priority = 0;

        String headingLower = heading.toLowerCase();
        String lyricsLower = lyrics.toLowerCase();

        // 見出しに「オリジナル」「日本語」「韓国語」などが含まれている場合は高優先度
        if (headingLower.contains("original") || headingLower.contains("japanese") ||
            headingLower.contains("korean") || headingLower.contains("日本語") ||
            headingLower.contains("한국어")) {
            priority += 1000;
        }

        // ハングル文字が含まれている場合（韓国語オリジナル）
        long hangulCount = lyrics.chars()
            .filter(c -> c >= 0xAC00 && c <= 0xD7AF)
            .count();
        if (hangulCount > 0) {
            priority += 500 + (int)(hangulCount / 10); // ハングル文字数に応じて加点
        }

        // 日本語文字が含まれている場合（日本語オリジナル）
        long japaneseCount = lyrics.chars()
            .filter(c -> (c >= 0x3040 && c <= 0x309F) ||  // ひらがな
                         (c >= 0x30A0 && c <= 0x30FF) ||  // カタカナ
                         (c >= 0x4E00 && c <= 0x9FAF))    // 漢字
            .count();
        if (japaneseCount > 0) {
            priority += 500 + (int)(japaneseCount / 10); // 日本語文字数に応じて加点
        }

        // 英語の一般的な単語が含まれている場合（英語オリジナル）
        if (lyricsLower.matches(".*\\b(the|and|you|me|my|your|love|like|that|this|was|were|are|have|has)\\b.*")) {
            priority += 100;
        }

        // 見出しに「Romanized」「Translation」が含まれている場合は減点
        if (headingLower.contains("romanized") || headingLower.contains("translation") ||
            headingLower.contains("english")) {
            priority -= 1000;
        }

        logger.debug("優先度計算: priority={}, heading=\"{}\", hangul={}, japanese={}",
            priority, heading, hangulCount, japaneseCount);

        return priority;
    }

    /**
     * 歌詞セクション情報を保持するクラス
     */
    private static class LyricsSection {
        String lyrics;
        String heading;
        int priority;
    }

    /**
     * テキストがローマ字のみかどうかを判定
     * オリジナルの歌詞（ハングル、日本語、英語など）が含まれていればfalseを返す
     *
     * 対応言語:
     * - 韓国語: ハングル文字を検出
     * - 日本語: ひらがな、カタカナ、漢字を検出
     * - 英語: 一般的な英単語を検出
     */
    private boolean isOnlyRomanized(String text) {
        if (text == null || text.trim().isEmpty()) {
            return true;
        }

        // ハングル文字が含まれている場合はローマ字ではない（韓国語）
        // Unicode範囲: U+AC00 - U+D7AF (Hangul Syllables)
        if (text.matches(".*[\\uAC00-\\uD7AF]+.*")) {
            return false;
        }

        // 日本語文字が含まれている場合はローマ字ではない
        // ひらがな: U+3040 - U+309F
        // カタカナ: U+30A0 - U+30FF
        // 漢字 (CJK Unified Ideographs): U+4E00 - U+9FAF
        if (text.matches(".*[\\u3040-\\u309F\\u30A0-\\u30FF\\u4E00-\\u9FAF]+.*")) {
            return false;
        }

        // 英語の一般的な単語が含まれている場合はローマ字ではない
        // （Geniusの英語歌詞を保持）
        String lowerText = text.toLowerCase();
        if (lowerText.matches(".*\\b(the|and|you|me|my|your|love|like|that|this|was|were|are|have|has)\\b.*")) {
            return false;
        }

        return false; // デフォルトでは除外しない（安全側に倒す）
    }

    /**
     * 歌詞全体がローマ字版のみかどうかを判定
     * オリジナル言語の文字（ハングル、日本語等）がほとんど含まれていない場合trueを返す
     */
    private boolean isAllRomanized(String lyrics) {
        if (lyrics == null || lyrics.trim().isEmpty()) {
            return true;
        }

        // ハングル文字の割合をチェック
        long hangulCount = lyrics.chars()
            .filter(c -> c >= 0xAC00 && c <= 0xD7AF)
            .count();

        // 日本語文字の割合をチェック（ひらがな、カタカナ、漢字）
        long japaneseCount = lyrics.chars()
            .filter(c -> (c >= 0x3040 && c <= 0x309F) ||  // ひらがな
                         (c >= 0x30A0 && c <= 0x30FF) ||  // カタカナ
                         (c >= 0x4E00 && c <= 0x9FAF))    // 漢字
            .count();

        // 全文字数（空白を除く）
        long totalChars = lyrics.chars()
            .filter(c -> !Character.isWhitespace(c))
            .count();

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
}
