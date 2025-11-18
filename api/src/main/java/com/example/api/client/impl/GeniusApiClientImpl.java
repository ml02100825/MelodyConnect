package com.example.api.client.impl;

import com.example.api.client.GeniusApiClient;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Primary;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;

/**
 * Genius API Client の実装
 * 歌詞を取得するためのGenius API統合
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

            // 2. Genius APIは歌詞を直接返さないため、
            // 実際の実装ではWebスクレイピングが必要
            // TODO: 本番環境では歌詞取得の別の方法を検討
            // (例: lrclib.net API, Musixmatch API など)
            logger.warn("Genius APIは歌詞を直接提供しません。スクレイピングが必要です。");
            logger.info("曲URL: {}", songUrl);

            // 現在はモックデータを返す
            return getMockLyrics();

        } catch (Exception e) {
            logger.error("歌詞の取得中にエラーが発生しました: songId={}", geniusSongId, e);
            return getMockLyrics();
        }
    }

    @Override
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
