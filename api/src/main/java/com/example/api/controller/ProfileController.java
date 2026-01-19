package com.example.api.controller;

import com.example.api.dto.PrivacyUpdateRequest;
import com.example.api.dto.ProfileUpdateRequest;
import com.example.api.dto.VolumeUpdateRequest;
import com.example.api.entity.User;
import com.example.api.service.ProfileService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

/**
 * プロフィールコントローラー
 * ユーザー設定関連のAPIエンドポイントを提供します
 */
@RestController
@RequestMapping("/api/profile")
public class ProfileController {

    @Autowired
    private ProfileService profileService;

    /**
     * プロフィール取得
     * GET /api/profile/{userId}
     */
    @GetMapping("/{userId}")
    public ResponseEntity<?> getProfile(@PathVariable Long userId) {
        try {
            User user = profileService.getUserProfile(userId);
            return ResponseEntity.ok(createProfileResponse(user));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(createErrorResponse(e.getMessage()));
        }
    }

    /**
     * プロフィール基本情報更新（名前、画像、ID）
     * PUT /api/profile/{userId}
     */
    @PutMapping("/{userId}")
    public ResponseEntity<?> updateProfile(@PathVariable Long userId,
                                          @Valid @RequestBody ProfileUpdateRequest request) {
        try {
            User user = profileService.updateProfile(userId, request);
            
            Map<String, Object> response = createProfileResponse(user);
            response.put("message", "プロフィールを更新しました");
            return ResponseEntity.ok(response);
            
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(createErrorResponse(e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.status(500).body(createErrorResponse("更新中にエラーが発生しました"));
        }
    }

    /**
     * 音量設定更新
     * PUT /api/profile/{userId}/volume
     */
    @PutMapping("/{userId}/volume")
    public ResponseEntity<?> updateVolume(@PathVariable Long userId,
                                          @RequestBody @Valid VolumeUpdateRequest request) {
        try {
            profileService.updateVolume(userId, request.getVolume());

            Map<String, Object> response = new HashMap<>();
            response.put("userId", userId);
            response.put("volume", request.getVolume());
            response.put("message", "音量を更新しました");
            return ResponseEntity.ok(response);
            
        } catch (Exception e) {
            return ResponseEntity.status(500).body(createErrorResponse("音量更新に失敗しました"));
        }
    }

    /**
     * プライバシー設定更新
     * PUT /api/profile/{userId}/privacy
     */
    @PutMapping("/{userId}/privacy")
    public ResponseEntity<?> updatePrivacy(@PathVariable Long userId,
                                           @RequestBody @Valid PrivacyUpdateRequest request) {
        try {
            profileService.updatePrivacy(userId, request);

            Map<String, Object> response = new HashMap<>();
            response.put("userId", userId);
            response.put("privacy", request.getPrivacy());
            response.put("message", "プライバシー設定を更新しました");
            return ResponseEntity.ok(response);

        } catch (Exception e) {
            return ResponseEntity.status(500).body(createErrorResponse("プライバシー設定の更新に失敗しました"));
        }
    }

    // --- ヘルパーメソッド ---

    private Map<String, Object> createProfileResponse(User user) {
        Map<String, Object> response = new HashMap<>();
        response.put("userId", user.getId());
        response.put("username", user.getUsername());
        response.put("email", user.getMailaddress());
        response.put("imageUrl", user.getImageUrl());
        response.put("userUuid", user.getUserUuid());
        response.put("totalPlay", user.getTotalPlay());
        response.put("life", user.getLife());
        response.put("volume", user.getVolume());
        response.put("privacy", user.getPrivacy()); // プライバシー設定も返す
        return response;
    }

    private Map<String, String> createErrorResponse(String message) {
        Map<String, String> error = new HashMap<>();
        error.put("error", message);
        return error;
    }
}