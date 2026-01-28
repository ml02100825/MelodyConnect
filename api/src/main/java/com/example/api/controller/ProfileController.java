package com.example.api.controller;

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

    /**
     * プロフィール更新エンドポイント（ステップ2: ユーザー名とアイコン設定）
     * @param userId ユーザーID
     * @param request プロフィール更新リクエスト
     * @return 更新されたユーザー情報
     */
    @PutMapping(value = "/{userId}", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
public ResponseEntity<?> updateProfile(
    @PathVariable Long userId,
    @RequestPart("username") String username,
    @RequestPart("userUuid") String userUuid,
    @RequestPart(value = "icon", required = false) MultipartFile icon
) {
    try {
        User user = profileService.updateProfileMultipart(userId, username, userUuid, icon);

        Map<String, Object> response = new HashMap<>();
        response.put("userId", user.getId());
        response.put("username", user.getUsername());
        response.put("email", user.getMailaddress());
        response.put("imageUrl", user.getImageUrl());
        response.put("message", "プロフィールを更新しました");

        return ResponseEntity.ok(response);
    } catch (IllegalArgumentException e) {
        return ResponseEntity.badRequest().body(createErrorResponse(e.getMessage()));
    } catch (Exception e) {
        return ResponseEntity.status(500)
                .body(createErrorResponse("プロフィール更新中にエラーが発生しました"));
    }
}
    /**
     * プロフィール取得エンドポイント
     * @param userId ユーザーID
     * @return ユーザー情報
     */
    @GetMapping("/{userId}")
    public ResponseEntity<?> getProfile(@PathVariable Long userId) {
        try {
            User user = profileService.getUserProfile(userId);

            Map<String, Object> response = new HashMap<>();
            response.put("userId", user.getId());
            response.put("username", user.getUsername());
            response.put("email", user.getMailaddress());
            response.put("imageUrl", user.getImageUrl());
            response.put("userUuid", user.getUserUuid());
            response.put("totalPlay", user.getTotalPlay());
            response.put("life", user.getLife());

            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(createErrorResponse(e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.status(500)
                    .body(createErrorResponse("プロフィール取得中にエラーが発生しました"));
        }
    }

    /**
     * エラーレスポンスを作成
     * @param message エラーメッセージ
     * @return エラーレスポンスマップ
     */
    private Map<String, String> createErrorResponse(String message) {
        Map<String, String> error = new HashMap<>();
        error.put("error", message);
        return error;
    }
}
