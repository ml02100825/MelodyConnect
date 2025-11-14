package com.example.api.controller;

import com.example.api.dto.*;
import com.example.api.service.AuthService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

/**
 * 認証コントローラー
 * ユーザー登録、ログイン、トークンリフレッシュのエンドポイントを提供します
 */
@RestController
@RequestMapping("/api/auth")
@CrossOrigin(origins = "*") // 本番環境では適切なオリジンを指定してください
public class AuthController {

    @Autowired
    private AuthService authService;

    /**
     * ユーザー登録エンドポイント
     * @param request 登録リクエスト
     * @param httpRequest HTTPリクエスト
     * @return 認証レスポンス
     */
    @PostMapping("/register")
    public ResponseEntity<?> register(@Valid @RequestBody RegisterRequest request,
                                      HttpServletRequest httpRequest) {
        try {
            String userAgent = httpRequest.getHeader("User-Agent");
            String ip = getClientIp(httpRequest);

            AuthResponse response = authService.register(request, userAgent, ip);
            return ResponseEntity.status(HttpStatus.CREATED).body(response);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(createErrorResponse(e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(createErrorResponse("登録処理中にエラーが発生しました"));
        }
    }

    /**
     * ログインエンドポイント
     * @param request ログインリクエスト
     * @param httpRequest HTTPリクエスト
     * @return 認証レスポンス
     */
    @PostMapping("/login")
    public ResponseEntity<?> login(@Valid @RequestBody LoginRequest request,
                                   HttpServletRequest httpRequest) {
        try {
            String userAgent = httpRequest.getHeader("User-Agent");
            String ip = getClientIp(httpRequest);

            AuthResponse response = authService.login(request, userAgent, ip);
            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(createErrorResponse(e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(createErrorResponse("ログイン処理中にエラーが発生しました"));
        }
    }

    /**
     * トークンリフレッシュエンドポイント
     * @param request リフレッシュトークンリクエスト
     * @return 新しいアクセストークンを含む認証レスポンス
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
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(createErrorResponse("トークンリフレッシュ処理中にエラーが発生しました"));
        }
    }

    /**
     * ログアウトエンドポイント
     * @param userId ユーザーID
     * @return 成功メッセージ
     */
    @PostMapping("/logout/{userId}")
    public ResponseEntity<?> logout(@PathVariable Long userId) {
        try {
            authService.logout(userId);
            Map<String, String> response = new HashMap<>();
            response.put("message", "ログアウトしました");
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(createErrorResponse("ログアウト処理中にエラーが発生しました"));
        }
    }

    /**
     * クライアントのIPアドレスを取得
     * @param request HTTPリクエスト
     * @return IPアドレス
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
        // 複数のIPがある場合は最初のものを使用
        if (ip != null && ip.contains(",")) {
            ip = ip.split(",")[0].trim();
        }
        return ip;
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
