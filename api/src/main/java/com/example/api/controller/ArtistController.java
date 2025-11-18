package com.example.api.controller;

import com.example.api.dto.LikeArtistRequest;
import com.example.api.dto.SpotifyArtistDto;
import com.example.api.entity.Artist;
import com.example.api.service.ArtistService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * アーティスト関連のコントローラー
 */
@RestController
@RequestMapping("/api/artist")
public class ArtistController {

    private static final Logger logger = LoggerFactory.getLogger(ArtistController.class);

    @Autowired
    private ArtistService artistService;

    /**
     * アーティストを検索
     * GET /api/artist/search?q=アーティスト名&limit=10
     */
    @GetMapping("/search")
    public ResponseEntity<List<SpotifyArtistDto>> searchArtists(
            @RequestParam("q") String query,
            @RequestParam(value = "limit", defaultValue = "10") int limit) {
        logger.info("アーティスト検索リクエスト: query={}, limit={}", query, limit);
        List<SpotifyArtistDto> artists = artistService.searchArtists(query, limit);
        return ResponseEntity.ok(artists);
    }

    /**
     * お気に入りアーティストを登録
     * POST /api/artist/like
     */
    @PostMapping("/like")
    public ResponseEntity<Map<String, Object>> registerLikeArtists(
            @RequestBody LikeArtistRequest request,
            Authentication authentication) {
        Long userId = Long.parseLong(authentication.getName());
        logger.info("お気に入りアーティスト登録リクエスト: userId={}, count={}",
            userId, request.getArtists().size());

        artistService.registerLikeArtists(userId, request);

        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("message", "お気に入りアーティストを登録しました");
        return ResponseEntity.ok(response);
    }

    /**
     * ユーザーのお気に入りアーティストを取得
     * GET /api/artist/like
     */
    @GetMapping("/like")
    public ResponseEntity<List<Artist>> getLikeArtists(Authentication authentication) {
        Long userId = Long.parseLong(authentication.getName());
        logger.info("お気に入りアーティスト取得リクエスト: userId={}", userId);
        List<Artist> artists = artistService.getLikeArtists(userId);
        return ResponseEntity.ok(artists);
    }

    /**
     * 初期設定完了状態を確認
     * GET /api/artist/setup-status
     */
    @GetMapping("/setup-status")
    public ResponseEntity<Map<String, Boolean>> getSetupStatus(Authentication authentication) {
        Long userId = Long.parseLong(authentication.getName());
        boolean completed = artistService.isInitialSetupCompleted(userId);

        Map<String, Boolean> response = new HashMap<>();
        response.put("initialSetupCompleted", completed);
        return ResponseEntity.ok(response);
    }
}
