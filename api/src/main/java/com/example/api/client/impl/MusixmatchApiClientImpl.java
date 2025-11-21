package com.example.api.client.impl;

import com.example.api.client.MusixmatchApiClient;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;

/**
 * Musixmatch API Client の実装
 * Musixmatch APIを使用して歌詞を取得（Geniusのフォールバック）
 */
@Component
public class MusixmatchApiClientImpl implements MusixmatchApiClient {

    private static final Logger logger = LoggerFactory.getLogger(MusixmatchApiClientImpl.class);
    private static final String MUSIXMATCH_API_URL = "https://api.musixmatch.com/ws/1.1";

    private final WebClient webClient;
    private final ObjectMapper objectMapper;

    @Value("${musixmatch.api.key:}")
    private String apiKey;

    public MusixmatchApiClientImpl(ObjectMapper objectMapper) {
        this.objectMapper = objectMapper;
        this.webClient = WebClient.builder()
            .baseUrl(MUSIXMATCH_API_URL)
            .build();
    }

    @Override
    public String getLyrics(String artistName, String trackName) {
        if (apiKey == null || apiKey.isEmpty()) {
            logger.warn("Musixmatch APIキーが設定されていません");
            return null;
        }

        try {
            logger.info("Musixmatchで歌詞を検索中: artist={}, track={}", artistName, trackName);

            // 1. 曲を検索してTrack IDを取得
            Long trackId = searchTrack(artistName, trackName);
            if (trackId == null) {
                logger.warn("Musixmatchで曲が見つかりませんでした: artist={}, track={}", artistName, trackName);
                return null;
            }

            // 2. Track IDから歌詞を取得
            return getLyricsByTrackId(trackId);

        } catch (Exception e) {
            logger.error("Musixmatch APIでエラーが発生しました: artist={}, track={}", artistName, trackName, e);
            return null;
        }
    }

    @Override
    public String getLyricsByTrackId(Long trackId) {
        if (apiKey == null || apiKey.isEmpty()) {
            logger.warn("Musixmatch APIキーが設定されていません");
            return null;
        }

        try {
            logger.info("Musixmatchから歌詞を取得中: trackId={}", trackId);

            String response = webClient.get()
                .uri(uriBuilder -> uriBuilder
                    .path("/track.lyrics.get")
                    .queryParam("apikey", apiKey)
                    .queryParam("track_id", trackId)
                    .build())
                .retrieve()
                .bodyToMono(String.class)
                .block();

            JsonNode rootNode = objectMapper.readTree(response);

            // ステータスコードをチェック
            int statusCode = rootNode.path("message").path("header").path("status_code").asInt();
            if (statusCode != 200) {
                logger.warn("Musixmatch API エラー: status_code={}, trackId={}", statusCode, trackId);
                return null;
            }

            // 歌詞を取得
            String lyrics = rootNode
                .path("message")
                .path("body")
                .path("lyrics")
                .path("lyrics_body")
                .asText();

            if (lyrics == null || lyrics.isEmpty() || lyrics.equals("null")) {
                logger.warn("歌詞が見つかりませんでした: trackId={}", trackId);
                return null;
            }

            // Musixmatchの制限メッセージを削除
            // "******* This Lyrics is NOT for Commercial use *******" などのメッセージを削除
            lyrics = lyrics.replaceAll("\\*{7}.*?\\*{7}", "").trim();

            logger.info("Musixmatchから歌詞を取得しました: {} 文字", lyrics.length());
            return lyrics;

        } catch (Exception e) {
            logger.error("歌詞の取得中にエラーが発生しました: trackId={}", trackId, e);
            return null;
        }
    }

    /**
     * 曲を検索してTrack IDを取得
     */
    private Long searchTrack(String artistName, String trackName) {
        try {
            String response = webClient.get()
                .uri(uriBuilder -> uriBuilder
                    .path("/track.search")
                    .queryParam("apikey", apiKey)
                    .queryParam("q_artist", artistName)
                    .queryParam("q_track", trackName)
                    .queryParam("page_size", 1)
                    .queryParam("s_track_rating", "desc")
                    .build())
                .retrieve()
                .bodyToMono(String.class)
                .block();

            JsonNode rootNode = objectMapper.readTree(response);

            // ステータスコードをチェック
            int statusCode = rootNode.path("message").path("header").path("status_code").asInt();
            if (statusCode != 200) {
                logger.warn("Musixmatch 検索エラー: status_code={}", statusCode);
                return null;
            }

            JsonNode trackList = rootNode.path("message").path("body").path("track_list");

            if (trackList.isArray() && trackList.size() > 0) {
                Long trackId = trackList.get(0).path("track").path("track_id").asLong();
                logger.info("曲が見つかりました: trackId={}", trackId);
                return trackId;
            }

            return null;

        } catch (Exception e) {
            logger.error("曲の検索中にエラーが発生しました: artist={}, track={}", artistName, trackName, e);
            return null;
        }
    }
}
