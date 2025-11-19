package com.example.api.controller;

import com.example.api.dto.SpotifyArtistDto;
import com.example.api.service.DevUtilityService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 開発用コントローラー
 * 本番環境では無効にすること
 */
@RestController
@RequestMapping("/api/dev")
public class DevController {

    private static final Logger logger = LoggerFactory.getLogger(DevController.class);

    @Autowired
    private DevUtilityService devUtilityService;

    /**
     * Spotifyから人気アーティストを取得
     * GET /api/dev/popular-artists?limit=50
     */
    @GetMapping("/popular-artists")
    public ResponseEntity<List<SpotifyArtistDto>> getPopularArtists(
            @RequestParam(value = "limit", defaultValue = "50") int limit) {
        logger.info("人気アーティスト取得リクエスト: limit={}", limit);
        List<SpotifyArtistDto> artists = devUtilityService.fetchPopularArtists(limit);
        return ResponseEntity.ok(artists);
    }

    /**
     * 人気アーティストデータからSQL文を生成
     * GET /api/dev/generate-sql?limit=50
     *
     * レスポンスはプレーンテキストのSQL
     */
    @GetMapping(value = "/generate-sql", produces = MediaType.TEXT_PLAIN_VALUE)
    public ResponseEntity<String> generateSql(
            @RequestParam(value = "limit", defaultValue = "50") int limit) {
        logger.info("SQL生成リクエスト: limit={}", limit);
        String sql = devUtilityService.fetchAndGenerateSql(limit);
        return ResponseEntity.ok(sql);
    }

    /**
     * 人気アーティストデータとSQLを両方返す
     * GET /api/dev/artist-data?limit=50
     */
    @GetMapping("/artist-data")
    public ResponseEntity<Map<String, Object>> getArtistData(
            @RequestParam(value = "limit", defaultValue = "50") int limit) {
        logger.info("アーティストデータ取得リクエスト: limit={}", limit);

        List<SpotifyArtistDto> artists = devUtilityService.fetchPopularArtists(limit);
        String sql = devUtilityService.generateInsertSql(artists);

        Map<String, Object> response = new HashMap<>();
        response.put("artists", artists);
        response.put("sql", sql);
        response.put("artistCount", artists.size());

        return ResponseEntity.ok(response);
    }
}
