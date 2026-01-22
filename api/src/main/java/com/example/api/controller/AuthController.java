package com.example.api.controller;

import com.example.api.dto.*;
import com.example.api.entity.User;
import com.example.api.repository.UserRepository;
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
 * CORS設定はWebConfigで一括管理
 */
@RestController
@RequestMapping("/api/auth")
public class AuthController {

    @Autowired
    private AuthService authService;

    @Autowired
    private UserRepository userRepository;

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
            User user = userRepository.findById(userId)
                    .orElseThrow(() -> new IllegalArgumentException("ユーザーが見つかりません"));
            authService.logout(user);
            Map<String, String> response = new HashMap<>();
            response.put("message", "ログアウトしました");
            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(createErrorResponse(e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(createErrorResponse("ログアウト処理中にエラーが発生しました"));
        }
    }

    /**
     * 退会（アカウント削除）エンドポイント
     * TODO: @param userId ユーザーID
     * @return 成功メッセージ
     */
    @DeleteMapping("/withdraw/{userId}")
    public ResponseEntity<?> withdraw(@PathVariable Long userId) {
        try {
            User user = userRepository.findById(userId) // id取得
                    .orElseThrow(() -> new IllegalArgumentException("ユーザーが見つかりません"));
            authService.withdraw(user); //////////////////
            Map<String, String> response = new HashMap<>();
            response.put("message", "退会処理が完了しました");
            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(createErrorResponse(e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(createErrorResponse("退会処理中にエラーが発生しました"));
        }
    }

    /**
     * セッション検証エンドポイント
     * リフレッシュトークンを使ってセッションの有効性を確認する
     * 有効な場合は新しいアクセストークンを発行する
     * @param request リフレッシュトークンリクエスト
     * @return 認証レスポンス（有効な場合）または401（無効な場合）
     */
    @PostMapping("/validate")
    public ResponseEntity<?> validateSession(@Valid @RequestBody RefreshTokenRequest request) {
        try {
            AuthResponse response = authService.refreshAccessToken(request.getRefreshToken());
            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            // セッションが無効（失効、revoke済み、または不正なトークン）
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(createErrorResponse("セッションが無効です"));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(createErrorResponse("セッション検証中にエラーが発生しました"));
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
