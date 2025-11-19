package com.example.api.service;

import com.example.api.client.SpotifyApiClient;
import com.example.api.dto.SpotifyArtistDto;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.*;

/**
 * 開発用ユーティリティサービス
 * Spotifyから人気アーティストを取得し、SQLを生成
 */
@Service
public class DevUtilityService {

    private static final Logger logger = LoggerFactory.getLogger(DevUtilityService.class);

    @Autowired
    private SpotifyApiClient spotifyApiClient;

    /**
     * 人気アーティストを取得
     */
    public List<SpotifyArtistDto> fetchPopularArtists(int limit) {
        return spotifyApiClient.getPopularArtists(limit);
    }

    /**
     * アーティストデータからSQL文を生成
     */
    public String generateInsertSql(List<SpotifyArtistDto> artists) {
        StringBuilder sql = new StringBuilder();

        // ジャンル一覧を収集
        Set<String> allGenres = new LinkedHashSet<>();
        for (SpotifyArtistDto artist : artists) {
            allGenres.addAll(artist.getGenres());
        }

        sql.append("-- ====================================\n");
        sql.append("-- 自動生成されたSQL (Spotify API)\n");
        sql.append("-- 生成日時: ").append(java.time.LocalDateTime.now()).append("\n");
        sql.append("-- ====================================\n\n");

        // Genre INSERT文
        sql.append("-- ジャンルデータ\n");
        int genreId = 1;
        Map<String, Integer> genreIdMap = new HashMap<>();
        for (String genre : allGenres) {
            if (genre == null || genre.isEmpty()) continue;
            genreIdMap.put(genre, genreId);
            String escapedGenre = escapeString(genre);
            sql.append(String.format(
                "INSERT INTO genre (genre_id, name, created_at) VALUES (%d, '%s', NOW()) ON DUPLICATE KEY UPDATE name=name;\n",
                genreId, escapedGenre
            ));
            genreId++;
        }
        sql.append("\n");

        // Artist INSERT文
        sql.append("-- アーティストデータ\n");
        int artistId = 1;
        Map<String, Integer> artistIdMap = new HashMap<>();
        for (SpotifyArtistDto artist : artists) {
            artistIdMap.put(artist.getSpotifyId(), artistId);
            String escapedName = escapeString(artist.getName());
            String imageUrl = artist.getImageUrl() != null ? escapeString(artist.getImageUrl()) : "";

            // 最初のジャンルをデフォルトジャンルとして使用
            Integer defaultGenreId = 1;
            if (!artist.getGenres().isEmpty()) {
                defaultGenreId = genreIdMap.getOrDefault(artist.getGenres().get(0), 1);
            }

            sql.append(String.format(
                "INSERT INTO artist (artist_id, artist_name, genre_id, image_url, created_at, artist_api_id) " +
                "VALUES (%d, '%s', %d, '%s', NOW(), '%s') ON DUPLICATE KEY UPDATE artist_name=artist_name;\n",
                artistId, escapedName, defaultGenreId, imageUrl, artist.getSpotifyId()
            ));
            artistId++;
        }
        sql.append("\n");

        // ArtistGenre INSERT文（多対多関係）
        sql.append("-- アーティスト・ジャンル紐付けデータ\n");
        int artistGenreId = 1;
        for (SpotifyArtistDto artist : artists) {
            Integer aId = artistIdMap.get(artist.getSpotifyId());
            for (String genre : artist.getGenres()) {
                Integer gId = genreIdMap.get(genre);
                if (aId != null && gId != null) {
                    sql.append(String.format(
                        "INSERT INTO artist_genre (artist_genre_id, artist_id, genre_id, created_at) " +
                        "VALUES (%d, %d, %d, NOW()) ON DUPLICATE KEY UPDATE artist_id=artist_id;\n",
                        artistGenreId, aId, gId
                    ));
                    artistGenreId++;
                }
            }
        }

        logger.info("SQL生成完了: genres={}, artists={}, artist_genres={}",
            genreIdMap.size(), artistIdMap.size(), artistGenreId - 1);

        return sql.toString();
    }

    /**
     * SQL用に文字列をエスケープ
     */
    private String escapeString(String str) {
        if (str == null) return "";
        return str.replace("'", "''").replace("\\", "\\\\");
    }

    /**
     * 人気アーティストを取得してSQL生成（一括処理）
     */
    public String fetchAndGenerateSql(int limit) {
        List<SpotifyArtistDto> artists = fetchPopularArtists(limit);
        return generateInsertSql(artists);
    }
}
