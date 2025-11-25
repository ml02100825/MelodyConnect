package com.example.api.client.impl;

import com.example.api.client.GeniusApiClient;
import com.example.api.client.SpotifyApiClient;
import com.example.api.dto.SpotifyArtistDto;
import com.example.api.entity.Song;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Primary;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;
import com.example.api.repository.*;

import java.time.Instant;
import java.util.*;

/**
 * Spotify API Client の実装
 * Client Credentials Flow による認証と楽曲検索機能を提供
 * アーティストの全曲取得機能を含む
 */
@Component
@Primary
public class SpotifyApiClientImpl implements SpotifyApiClient {
    
    @Autowired
    private SongRepository songRepository;

    private static final Logger logger = LoggerFactory.getLogger(SpotifyApiClientImpl.class);
    private static final String SPOTIFY_AUTH_URL = "https://accounts.spotify.com/api/token";
    private static final String SPOTIFY_API_URL = "https://api.spotify.com/v1";
    private static final int MAX_ALBUMS_PER_REQUEST = 50;
    private static final int MAX_TRACKS_PER_REQUEST = 50;

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

    // GeniusApiClientを遅延注入（循環依存を回避）
    private GeniusApiClient geniusApiClient;

    @org.springframework.beans.factory.annotation.Autowired
    public void setGeniusApiClient(GeniusApiClient geniusApiClient) {
        this.geniusApiClient = geniusApiClient;
    }

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
    public List<Song> getAllSongsByArtist(String spotifyArtistId) {
        if (spotifyArtistId == null || spotifyArtistId.isEmpty()) {
            logger.warn("SpotifyアーティストIDが指定されていません");
            return Collections.emptyList();
        }

        String token = getAccessToken();
        if (token == null) {
            logger.warn("トークンが取得できないため処理を中断します");
            return Collections.emptyList();
        }

        List<Song> allSongs = new ArrayList<>();
        Set<String> seenTrackIds = new HashSet<>();

        try {
            logger.info("=== アーティストの全曲取得開始 ===");
            logger.info("Spotify Artist ID: {}", spotifyArtistId);

            // ステップ1: アーティストの全アルバムを取得
            List<String> albumIds = getAllAlbumIds(spotifyArtistId, token);
            logger.info("取得したアルバム数: {}", albumIds.size());

            // ステップ2: 各アルバムから全トラックを取得
            int totalTracks = 0;
            for (String albumId : albumIds) {
                List<Song> tracksFromAlbum = getTracksFromAlbum(albumId, spotifyArtistId, token);
                
                // 重複チェック（コンピレーションアルバムなどで同じ曲が複数回出る場合がある）
                for (Song song : tracksFromAlbum) {
                    if (!seenTrackIds.contains(song.getSpotify_track_id())) {
                        allSongs.add(song);
                        seenTrackIds.add(song.getSpotify_track_id());
                        totalTracks++;
                    }
                }

                // 進捗ログ
                if (totalTracks % 50 == 0) {
                    logger.info("取得進捗: {}曲", totalTracks);
                }
            }

            logger.info("=== 全曲取得完了 ===");
            logger.info("合計楽曲数: {}", allSongs.size());
            return allSongs;

        } catch (Exception e) {
            logger.error("アーティスト {} の全曲取得に失敗しました", spotifyArtistId, e);
            return allSongs; // 部分的に取得できた曲は返す
        }
    }

    /**
     * アーティストの全アルバムIDを取得
     */
    private List<String> getAllAlbumIds(String artistId, String token) throws Exception {
        List<String> albumIds = new ArrayList<>();
        String nextUrl = null;
        int currentOffset = 0;

        do {
            // ラムダ式内で使うためにfinal変数を作成
            final int offset = currentOffset;
            
            String response = apiClient.get()
                .uri(uriBuilder -> uriBuilder
                    .path("/artists/" + artistId + "/albums")
                    .queryParam("include_groups", "album,single")  // アルバムとシングルを取得
                    .queryParam("market", "JP")
                    .queryParam("limit", MAX_ALBUMS_PER_REQUEST)
                    .queryParam("offset", offset)
                    .build())
                .header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                .retrieve()
                .bodyToMono(String.class)
                .block();

            JsonNode jsonNode = objectMapper.readTree(response);
            JsonNode items = jsonNode.path("items");

            if (items.isArray()) {
                for (JsonNode album : items) {
                    String albumId = album.path("id").asText();
                    if (albumId != null && !albumId.isEmpty()) {
                        albumIds.add(albumId);
                    }
                }
            }

            // 次のページがあるかチェック
            nextUrl = jsonNode.path("next").asText(null);
            currentOffset += MAX_ALBUMS_PER_REQUEST;

        } while (nextUrl != null && !nextUrl.isEmpty());

        return albumIds;
    }

    /**
     * アルバムから全トラックを取得
     * ページネーション対応（50曲以上のアルバムに対応）
     */
    private List<Song> getTracksFromAlbum(String albumId, String artistId, String token) {
        List<Song> songs = new ArrayList<>();
        int currentOffset = 0;
        boolean hasMore = true;

        try {
            while (hasMore) {
                // ラムダ式内で使うためにfinal変数を作成
                final int offset = currentOffset;
                
                String response = apiClient.get()
                    .uri(uriBuilder -> uriBuilder
                        .path("/albums/" + albumId + "/tracks")
                        .queryParam("market", "JP")
                        .queryParam("limit", MAX_TRACKS_PER_REQUEST)
                        .queryParam("offset", offset)
                        .build())
                    .header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                    .retrieve()
                    .bodyToMono(String.class)
                    .block();

                JsonNode jsonNode = objectMapper.readTree(response);
                JsonNode items = jsonNode.path("items");

                if (items.isArray()) {
                    for (JsonNode track : items) {
                        Song song = parseTrackToSong(track);
                        if (song != null) {
                            songs.add(song);
                        }
                    }
                    
                    // 次のページがあるかチェック
                    String nextUrl = jsonNode.path("next").asText(null);
                    hasMore = (nextUrl != null && !nextUrl.isEmpty());
                    currentOffset += MAX_TRACKS_PER_REQUEST;
                } else {
                    hasMore = false;
                }
            }

        } catch (Exception e) {
            logger.warn("アルバム {} からのトラック取得に失敗: {}", albumId, e.getMessage());
        }

        return songs;
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
            // アーティストのトップトラックを取得してランダムに1曲返す
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

        String songName = trackNode.path("name").asText();
        song.setSongname(songName);
        song.setSpotify_track_id(trackNode.path("id").asText());

        // アーティスト情報
        String artistApiId = null;
        JsonNode artists = trackNode.path("artists");
        if (artists.isArray() && artists.size() > 0) {
            artistApiId = artists.get(0).path("id").asText();
            // アーティスト情報を一時フィールドに保存
            song.setTempArtistApiId(artistApiId);
            // Note: artist_idは後で設定される
            song.setAritst_id(0L); // プレースホルダー
        }

        // ジャンルはトラックレベルでは取得できないため、デフォルト設定
        song.setGenre(null);
        // 言語はSpotify APIから取得できないため、nullに設定（歌詞取得時に判定）
        song.setLanguage(null);

        // Genius Song IDは問題生成時に動的に検索するため、ここでは設定しない
        // （SpotifyApiClientで事前に検索すると、間違ったIDを設定してしまう可能性があるため）
        song.setGenius_song_id(null);

        logger.debug("Spotify楽曲をパース: {} (ID: {})", song.getSongname(), song.getSpotify_track_id());
        return song;
    }

    /**
     * モック楽曲データを作成
     */
    private Song createMockSong(String genre) {
        Song song = new Song();
        song.setSongname("Mock Song - " + System.currentTimeMillis());
        song.setSpotify_track_id("mock_" + System.currentTimeMillis());
        song.setGenius_song_id(null);  // 歌詞取得時に設定
        song.setGenre(genre);
        song.setLanguage(null);  // 歌詞取得時に判定
        song.setAritst_id(1L);
        return song;
    }
}
