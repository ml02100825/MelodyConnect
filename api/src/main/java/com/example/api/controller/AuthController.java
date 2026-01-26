package com.example.api.controller;

import com.example.api.dto.*;
import com.example.api.service.AuthService;
import jakarta.servlet.http.HttpServletRequest;
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
 * 認証コントローラー
 * ユーザー登録、ログイン、トークンリフレッシュ、パスワードリセットのエンドポイントを提供します
 * CORS設定はWebConfigで一括管理
 */
@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private static final Logger logger = LoggerFactory.getLogger(AuthController.class);

    @Autowired
    private AuthService authService;

    /**
     * ユーザー登録エンドポイント
     */
    @PostMapping("/register")
    public ResponseEntity<?> register(@Valid @RequestBody RegisterRequest request,
                                      HttpServletRequest httpRequest) {
        try {
            String userAgent = httpRequest.getHeader("User-Agent");
            String ip = getClientIp(httpRequest);
            
            logger.info("新規登録リクエスト受信: {}", request.getEmail());

            AuthResponse response = authService.register(request, userAgent, ip);
            return ResponseEntity.status(HttpStatus.CREATED).body(response);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(createErrorResponse(e.getMessage()));
        } catch (Exception e) {
            logger.error("登録処理エラー", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(createErrorResponse("登録処理中にエラーが発生しました"));
        }
    }

    /**
     * ログインエンドポイント
     */
    @PostMapping("/login")
    public ResponseEntity<?> login(@Valid @RequestBody LoginRequest request,
                                   HttpServletRequest httpRequest) {
        try {
            String userAgent = httpRequest.getHeader("User-Agent");
            String ip = getClientIp(httpRequest);

            logger.info("ログインリクエスト受信: {}", request.getEmail());

            AuthResponse response = authService.login(request, userAgent, ip);
            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(createErrorResponse(e.getMessage()));
        } catch (Exception e) {
            logger.error("ログイン処理エラー", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(createErrorResponse("ログイン処理中にエラーが発生しました"));
        }
    }

    /**
     * トークンリフレッシュエンドポイント
     */
    @PostMapping("/refresh")
    public ResponseEntity<?> refreshToken(@Valid @RequestBody RefreshTokenRequest request) {
        try {
            AuthResponse response = authService.refreshAccessToken(request.getRefreshToken());
            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(createErrorResponse(e.getMessage()));
        } catch (Exception e) {
            logger.error("リフレッシュ処理エラー", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(createErrorResponse("トークンリフレッシュ処理中にエラーが発生しました"));
        }
    }

    /**
     * ログアウトエンドポイント
     * ★変更点: UserIdではなくRefreshTokenを受け取って特定のセッションを無効化します
     * @param request リフレッシュトークンを含むマップ
     */
    @PostMapping("/logout")
    public ResponseEntity<?> logout(@RequestBody Map<String, String> request) {
        try {
            String refreshToken = request.get("refreshToken");
            authService.logout(refreshToken);
            
            Map<String, String> response = new HashMap<>();
            response.put("message", "ログアウトしました");
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            logger.error("ログアウト処理エラー", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(createErrorResponse("ログアウト処理中にエラーが発生しました"));
        }
    }

    /**
     * パスワードリセット要求エンドポイント (★追加)
     * メールアドレスを受け取り、リセット用トークンを発行（ログ出力）します
     */
    @PostMapping("/request-password-reset")
    public ResponseEntity<?> requestPasswordReset(@RequestParam String email) {
        try {
            logger.info("パスワードリセット要求受信: {}", email);
            authService.requestPasswordReset(email);
            // セキュリティ上、メールが存在しなくても成功メッセージを返すのが一般的です
            Map<String, String> response = new HashMap<>();
            response.put("message", "パスワードリセット手順をメールで送信しました");
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            logger.error("パスワードリセット要求エラー", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(createErrorResponse("処理中にエラーが発生しました"));
        }
    }

    /**
     * パスワード更新実行エンドポイント (★追加)
     * トークンと新しいパスワードを受け取り、更新を実行します
     */
    @PostMapping("/reset-password")
    public ResponseEntity<?> resetPassword(@RequestBody Map<String, String> request) {
        try {
            String token = request.get("token");
            String newPassword = request.get("newPassword");

            if (token == null || newPassword == null) {
                return ResponseEntity.badRequest().body(createErrorResponse("トークンと新しいパスワードが必要です"));
            }

            authService.resetPassword(token, newPassword);
            
            Map<String, String> response = new HashMap<>();
            response.put("message", "パスワードを更新しました");
            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(createErrorResponse(e.getMessage()));
        } catch (Exception e) {
            logger.error("パスワード更新エラー", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(createErrorResponse("パスワード更新中にエラーが発生しました"));
        }
    }

    /**
     * セッション検証エンドポイント
     */
    @PostMapping("/validate")
    public ResponseEntity<?> validateSession(@Valid @RequestBody RefreshTokenRequest request) {
        try {
            AuthResponse response = authService.refreshAccessToken(request.getRefreshToken());
            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(createErrorResponse("セッションが無効です"));
        } catch (Exception e) {
            logger.error("セッション検証エラー", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(createErrorResponse("セッション検証中にエラーが発生しました"));
        }
    }

    /**
     * クライアントのIPアドレスを取得
     */
    private String getClientIp(HttpServletRequest request) {
        String ip = request.getHeader("X-Forwarded-For");
        if (ip == null || ip.isEmpty() || "unknown".equalsIgnoreCase(ip)) {
            ip = request.getHeader("Proxy-Client-IP");
        }
        if (ip == null || ip.isEmpty() || "unknown".equalsIgnoreCase(ip)) {
            ip = request.getHeader("WL-Proxy-Client-IP");
        }
        if (ip == null || ip.isEmpty() || "unknown".equalsIgnoreCase(ip)) {
            ip = request.getRemoteAddr();
        }
        if (ip != null && ip.contains(",")) {
            ip = ip.split(",")[0].trim();
        }
        return ip;
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