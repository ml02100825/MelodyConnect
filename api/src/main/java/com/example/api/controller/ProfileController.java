package com.example.api.controller;

import com.example.api.dto.PrivacyUpdateRequest;
import com.example.api.dto.ProfileUpdateRequest;
import com.example.api.entity.User;
import com.example.api.service.ProfileService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.http.MediaType;
import org.springframework.web.multipart.MultipartFile;

import java.util.HashMap;
import java.util.Map;

/**
 * プロフィールコントローラー
 * ユーザープロフィール設定のエンドポイントを提供します
 * CORS設定はWebConfigで一括管理
 */
@RestController
@RequestMapping("/api/profile")
public class ProfileController {

    @Autowired
    private ProfileService profileService;

    @GetMapping("/{userId}")
    public ResponseEntity<?> getProfile(@PathVariable Long userId) {
        try {
            User user = profileService.getUserProfile(userId);
            Map<String, Object> response = createProfileResponse(user);
            response.putAll(profileService.getProfileExtras(user));
            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(createError(e.getMessage()));
        }
    }

    @PutMapping("/{userId}")
    public ResponseEntity<?> updateProfile(@PathVariable Long userId,
                                          @Valid @RequestBody ProfileUpdateRequest request) {
        try {
            User user = profileService.updateProfile(userId, request);
            Map<String, Object> response = createProfileResponse(user);
            response.put("message", "プロフィールを更新しました");
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            return ResponseEntity.status(500).body(createError("更新に失敗しました: " + e.getMessage()));
        }
    }

    // 音量更新エンドポイントは削除しました

    @PutMapping("/{userId}/privacy")
    public ResponseEntity<?> updatePrivacy(@PathVariable Long userId,
                                           @RequestBody PrivacyUpdateRequest request) {
        try {
            profileService.updatePrivacy(userId, request.getPrivacy());
            return ResponseEntity.ok(Map.of("message", "プライバシー設定を更新しました", "privacy", request.getPrivacy()));
        } catch (Exception e) {
            return ResponseEntity.status(500).body(createError("プライバシー設定更新に失敗しました"));
        }
    }

    private Map<String, Object> createProfileResponse(User user) {
        Map<String, Object> response = new HashMap<>();
        response.put("userId", user.getId());
        response.put("username", user.getUsername());
        response.put("email", user.getMailaddress());
        response.put("imageUrl", user.getImageUrl());
        response.put("userUuid", user.getUserUuid());
        response.put("totalPlay", user.getTotalPlay());
        response.put("life", user.getLife());
        response.put("privacy", user.getPrivacy());
        return response;
    }

    private Map<String, String> createError(String message) {
        Map<String, String> error = new HashMap<>();
        error.put("error", message);
        return error;
    }
}