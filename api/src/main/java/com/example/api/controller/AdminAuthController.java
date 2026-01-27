package com.example.api.controller;

import com.example.api.dto.RefreshTokenRequest;
import com.example.api.dto.admin.AdminLoginRequest;
import com.example.api.dto.admin.AdminLoginResponse;
import com.example.api.service.AdminAuthService;
import jakarta.validation.Valid;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

/**
 * 管理者認証コントローラー
 * 管理者のログイン、トークンリフレッシュのエンドポイントを提供します
 */
@RestController
@RequestMapping("/api/admin/auth")
public class AdminAuthController {

    private static final Logger logger = LoggerFactory.getLogger(AdminAuthController.class);

    @Autowired
    private AdminAuthService adminAuthService;

    /**
     * 管理者ログインエンドポイント
     * @param request ログインリクエスト
     * @return ログインレスポンス
     */
    @PostMapping("/login")
    public ResponseEntity<?> login(@Valid @RequestBody AdminLoginRequest request) {
        try {
            logger.info("管理者ログインリクエスト受信: email={}", request.getEmail());
            AdminLoginResponse response = adminAuthService.login(request);
            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            logger.warn("管理者ログイン失敗: {}", e.getMessage());
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(createErrorResponse(e.getMessage()));
        } catch (Exception e) {
            logger.error("管理者ログイン処理中にエラー発生", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(createErrorResponse("ログイン処理中にエラーが発生しました"));
        }
    }

    /**
     * 管理者トークンリフレッシュエンドポイント
     * @param request リフレッシュトークンリクエスト
     * @return 新しいトークンを含むレスポンス
     */
    @PostMapping("/refresh")
    public ResponseEntity<?> refreshToken(@Valid @RequestBody RefreshTokenRequest request) {
        try {
            logger.info("管理者トークンリフレッシュリクエスト受信");
            AdminLoginResponse response = adminAuthService.refreshToken(request.getRefreshToken());
            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            logger.warn("管理者トークンリフレッシュ失敗: {}", e.getMessage());
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(createErrorResponse(e.getMessage()));
        } catch (Exception e) {
            logger.error("管理者トークンリフレッシュ処理中にエラー発生", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(createErrorResponse("トークンリフレッシュ処理中にエラーが発生しました"));
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
