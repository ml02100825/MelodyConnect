package com.example.api.client.impl;

import com.example.api.client.AppleMusicApiClient;
import com.example.api.entity.Artist;
import com.example.api.entity.song;
import com.example.api.repository.ArtistRepository;
import com.example.api.repository.SongRepository;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Primary;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;

import java.time.LocalDateTime;

/**
 * Apple Music API Client の実装
 * 楽曲検索とメタデータ取得のためのApple Music API統合
 */
@Component
@Primary
public class AppleMusicApiClientImpl implements AppleMusicApiClient {

    private static final Logger logger = LoggerFactory.getLogger(AppleMusicApiClientImpl.class);
    private static final String APPLE_MUSIC_API_BASE_URL = "https://api.music.apple.com/v1";

    private final WebClient webClient;
    private final ObjectMapper objectMapper;

    @Autowired
    private SongRepository songRepository;

    @Autowired
    private ArtistRepository artistRepository;

    @Value("${apple.music.api.key:}")
    private String apiKey;

    @Value("${apple.music.storefront:us}")
    private String storefront;

    public AppleMusicApiClientImpl(ObjectMapper objectMapper) {
        this.objectMapper = objectMapper;
        this.webClient = WebClient.builder()
            .baseUrl(APPLE_MUSIC_API_BASE_URL)
            .build();
    }

    @Override
    public song getRandomSongByArtist(Integer artistId) {
        if (apiKey == null || apiKey.isEmpty()) {
            logger.warn("Apple Music APIキーが設定されていません。モックデータを返します。");
            return createMockSong(artistId);
        }

        try {
            // アーティスト情報を取得
            Artist artist = artistRepository.findById(artistId).orElse(null);
            if (artist == null || artist.getArtistApiId() == null) {
                logger.warn("アーティストが見つかりません: artistId={}", artistId);
                return createMockSong(artistId);
            }

            logger.info("Apple Musicからアーティストの曲を検索中: artistApiId={}", artist.getArtistApiId());

            // アーティストの曲を取得
            String response = webClient.get()
                .uri(uriBuilder -> uriBuilder
                    .path("/catalog/{storefront}/artists/{id}/songs")
                    .queryParam("limit", 25)
                    .build(storefront, artist.getArtistApiId()))
                .header("Authorization", "Bearer " + apiKey)
                .retrieve()
                .bodyToMono(String.class)
                .block();

            return parseSongFromResponse(response, artist);

        } catch (Exception e) {
            logger.error("アーティストの曲取得中にエラーが発生しました: artistId={}", artistId, e);
            return createMockSong(artistId);
        }
    }

    @Override
    public song getRandomSongByGenre(String genreName) {
        if (apiKey == null || apiKey.isEmpty()) {
            logger.warn("Apple Music APIキーが設定されていません。モックデータを返します。");
            return createMockSongForGenre(genreName);
        }

        try {
            logger.info("Apple Musicからジャンルで曲を検索中: genre={}", genreName);

            // ジャンルで検索
            String response = webClient.get()
                .uri(uriBuilder -> uriBuilder
                    .path("/catalog/{storefront}/search")
                    .queryParam("term", genreName)
                    .queryParam("types", "songs")
                    .queryParam("limit", 25)
                    .build(storefront))
                .header("Authorization", "Bearer " + apiKey)
                .retrieve()
                .bodyToMono(String.class)
                .block();

            return parseSongFromSearchResponse(response, genreName);

        } catch (Exception e) {
            logger.error("ジャンルによる曲検索中にエラーが発生しました: genre={}", genreName, e);
            return createMockSongForGenre(genreName);
        }
    }

    @Override
    public song getRandomSong() {
        if (apiKey == null || apiKey.isEmpty()) {
            logger.warn("Apple Music APIキーが設定されていません。モックデータを返します。");
            return createMockSongForGenre("pop");
        }

        try {
            logger.info("Apple Musicからランダムな曲を検索中");

            // 人気の曲を取得
            String[] popularTerms = {"love", "life", "dream", "heart", "time"};
            String searchTerm = popularTerms[(int)(Math.random() * popularTerms.length)];

            String response = webClient.get()
                .uri(uriBuilder -> uriBuilder
                    .path("/catalog/{storefront}/search")
                    .queryParam("term", searchTerm)
                    .queryParam("types", "songs")
                    .queryParam("limit", 25)
                    .build(storefront))
                .header("Authorization", "Bearer " + apiKey)
                .retrieve()
                .bodyToMono(String.class)
                .block();

            return parseSongFromSearchResponse(response, "pop");

        } catch (Exception e) {
            logger.error("ランダム曲の取得中にエラーが発生しました", e);
            return createMockSongForGenre("pop");
        }
    }

    /**
     * APIレスポンスから曲をパース
     */
    private song parseSongFromResponse(String response, Artist artist) {
        try {
            JsonNode rootNode = objectMapper.readTree(response);
            JsonNode data = rootNode.path("data");

            if (data.isArray() && data.size() > 0) {
                // ランダムに1曲選択
                int randomIndex = (int)(Math.random() * data.size());
                JsonNode songNode = data.get(randomIndex);
                JsonNode attributes = songNode.path("attributes");

                song newSong = new song();
                newSong.setArtist(artist);
                newSong.setSongname(attributes.path("name").asText("Unknown"));
                newSong.setGenre(attributes.path("genreNames").get(0).asText("Unknown"));
                newSong.setLanguage("en");
                newSong.setCreated_at(LocalDateTime.now());

                // 保存して返す
                return songRepository.save(newSong);
            }

            return createMockSong(artist.getArtistId());

        } catch (Exception e) {
            logger.error("レスポンスのパースに失敗しました", e);
            return createMockSong(artist.getArtistId());
        }
    }

    /**
     * 検索レスポンスから曲をパース
     */
    private song parseSongFromSearchResponse(String response, String genre) {
        try {
            JsonNode rootNode = objectMapper.readTree(response);
            JsonNode songs = rootNode.path("results").path("songs").path("data");

            if (songs.isArray() && songs.size() > 0) {
                // ランダムに1曲選択
                int randomIndex = (int)(Math.random() * songs.size());
                JsonNode songNode = songs.get(randomIndex);
                JsonNode attributes = songNode.path("attributes");

                // アーティストを取得または作成
                String artistName = attributes.path("artistName").asText("Unknown Artist");
                Artist artist = findOrCreateArtist(artistName);

                song newSong = new song();
                newSong.setArtist(artist);
                newSong.setSongname(attributes.path("name").asText("Unknown"));
                newSong.setGenre(genre);
                newSong.setLanguage("en");
                newSong.setCreated_at(LocalDateTime.now());

                // 保存して返す
                return songRepository.save(newSong);
            }

            return createMockSongForGenre(genre);

        } catch (Exception e) {
            logger.error("検索レスポンスのパースに失敗しました", e);
            return createMockSongForGenre(genre);
        }
    }

    /**
     * アーティストを検索または作成
     */
    private Artist findOrCreateArtist(String artistName) {
        return artistRepository.findByArtistName(artistName)
            .orElseGet(() -> {
                Artist newArtist = new Artist();
                newArtist.setArtistName(artistName);
                newArtist.setGenreId(1); // デフォルトジャンル
                return artistRepository.save(newArtist);
            });
    }

    /**
     * モックの曲データを作成
     */
    private song createMockSong(Integer artistId) {
        Artist artist = artistRepository.findById(artistId)
            .orElseGet(() -> {
                Artist newArtist = new Artist();
                newArtist.setArtistName("Mock Artist");
                newArtist.setGenreId(1);
                return artistRepository.save(newArtist);
            });

        song mockSong = new song();
        mockSong.setArtist(artist);
        mockSong.setSongname("Mock Song Title");
        mockSong.setGenre("pop");
        mockSong.setLanguage("en");
        mockSong.setGenius_song_id(12345L);
        mockSong.setCreated_at(LocalDateTime.now());

        return songRepository.save(mockSong);
    }

    /**
     * ジャンル用のモック曲データを作成
     */
    private song createMockSongForGenre(String genre) {
        Artist artist = findOrCreateArtist("Mock Artist");

        song mockSong = new song();
        mockSong.setArtist(artist);
        mockSong.setSongname("Mock " + genre + " Song");
        mockSong.setGenre(genre);
        mockSong.setLanguage("en");
        mockSong.setGenius_song_id(12345L);
        mockSong.setCreated_at(LocalDateTime.now());

        return songRepository.save(mockSong);
    }
}
