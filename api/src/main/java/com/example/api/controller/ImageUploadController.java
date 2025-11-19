package com.example.api.controller;

import com.example.api.service.ImageUploadService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.HashMap;
import java.util.Map;

/**
 * 画像アップロードコントローラー
 * プロフィールアイコンなどの画像をアップロードして保存します
 */
@RestController
@RequestMapping("/api/upload")
public class ImageUploadController {

    @Autowired
    private ImageUploadService imageUploadService;

    // 画像の最大サイズ（5MB）
    private static final long MAX_FILE_SIZE = 5 * 1024 * 1024;

    // 許可する画像形式
    private static final String[] ALLOWED_EXTENSIONS = {"jpg", "jpeg", "png", "gif", "webp"};

    /**
     * 画像アップロード
     * @param file アップロードするファイル
     * @return 画像URL
     */
    @PostMapping("/image")
    public ResponseEntity<?> uploadImage(@RequestParam("file") MultipartFile file) {
        try {
            // ファイルが空でないかチェック
            if (file.isEmpty()) {
                return ResponseEntity.badRequest()
                        .body(createErrorResponse("ファイルが選択されていません"));
            }

            // ファイルサイズチェック
            if (file.getSize() > MAX_FILE_SIZE) {
                return ResponseEntity.badRequest()
                        .body(createErrorResponse("ファイルサイズは5MB以下である必要があります"));
            }

            // ファイル拡張子チェック
            String originalFilename = file.getOriginalFilename();
            if (originalFilename == null || !isAllowedExtension(originalFilename)) {
                return ResponseEntity.badRequest()
                        .body(createErrorResponse("許可されていないファイル形式です（jpg, jpeg, png, gif, webpのみ）"));
            }

            // 画像をアップロード（環境に応じてローカルまたはS3に保存）
            String imageUrl = imageUploadService.uploadImage(file);

            // レスポンスを返す
            Map<String, String> response = new HashMap<>();
            response.put("imageUrl", imageUrl);
            response.put("message", "画像をアップロードしました");

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(createErrorResponse("画像のアップロードに失敗しました: " + e.getMessage()));
        }
    }

    /**
     * ファイル拡張子が許可されているかチェック
     */
    private boolean isAllowedExtension(String filename) {
        String extension = getFileExtension(filename).toLowerCase();
        for (String allowed : ALLOWED_EXTENSIONS) {
            if (allowed.equals(extension)) {
                return true;
            }
        }
        return false;
    }

    /**
     * ファイル拡張子を取得
     */
    private String getFileExtension(String filename) {
        int lastDotIndex = filename.lastIndexOf('.');
        if (lastDotIndex == -1) {
            return "";
        }
        return filename.substring(lastDotIndex + 1);
    }

    /**
     * エラーレスポンスを作成
     */
    private Map<String, String> createErrorResponse(String message) {
        Map<String, String> error = new HashMap<>();
        error.put("error", message);
        return error;
    }
}
