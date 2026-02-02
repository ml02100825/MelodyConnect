package com.example.api.controller;

import com.example.api.dto.AuthResponse;
import com.example.api.dto.LoginRequest;
import com.example.api.dto.RefreshTokenRequest;
import com.example.api.dto.RegisterRequest;
import com.example.api.entity.User;
import com.example.api.entity.User;
import com.example.api.repository.UserRepository;
import com.example.api.service.AuthService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.springframework.beans.factory.annotation.Autowired;

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

    // 依存性をfinalにして不変性を保証
    private final AuthService authService;

    /**
     * コンストラクタインジェクション
     * Springが起動時に自動的にAuthServiceを注入します
     */
    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    /**
     * ユーザー登録エンドポイント
     * 新規ユーザーを作成し、セッションを開始します。
     * @param request 登録リクエスト (メールアドレス、パスワード)
     * @param httpRequest HTTPリクエスト (IPアドレス、User-Agent取得用)
     * @return 認証レスポンス (ユーザー情報、アクセストークン、リフレッシュトークン)
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
     * メールアドレスとパスワードで認証し、トークンを発行します。
     * @param request ログインリクエスト (メールアドレス、パスワード)
     * @param httpRequest HTTPリクエスト (IPアドレス、User-Agent取得用)
     * @return 認証レスポンス (ユーザー情報、アクセストークン、リフレッシュトークン)
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
     * 有効なリフレッシュトークンを使用して、新しいアクセストークンを発行します。
     * @param request リフレッシュトークンを含むリクエスト
     * @return 認証レスポンス (新しいアクセストークンを含む)
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
     * 指定されたリフレッシュトークンに紐づくセッションを無効化（削除）します。
     * ★修正: Mapから専用DTO (LogoutRequest) に変更
     * @param request リフレッシュトークンを含むリクエスト
     * @return 成功メッセージ
     */
    @PostMapping("/logout")
    public ResponseEntity<?> logout(@Valid @RequestBody LogoutRequest request) {
        try {
            // AuthServiceの logout(String refreshToken) を呼び出す
            authService.logout(request.getRefreshToken());
            
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
     * パスワードリセット要求エンドポイント
     * メールアドレスを受け取り、リセット用コードをメールで送信します。
     * @param email リセット対象のメールアドレス
     * @return 送信完了メッセージ
     */
    @PostMapping("/request-password-reset")
    public ResponseEntity<?> requestPasswordReset(@RequestParam String email) {
        try {
            logger.info("パスワードリセット要求受信: {}", email);
            authService.requestPasswordReset(email);
            
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
     * パスワード更新実行エンドポイント
     * リセット用トークンと新しいパスワードを受け取り、パスワードを更新します。
     * ★修正: Mapから専用DTO (ResetPasswordRequest) に変更
     * @param request トークンと新パスワードを含むリクエスト
     * @return 更新完了メッセージ
     */
    @PostMapping("/reset-password")
    public ResponseEntity<?> resetPassword(@Valid @RequestBody ResetPasswordRequest request) {
        try {
            authService.resetPassword(request.getToken(), request.getNewPassword());
            
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

    @PostMapping("/withdraw")
    public ResponseEntity<?> withdraw(@AuthenticationPrincipal User user) {
        authService.withdraw(user);
        return ResponseEntity.ok(Map.of("message", "退会しました"));
    /**
     * セッション検証エンドポイント
     * アプリ起動時などに、リフレッシュトークンが有効かを確認します。
     * @param request リフレッシュトークンを含むリクエスト
     * @return 有効な場合は認証レスポンス
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
     * クライアントのIPアドレスを取得するヘルパーメソッド
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
     * JSON形式のエラーレスポンスを作成するヘルパーメソッド
     */
    private Map<String, String> createErrorResponse(String message) {
        Map<String, String> error = new HashMap<>();
        error.put("error", message);
        return error;
    }
}