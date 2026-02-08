package com.example.api.client.impl;

import com.example.api.client.GeniusApiClient;
import com.example.api.client.SpotifyApiClient;
import com.example.api.dto.SpotifyArtistDto;
import com.example.api.entity.Artist;
import com.example.api.entity.ArtistGenre;
import com.example.api.entity.Genre;
import com.example.api.entity.Song;
import com.example.api.repository.ArtistGenreRepository;
import com.example.api.repository.ArtistRepository;
import com.example.api.repository.GenreRepository;
import com.example.api.repository.SongRepository;
import com.example.api.service.ArtistService;
import com.example.api.service.ArtistSyncService;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Lazy;
import org.springframework.context.annotation.Primary;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;
import org.springframework.web.reactive.function.client.WebClientResponseException;

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

    @Autowired
    private ArtistRepository artistRepository;

    @Autowired
    private GenreRepository genreRepository;

    @Autowired
    private ArtistGenreRepository artistGenreRepository;

    // ArtistSyncServiceを遅延注入（循環依存を回避）
    private ArtistSyncService artistSyncService;

    @Autowired
    @Lazy
    public void setArtistSyncService(ArtistSyncService artistSyncService) {
        this.artistSyncService = artistSyncService;
    }

    // ArtistServiceを遅延注入（循環依存を回避: SpotifyApiClientImpl ↔ ArtistService）
    private ArtistService artistService;

    @Autowired
    @Lazy
    public void setArtistService(ArtistService artistService) {
        this.artistService = artistService;
    }

    private static final Logger logger = LoggerFactory.getLogger(SpotifyApiClientImpl.class);
    private static final String SPOTIFY_AUTH_URL = "https://accounts.spotify.com/api/token";
    private static final String SPOTIFY_API_URL = "https://api.spotify.com/v1";
    private static final int MAX_ALBUMS_PER_REQUEST = 50;
    private static final int MAX_TRACKS_PER_REQUEST = 50;
    private static final int SPOTIFY_SEARCH_MAX_LIMIT = 50;
    private static final int SPOTIFY_SEARCH_MAX_OFFSET = 1000;
    
    /** ジャンル検索で返却する楽曲数 */
    private static final int GENRE_SEARCH_SONG_LIMIT = 5;

    private final WebClient authClient;
    private final WebClient apiClient;
    private final ObjectMapper objectMapper;
    private final Random random = new Random();
    private static final Map<String, List<String>> GENRE_KEYWORDS = buildGenreKeywords();

    @Value("${spotify.client.id:}")
    private String clientId;

    @Value("${spotify.client.secret:}")
    private String clientSecret;

    private String accessToken;
    private Instant tokenExpiry;

    // GeniusApiClientを遅延注入（循環依存を回避）
    private GeniusApiClient geniusApiClient;

    @Autowired
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
                    if (!seenTrackIds.contains(song.getSpotifyTrackId())) {
                        allSongs.add(song);
                        seenTrackIds.add(song.getSpotifyTrackId());
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
            final int offset = currentOffset;
            
            String response = apiClient.get()
                .uri(uriBuilder -> uriBuilder
                    .path("/artists/" + artistId + "/albums")
                    .queryParam("include_groups", "album,single")
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

            nextUrl = jsonNode.path("next").asText(null);
            currentOffset += MAX_ALBUMS_PER_REQUEST;

        } while (nextUrl != null && !nextUrl.isEmpty());

        return albumIds;
    }

    /**
     * アルバムから全トラックを取得
     */
    private List<Song> getTracksFromAlbum(String albumId, String artistId, String token) {
        List<Song> songs = new ArrayList<>();
        int currentOffset = 0;
        boolean hasMore = true;

        try {
            while (hasMore) {
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
                        // ★ 修正: artistIdを指定してArtist検索/作成をスキップ
                        Song song = parseTrackToSongWithArtist(track, artistId);
                        if (song != null) {
                            songs.add(song);
                        }
                    }
                    
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

    /**
     * ★ 新仕様 ★
     * ジャンル名からランダムな楽曲を取得（5曲）
     * 
     * 処理フロー:
     * 1. ジャンル名でArtistGenreを検索し、ランダムに1人のアーティストを選択
     * 2. そのアーティストの楽曲をSongテーブルから検索
     * 3. Songテーブルに曲がなければ、ArtistSyncServiceで同期してからDB取得
     * 4. ランダムに最大5曲を返却
     *
     * @param genreName ジャンル名
     * @return 楽曲リスト（最大5曲）
     */
    @Override
    public List<Song> getRandomSongsByGenre(String genreName) {
        logger.info("=== ジャンルから楽曲を取得開始 ===");
        logger.info("ジャンル名: {}", genreName);

        try {
            // ステップ1: ジャンル名でアーティストをランダムに1人取得
            Artist selectedArtist = findRandomArtistByGenre(genreName);
            
            if (selectedArtist == null) {
                logger.warn("ジャンル '{}' に該当するアーティストが見つかりませんでした", genreName);
                // フォールバック: Spotify APIで検索（従来の動作）
                return getRandomSongsFromSpotifyByGenre(genreName);
            }

            logger.info("選択されたアーティスト: id={}, name={}", 
                selectedArtist.getArtistId(), selectedArtist.getArtistName());

            // ステップ2: Songテーブルからそのアーティストの曲数をチェック
            long songCount = songRepository.countByArtistId(selectedArtist.getArtistId());
            logger.info("DBに存在する楽曲数: {}", songCount);

            // ステップ3: 曲がなければSpotify APIから同期
            if (songCount == 0) {
                logger.info("楽曲がないため、Spotify APIから同期します");
                syncArtistSongsFromSpotify(selectedArtist);
                
                // 同期後に再カウント
                songCount = songRepository.countByArtistId(selectedArtist.getArtistId());
                logger.info("同期後の楽曲数: {}", songCount);
                
                if (songCount == 0) {
                    logger.warn("同期後も楽曲が見つかりませんでした");
                    return getRandomSongsFromSpotifyByGenre(genreName);
                }
            }

            // ステップ4: DBからランダムに5曲取得
            List<Song> songs = songRepository.findRandomSongsByArtist(
                selectedArtist.getArtistId(), 
                GENRE_SEARCH_SONG_LIMIT
            );

            logger.info("=== ジャンルから楽曲を取得完了 ===");
            logger.info("取得曲数: {}", songs.size());

            return songs;

        } catch (Exception e) {
            logger.error("ジャンル '{}' からの楽曲取得に失敗しました", genreName, e);
            return getRandomSongsFromSpotifyByGenre(genreName);
        }
    }

    /**
     * ジャンル名からランダムにアーティストを1人取得
     * 
     * 検索優先順位:
     * 1. 完全一致検索
     * 2. 部分一致検索（前方・後方にワイルドカード）
     */
    private Artist findRandomArtistByGenre(String genreName) {
        // 1. 完全一致で検索
        Optional<ArtistGenre> exactMatch = artistGenreRepository.findRandomByGenreName(genreName);
        if (exactMatch.isPresent()) {
            logger.debug("ジャンル完全一致でアーティストを発見: {}", genreName);
            return exactMatch.get().getArtist();
        }

        // 2. 部分一致で検索（例: "pop" → "%pop%" で j-pop, k-pop なども対象）
        String likePattern = "%" + genreName + "%";
        Optional<ArtistGenre> likeMatch = artistGenreRepository.findRandomByGenreNameLike(likePattern);
        if (likeMatch.isPresent()) {
            logger.debug("ジャンル部分一致でアーティストを発見: pattern={}", likePattern);
            return likeMatch.get().getArtist();
        }

        logger.debug("ジャンル '{}' に該当するアーティストが見つかりませんでした", genreName);
        return null;
    }

    /**
     * ArtistSyncServiceを使用してアーティストの楽曲を同期
     */
    private void syncArtistSongsFromSpotify(Artist artist) {
        if (artistSyncService == null) {
            logger.warn("ArtistSyncServiceが利用できません");
            return;
        }

        try {
            logger.info("アーティスト '{}' の楽曲を同期中...", artist.getArtistName());
            int syncedCount = artistSyncService.syncArtistSongs(artist.getArtistId());
            logger.info("同期完了: {}曲を保存", syncedCount);
        } catch (Exception e) {
            logger.error("楽曲同期に失敗: artistId={}", artist.getArtistId(), e);
        }
    }

    /**
     * フォールバック: Spotify APIから直接ジャンルで検索（従来の動作）
     * DBにジャンルに該当するアーティストがない場合に使用
     */
    private List<Song> getRandomSongsFromSpotifyByGenre(String genreName) {
        logger.info("フォールバック: Spotify APIでジャンル '{}' を検索", genreName);
        
        String token = getAccessToken();
        if (token == null) {
            logger.warn("トークンが取得できないためモックデータを返します");
            return Collections.singletonList(createMockSong(genreName));
        }

        try {
            String query = "genre:" + genreName;
            int offset = random.nextInt(100);

            String response = apiClient.get()
                .uri(uriBuilder -> uriBuilder
                    .path("/search")
                    .queryParam("q", query)
                    .queryParam("type", "track")
                    .queryParam("limit", GENRE_SEARCH_SONG_LIMIT)
                    .queryParam("offset", offset)
                    .build())
                .header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                .retrieve()
                .bodyToMono(String.class)
                .block();

            JsonNode jsonNode = objectMapper.readTree(response);
            JsonNode tracks = jsonNode.path("tracks").path("items");

            List<Song> songs = new ArrayList<>();
            if (tracks.isArray()) {
                for (JsonNode track : tracks) {
                    Song song = parseTrackToSong(track);
                    if (song != null) {
                        songs.add(song);
                    }
                }
            }

            if (songs.isEmpty()) {
                logger.warn("Spotify APIでも楽曲が見つかりませんでした");
                return Collections.singletonList(createMockSong(genreName));
            }

            logger.info("Spotify APIから{}曲を取得", songs.size());
            return songs;

        } catch (Exception e) {
            logger.error("Spotify APIでのジャンル検索に失敗: {}", genreName, e);
            return Collections.singletonList(createMockSong(genreName));
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
        if (query == null || query.trim().isEmpty()) {
            return Collections.emptyList();
        }

        String token = getAccessToken();
        if (token == null) {
            logger.warn("Spotify token not available");
            return createMockArtists(query);
        }

        try {
            List<SpotifyArtistDto> result = new ArrayList<>();
            int remaining = Math.max(1, limit);
            int perRequest = 50;
            int offset = 0;

            while (remaining > 0) {
                int requestLimit = Math.min(perRequest, remaining);
                final int currentOffset = offset;
                String response = apiClient.get()
                    .uri(uriBuilder -> uriBuilder
                        .path("/search")
                        .queryParam("q", query)
                        .queryParam("type", "artist")
                        .queryParam("limit", requestLimit)
                        .queryParam("offset", currentOffset)
                        .build())
                    .header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                    .retrieve()
                    .bodyToMono(String.class)
                    .block();

                JsonNode jsonNode = objectMapper.readTree(response);
                JsonNode artists = jsonNode.path("artists").path("items");
                if (!artists.isArray() || artists.size() == 0) {
                    break;
                }

                for (JsonNode artistNode : artists) {
                    SpotifyArtistDto dto = parseArtistNode(artistNode);
                    if (dto != null) {
                        result.add(dto);
                    }
                }

                offset += requestLimit;
                remaining -= requestLimit;
                if (offset >= 10000) {
                    break;
                }
            }

            logger.info("Spotify artist search: query={}, count={}", query, result.size());
            return result;

        } catch (Exception e) {
            logger.error("Spotify artist search failed: query={}", query, e);
            return createMockArtists(query);
        }
    }


    
    @Override
    public List<SpotifyArtistDto> searchArtistsByGenre(String genreName, int limit) {
        if (genreName == null || genreName.trim().isEmpty()) {
            return Collections.emptyList();
        }

        logger.info("Genre artist search start: genre={}, limit={}", genreName, limit);
        String token = getAccessToken();
        if (token == null) {
            logger.warn("Spotify token not available");
            return createMockArtists(genreName);
        }

        try {
            List<String> keywords = buildGenreKeywordList(genreName);
            logger.info("Genre keyword search: genre={}, keywords={}", genreName, keywords);
            return searchArtistsByGenreKeywords(genreName, keywords, limit, token);
        } catch (Exception e) {
            logger.error("Genre artist search failed: genre={}", genreName, e);
            return createMockArtists(genreName);
        }
    }

    private List<SpotifyArtistDto> searchArtistsByGenreKeywords(
        String genreName,
        List<String> keywords,
        int limit,
        String token
    ) throws Exception {
        if (keywords == null || keywords.isEmpty()) {
            logger.info("Genre keyword search empty: genre={}", genreName);
            return Collections.emptyList();
        }

        int searchLimit = SPOTIFY_SEARCH_MAX_LIMIT;
        int maxRequests = 10;
        int maxOffset = SPOTIFY_SEARCH_MAX_OFFSET - searchLimit;
        if (maxOffset < 0) {
            maxOffset = 0;
        }
        int maxPage = maxOffset / searchLimit;

        LinkedHashSet<String> artistIds = new LinkedHashSet<>();
        int requestCount = 0;
        int keywordIndex = 0;
        while (requestCount < maxRequests) {
            String keyword = keywords.get(keywordIndex % keywords.size());
            keywordIndex++;
            String query = buildTrackKeywordQuery(keyword);
            if (query.isBlank()) {
                requestCount++;
                continue;
            }
            int offset = maxPage > 0 ? random.nextInt(maxPage + 1) * searchLimit : 0;

            String response;
            try {
                response = apiClient.get()
                    .uri(uriBuilder -> uriBuilder
                        .path("/search")
                        .queryParam("q", query)
                        .queryParam("type", "track")
                        .queryParam("limit", searchLimit)
                        .queryParam("offset", offset)
                        .build())
                    .header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                    .retrieve()
                    .bodyToMono(String.class)
                    .block();
            } catch (WebClientResponseException e) {
                logger.error(
                    "Genre search request failed: query={}, offset={}, limit={}, status={}, body={}",
                    query,
                    offset,
                    searchLimit,
                    e.getRawStatusCode(),
                    e.getResponseBodyAsString());
                if (e.getStatusCode().value() == 400) {
                    requestCount++;
                    continue;
                }
                throw e;
            }
            if (response == null || response.isBlank()) {
                requestCount++;
                continue;
            }

            JsonNode jsonNode = objectMapper.readTree(response);
            JsonNode tracks = jsonNode.path("tracks").path("items");
            if (!tracks.isArray() || tracks.size() == 0) {
                requestCount++;
                continue;
            }

            collectArtistIdsFromTracks(tracks, artistIds);
            requestCount++;
            if (artistIds.size() >= Math.max(1, limit) * 2) {
                break;
            }
        }

        if (artistIds.isEmpty()) {
            logger.info("Genre keyword search artists empty: genre={}, keywords={}", genreName, keywords);
            return Collections.emptyList();
        }

        List<String> artistIdList = new ArrayList<>(artistIds);
        logger.info(
            "Genre keyword search collected artist ids: genre={}, count={}",
            genreName,
            artistIdList.size());

        List<SpotifyArtistDto> detailedArtists = fetchArtistsByIds(artistIdList, token);
        if (detailedArtists.isEmpty()) {
            logger.info("Genre keyword search detail artists empty: genre={}", genreName);
            return Collections.emptyList();
        }

        List<SpotifyArtistDto> result = new ArrayList<>();
        for (SpotifyArtistDto dto : detailedArtists) {
            if (matchesAnyKeywordInArtistGenres(dto, keywords)) {
                result.add(dto);
            }
        }

        if (result.isEmpty()) {
            logger.info("Genre keyword search genre filter empty: genre={}, keywords={}", genreName, keywords);
            return Collections.emptyList();
        }

        result.sort(Comparator.comparingInt(SpotifyArtistDto::getPopularity).reversed());
        logger.info(
            "Genre keyword search result count: collected={}, detailed={}, genreFiltered={}, returned={}",
            artistIds.size(),
            detailedArtists.size(),
            result.size(),
            result.size());

        if (result.size() > limit) {
            return result.subList(0, limit);
        }
        return result;
    }

    private static Map<String, List<String>> buildGenreKeywords() {
        Map<String, List<String>> map = new HashMap<>();
        map.put("anime", List.of(
            "アニメ",
            "アニソン",
            "アニメソング",
            "anime",
            "anisong",
            "anime song",
            "soundtrack",
            "theme song",
            "opening",
            "ending",
            "OST",
            "original soundtrack"
        ));
        map.put("jpop", List.of("j-pop", "jpop", "J-POP", "邦楽", "Jポップ"));
        map.put("kpop", List.of("k-pop", "kpop", "K-POP", "케이팝", "한국", "korean pop"));
        map.put("pop", List.of("pop", "pops", "hit song", "chart"));
        map.put("rock", List.of("rock", "rock band", "guitar"));
        map.put("metal", List.of("metal", "heavy metal", "metalcore"));
        map.put("punk", List.of("punk", "pop punk", "hardcore"));
        map.put("hiphop", List.of("hip hop", "hiphop", "rap"));
        map.put("rap", List.of("rap", "hip hop"));
        map.put("rnb", List.of("r&b", "rnb", "rhythm and blues", "soul"));
        map.put("soul", List.of("soul", "neo soul"));
        map.put("funk", List.of("funk", "groove"));
        map.put("jazz", List.of("jazz", "swing", "bebop"));
        map.put("classical", List.of("classical", "symphony", "orchestra", "concerto", "piano", "violin"));
        map.put("electronic", List.of("electronic", "electronica", "synth", "synthwave"));
        map.put("edm", List.of("edm", "electronic dance"));
        map.put("dance", List.of("dance", "club"));
        map.put("house", List.of("house", "deep house"));
        map.put("techno", List.of("techno"));
        map.put("trance", List.of("trance"));
        map.put("dubstep", List.of("dubstep"));
        map.put("drumandbass", List.of("drum and bass", "dnb"));
        map.put("reggae", List.of("reggae", "dub"));
        map.put("ska", List.of("ska"));
        map.put("blues", List.of("blues"));
        map.put("folk", List.of("folk", "acoustic"));
        map.put("country", List.of("country", "bluegrass", "americana"));
        map.put("latin", List.of("latin", "reggaeton", "salsa", "bachata"));
        map.put("bossa", List.of("bossa nova"));
        map.put("citypop", List.of("city pop", "シティポップ"));
        return map;
    }

    private String buildTrackKeywordQuery(String keyword) {
        if (keyword == null) {
            return "";
        }
        String term = keyword.trim();
        if (term.isEmpty()) {
            return "";
        }
        if (term.contains(" ")) {
            return "\"" + term + "\"";
        }
        return term;
    }

    private List<String> buildGenreKeywordList(String genreName) {
        String normalized = normalizeGenreKey(genreName);
        LinkedHashSet<String> keywords = new LinkedHashSet<>();
        List<String> mapped = GENRE_KEYWORDS.get(normalized);
        if (mapped != null) {
            keywords.addAll(mapped);
        }
        String trimmed = genreName == null ? "" : genreName.trim();
        if (!trimmed.isEmpty()) {
            keywords.add(trimmed);
            keywords.add(trimmed.toLowerCase(Locale.ROOT));
        }
        return new ArrayList<>(keywords);
    }

    private boolean matchesAnyKeywordInArtistGenres(SpotifyArtistDto artist, List<String> keywords) {
        if (artist == null || artist.getGenres() == null || keywords == null || keywords.isEmpty()) {
            return false;
        }
        List<String> genres = artist.getGenres();
        for (String keyword : keywords) {
            if (keyword == null) {
                continue;
            }
            String term = keyword.trim();
            if (term.isEmpty()) {
                continue;
            }
            String loweredTerm = term.toLowerCase(Locale.ROOT);
            for (String genre : genres) {
                if (genre == null) {
                    continue;
                }
                if (genre.toLowerCase(Locale.ROOT).contains(loweredTerm)) {
                    return true;
                }
            }
        }
        return false;
    }

    private String normalizeGenreKey(String genreName) {
        if (genreName == null) {
            return "";
        }
        String lower = genreName.trim().toLowerCase(Locale.ROOT);
        return lower.replaceAll("[\\s_\\-]+", "");
    }

    private void collectArtistIdsFromTracks(JsonNode tracks, Set<String> artistIds) {
        if (!tracks.isArray()) {
            return;
        }
        for (JsonNode trackNode : tracks) {
            JsonNode artists = trackNode.path("artists");
            if (!artists.isArray()) {
                continue;
            }
            for (JsonNode artistNode : artists) {
                String artistId = artistNode.path("id").asText();
                if (artistId != null && !artistId.isBlank()) {
                    artistIds.add(artistId);
                }
            }
        }
    }

    private List<SpotifyArtistDto> fetchArtistsByIds(List<String> artistIds, String token) throws Exception {
        if (artistIds.isEmpty()) {
            return Collections.emptyList();
        }

        int batchSize = 50;
        LinkedHashMap<String, SpotifyArtistDto> resultsById = new LinkedHashMap<>();
        for (int start = 0; start < artistIds.size(); start += batchSize) {
            int end = Math.min(start + batchSize, artistIds.size());
            List<String> batch = artistIds.subList(start, end);

            String response = apiClient.get()
                .uri(uriBuilder -> uriBuilder
                    .path("/artists")
                    .queryParam("ids", String.join(",", batch))
                    .build())
                .header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                .retrieve()
                .bodyToMono(String.class)
                .block();

            if (response == null || response.isBlank()) {
                continue;
            }

            JsonNode jsonNode = objectMapper.readTree(response);
            JsonNode artists = jsonNode.path("artists");

            if (artists.isArray()) {
                for (JsonNode artistNode : artists) {
                    SpotifyArtistDto dto = parseArtistNode(artistNode);
                    if (dto != null && !resultsById.containsKey(dto.getSpotifyId())) {
                        resultsById.put(dto.getSpotifyId(), dto);
                    }
                }
            }
        }

        List<SpotifyArtistDto> result = new ArrayList<>(resultsById.values());
        return result;
    }

    private SpotifyArtistDto parseArtistNode(JsonNode artistNode) {
        try {
            String imageUrl = null;
            JsonNode images = artistNode.path("images");
            if (images.isArray() && images.size() > 0) {
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
                        if (dto != null && dto.getPopularity() >= 50) {
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

    private Song searchAndSelectRandom(String query, String token) throws Exception {
        int offset = random.nextInt(100);

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
     * アーティストが存在しない場合は先にDBに保存する
     */
    private Song parseTrackToSong(JsonNode trackNode) {
        return parseTrackToSongWithArtist(trackNode, null);
    }

    /**
     * SpotifyのトラックJSONをSongエンティティに変換（アーティストID指定版）
     * 
     * @param trackNode SpotifyのトラックJSON
     * @param knownArtistApiId 既知のSpotifyアーティストID（nullの場合はトラックから取得）
     * @return Songエンティティ
     */
    private Song parseTrackToSongWithArtist(JsonNode trackNode, String knownArtistApiId) {
        Song song = new Song();

        String songName = trackNode.path("name").asText();
        song.setSongname(songName);
        song.setSpotifyTrackId(trackNode.path("id").asText());

        // アーティスト情報を取得してDBに保存
        JsonNode artists = trackNode.path("artists");
        String artistApiId = knownArtistApiId;
        String artistName = null;

        if (artists.isArray() && artists.size() > 0) {
            if (artistApiId == null) {
                artistApiId = artists.get(0).path("id").asText();
            }
            artistName = artists.get(0).path("name").asText();
        }

        if (artistApiId != null && !artistApiId.isEmpty()) {
            // ★ 修正: ArtistServiceの独立トランザクションで取得・作成（制約違反が起きても外側トランザクションを汚染しない）
            Artist artist = artistService.getOrCreateArtist(artistApiId, artistName != null ? artistName : "Unknown Artist");

            // artistIdがLong型に変更されたため、直接設定
            song.setArtistId(artist.getArtistId());
            logger.debug("Songにアーティストを設定: artistId={}, artistName={}", artist.getArtistId(), artist.getArtistName());
        } else {
            logger.warn("トラックにアーティスト情報がありません: {}", songName);
            song.setArtistId(1L);
        }

        song.setLanguage(null);
        song.setGeniusSongId(null);

        logger.debug("Spotify楽曲をパース: {} (ID: {})", song.getSongname(), song.getSpotifyTrackId());
        return song;
    }

    private Song createMockSong(String genre) {
        Song song = new Song();
        song.setSongname("Mock Song - " + System.currentTimeMillis());
        song.setSpotifyTrackId("mock_" + System.currentTimeMillis());
        song.setGeniusSongId(null);
        song.setLanguage(null);
        song.setArtistId(1L);
        return song;
    }
}
