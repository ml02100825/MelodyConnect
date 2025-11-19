package com.example.api.client.impl;

import com.example.api.client.SpotifyApiClient;
import com.example.api.dto.SpotifyArtistDto;
import com.example.api.entity.Song;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Primary;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;

import java.time.Instant;
import java.util.ArrayList;
import java.util.Base64;
import java.util.List;
import java.util.Random;

/**
 * Spotify API Client の実装
 * Client Credentials Flow による認証と楽曲検索機能を提供
 */
@Component
@Primary
public class SpotifyApiClientImpl implements SpotifyApiClient {

    private static final Logger logger = LoggerFactory.getLogger(SpotifyApiClientImpl.class);
    private static final String SPOTIFY_AUTH_URL = "https://accounts.spotify.com/api/token";
    private static final String SPOTIFY_API_URL = "https://api.spotify.com/v1";

    private final WebClient authClient;
    private final WebClient apiClient;
    private final ObjectMapper objectMapper;
    private final Random random = new Random();

    @Value("${spotify.client.id:}")
    private String clientId;

    @Value("${spotify.client.secret:}")
    private String clientSecret;

    private String accessToken;
    private Instant tokenExpiry;

    public SpotifyApiClientImpl(ObjectMapper objectMapper) {
        this.objectMapper = objectMapper;
        this.authClient = WebClient.builder()
            .baseUrl(SPOTIFY_AUTH_URL)
            .build();
        this.apiClient = WebClient.builder()
            .baseUrl(SPOTIFY_API_URL)
            .defaultHeader(HttpHeaders.CONTENT_TYPE, MediaType.APPLICATION_JSON_VALUE)
            .build();
    }

    /**
     * アクセストークンを取得（Client Credentials Flow）
     */
    private synchronized String getAccessToken() {
        if (accessToken != null && tokenExpiry != null && Instant.now().isBefore(tokenExpiry)) {
            return accessToken;
        }

        if (clientId == null || clientId.isEmpty() || clientSecret == null || clientSecret.isEmpty()) {
            logger.warn("Spotify API認証情報が設定されていません");
            return null;
        }

        try {
            String credentials = Base64.getEncoder().encodeToString(
                (clientId + ":" + clientSecret).getBytes()
            );

            String response = authClient.post()
                .header(HttpHeaders.AUTHORIZATION, "Basic " + credentials)
                .header(HttpHeaders.CONTENT_TYPE, MediaType.APPLICATION_FORM_URLENCODED_VALUE)
                .bodyValue("grant_type=client_credentials")
                .retrieve()
                .bodyToMono(String.class)
                .block();

            JsonNode jsonNode = objectMapper.readTree(response);
            accessToken = jsonNode.path("access_token").asText();
            int expiresIn = jsonNode.path("expires_in").asInt(3600);
            tokenExpiry = Instant.now().plusSeconds(expiresIn - 60); // 60秒のバッファ

            logger.info("Spotify アクセストークンを取得しました");
            return accessToken;

        } catch (Exception e) {
            logger.error("Spotify アクセストークンの取得に失敗しました", e);
            return null;
        }
    }

    @Override
    public Song getRandomSongByArtist(Integer artistId) {
        // TODO: artistIdからSpotifyのアーティストIDにマッピングが必要
        // 現時点ではランダム検索にフォールバック
        logger.info("アーティストID {} から楽曲を検索", artistId);
        return getRandomSong();
    }

    @Override
    public Song getRandomSongBySpotifyArtistId(String spotifyArtistId) {
        if (spotifyArtistId == null || spotifyArtistId.isEmpty()) {
            logger.warn("SpotifyアーティストIDが指定されていません");
            return getRandomSong();
        }

        String token = getAccessToken();
        if (token == null) {
            logger.warn("トークンが取得できないためモックデータを返します");
            return createMockSong("pop");
        }

        try {
            // アーティストのトップトラックを取得
            String response = apiClient.get()
                .uri(uriBuilder -> uriBuilder
                    .path("/artists/" + spotifyArtistId + "/top-tracks")
                    .queryParam("market", "JP")
                    .build())
                .header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                .retrieve()
                .bodyToMono(String.class)
                .block();

            JsonNode jsonNode = objectMapper.readTree(response);
            JsonNode tracks = jsonNode.path("tracks");

            if (tracks.isArray() && tracks.size() > 0) {
                // ランダムにトラックを選択
                int randomIndex = random.nextInt(tracks.size());
                Song song = parseTrackToSong(tracks.get(randomIndex));
                logger.info("アーティスト {} の楽曲を取得: {}", spotifyArtistId, song.getSongname());
                return song;
            }

            logger.warn("アーティスト {} のトップトラックが見つかりませんでした", spotifyArtistId);
            return getRandomSong();

        } catch (Exception e) {
            logger.error("アーティスト {} の楽曲検索に失敗しました", spotifyArtistId, e);
            return getRandomSong();
        }
    }

    @Override
    public Song getRandomSongByGenre(String genreName) {
        String token = getAccessToken();
        if (token == null) {
            logger.warn("トークンが取得できないためモックデータを返します");
            return createMockSong(genreName);
        }

        try {
            // ジャンルで検索
            String query = "genre:" + genreName;
            return searchAndSelectRandom(query, token);
        } catch (Exception e) {
            logger.error("ジャンル {} での検索に失敗しました", genreName, e);
            return createMockSong(genreName);
        }
    }

    @Override
    public Song getRandomSong() {
        String token = getAccessToken();
        if (token == null) {
            logger.warn("トークンが取得できないためモックデータを返します");
            return createMockSong("pop");
        }

        try {
            // ランダムな文字で検索（より多様な結果を得るため）
            String[] randomQueries = {"a", "e", "i", "o", "u", "love", "life", "heart", "dream", "night"};
            String query = randomQueries[random.nextInt(randomQueries.length)];
            return searchAndSelectRandom(query, token);
        } catch (Exception e) {
            logger.error("ランダム楽曲の検索に失敗しました", e);
            return createMockSong("pop");
        }
    }

    @Override
    public Song searchSong(String songName, String artistName) {
        String token = getAccessToken();
        if (token == null) {
            logger.warn("トークンが取得できないためモックデータを返します");
            return createMockSong("pop");
        }

        try {
            String query = String.format("track:%s artist:%s", songName, artistName);

            String response = apiClient.get()
                .uri(uriBuilder -> uriBuilder
                    .path("/search")
                    .queryParam("q", query)
                    .queryParam("type", "track")
                    .queryParam("limit", 1)
                    .build())
                .header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                .retrieve()
                .bodyToMono(String.class)
                .block();

            JsonNode jsonNode = objectMapper.readTree(response);
            JsonNode tracks = jsonNode.path("tracks").path("items");

            if (tracks.isArray() && tracks.size() > 0) {
                return parseTrackToSong(tracks.get(0));
            }

            logger.warn("楽曲が見つかりませんでした: {} - {}", songName, artistName);
            return createMockSong("pop");

        } catch (Exception e) {
            logger.error("楽曲検索に失敗しました: {} - {}", songName, artistName, e);
            return createMockSong("pop");
        }
    }

    @Override
    public List<SpotifyArtistDto> searchArtists(String query, int limit) {
        String token = getAccessToken();
        if (token == null) {
            logger.warn("トークンが取得できないためモックデータを返します");
            return createMockArtists(query);
        }

        try {
            String response = apiClient.get()
                .uri(uriBuilder -> uriBuilder
                    .path("/search")
                    .queryParam("q", query)
                    .queryParam("type", "artist")
                    .queryParam("limit", limit)
                    .build())
                .header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                .retrieve()
                .bodyToMono(String.class)
                .block();

            JsonNode jsonNode = objectMapper.readTree(response);
            JsonNode artists = jsonNode.path("artists").path("items");

            List<SpotifyArtistDto> result = new ArrayList<>();
            if (artists.isArray()) {
                for (JsonNode artistNode : artists) {
                    SpotifyArtistDto dto = parseArtistNode(artistNode);
                    if (dto != null) {
                        result.add(dto);
                    }
                }
            }

            logger.info("Spotifyアーティスト検索完了: query={}, 結果数={}", query, result.size());
            return result;

        } catch (Exception e) {
            logger.error("アーティスト検索に失敗しました: query={}", query, e);
            return createMockArtists(query);
        }
    }

    /**
     * SpotifyのアーティストJSONをDTOに変換
     */
    private SpotifyArtistDto parseArtistNode(JsonNode artistNode) {
        try {
            String imageUrl = null;
            JsonNode images = artistNode.path("images");
            if (images.isArray() && images.size() > 0) {
                // 最初の画像（通常は最大サイズ）を使用
                imageUrl = images.get(0).path("url").asText();
            }

            List<String> genres = new ArrayList<>();
            JsonNode genresNode = artistNode.path("genres");
            if (genresNode.isArray()) {
                for (JsonNode genre : genresNode) {
                    genres.add(genre.asText());
                }
            }

            return SpotifyArtistDto.builder()
                .spotifyId(artistNode.path("id").asText())
                .name(artistNode.path("name").asText())
                .imageUrl(imageUrl)
                .genres(genres)
                .popularity(artistNode.path("popularity").asInt())
                .build();
        } catch (Exception e) {
            logger.warn("アーティストノードのパースに失敗しました", e);
            return null;
        }
    }

    /**
     * モックアーティストデータを作成
     */
    private List<SpotifyArtistDto> createMockArtists(String query) {
        List<SpotifyArtistDto> mockList = new ArrayList<>();
        mockList.add(SpotifyArtistDto.builder()
            .spotifyId("mock_artist_1")
            .name("Mock Artist 1 - " + query)
            .imageUrl(null)
            .genres(List.of("pop"))
            .popularity(50)
            .build());
        return mockList;
    }

    @Override
    public List<SpotifyArtistDto> getPopularArtists(int limit) {
        String token = getAccessToken();
        if (token == null) {
            logger.warn("トークンが取得できないためモックデータを返します");
            return createMockArtists("popular");
        }

        List<SpotifyArtistDto> allArtists = new ArrayList<>();
        // 様々なジャンルから人気アーティストを取得
        String[] genres = {"pop", "rock", "hip-hop", "r-n-b", "k-pop", "j-pop", "latin", "electronic", "country", "jazz"};

        try {
            int perGenre = Math.max(1, limit / genres.length);

            for (String genre : genres) {
                if (allArtists.size() >= limit) break;

                String response = apiClient.get()
                    .uri(uriBuilder -> uriBuilder
                        .path("/search")
                        .queryParam("q", "genre:" + genre)
                        .queryParam("type", "artist")
                        .queryParam("limit", perGenre)
                        .build())
                    .header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                    .retrieve()
                    .bodyToMono(String.class)
                    .block();

                JsonNode jsonNode = objectMapper.readTree(response);
                JsonNode artists = jsonNode.path("artists").path("items");

                if (artists.isArray()) {
                    for (JsonNode artistNode : artists) {
                        if (allArtists.size() >= limit) break;

                        SpotifyArtistDto dto = parseArtistNode(artistNode);
                        if (dto != null && dto.getPopularity() >= 50) { // 人気度50以上
                            // 重複チェック
                            boolean isDuplicate = allArtists.stream()
                                .anyMatch(a -> a.getSpotifyId().equals(dto.getSpotifyId()));
                            if (!isDuplicate) {
                                allArtists.add(dto);
                            }
                        }
                    }
                }
            }

            logger.info("人気アーティストを取得しました: count={}", allArtists.size());
            return allArtists;

        } catch (Exception e) {
            logger.error("人気アーティストの取得に失敗しました", e);
            return createMockArtists("popular");
        }
    }

    /**
     * 検索してランダムに1曲選択
     */
    private Song searchAndSelectRandom(String query, String token) throws Exception {
        int offset = random.nextInt(100); // ランダムなオフセット

        String response = apiClient.get()
            .uri(uriBuilder -> uriBuilder
                .path("/search")
                .queryParam("q", query)
                .queryParam("type", "track")
                .queryParam("limit", 20)
                .queryParam("offset", offset)
                .build())
            .header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
            .retrieve()
            .bodyToMono(String.class)
            .block();

        JsonNode jsonNode = objectMapper.readTree(response);
        JsonNode tracks = jsonNode.path("tracks").path("items");

        if (tracks.isArray() && tracks.size() > 0) {
            int randomIndex = random.nextInt(tracks.size());
            return parseTrackToSong(tracks.get(randomIndex));
        }

        throw new RuntimeException("検索結果が空でした");
    }

    /**
     * SpotifyのトラックJSONをSongエンティティに変換
     */
    private Song parseTrackToSong(JsonNode trackNode) {
        Song song = new Song();

        song.setSongname(trackNode.path("name").asText());
        song.setSpotify_track_id(trackNode.path("id").asText());

        // アーティスト情報
        JsonNode artists = trackNode.path("artists");
        if (artists.isArray() && artists.size() > 0) {
            String artistName = artists.get(0).path("name").asText();
            // Note: アーティストIDは別途マッピングが必要
            song.setAritst_id(0L); // プレースホルダー
        }

        // ジャンルはトラックレベルでは取得できないため、デフォルト設定
        song.setGenre("pop");
        song.setLanguage("en");

        logger.info("Spotify楽曲を取得: {} (ID: {})", song.getSongname(), song.getSpotify_track_id());
        return song;
    }

    /**
     * モック楽曲データを作成
     */
    private Song createMockSong(String genre) {
        Song song = new Song();
        song.setSongname("Mock Song - " + System.currentTimeMillis());
        song.setSpotify_track_id("mock_" + System.currentTimeMillis());
        song.setGenius_song_id(12345L);
        song.setGenre(genre);
        song.setLanguage("en");
        song.setAritst_id(1L);
        return song;
    }
}
