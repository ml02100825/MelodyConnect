package com.example.api.security;

import com.example.api.util.JwtUtil;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

/**
 * JWTトークン認証フィルター
 * リクエストヘッダーからJWTトークンを取得し、認証を行います
 */
@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private static final Logger logger = LoggerFactory.getLogger(JwtAuthenticationFilter.class);

    @Autowired
    private JwtUtil jwtUtil;

    // ★認証をスキップするパスのリスト
    private static final List<String> PUBLIC_PATHS = Arrays.asList(
        "/api/auth/register",
        "/api/auth/login",
        "/api/auth/refresh",
        "/api/auth/validate",
        "/api/upload/",
        "/uploads/",
        "/audio/",
        "/ws/",
        "/app/",
        "/topic/",
        "/queue/",
        "/actuator/",
        "/hello",
        "/samples/",
        "/api/dev/",
        "/api/vocabulary/",
        "/api/v1/rankings/" // ★ランキングAPI
    );

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {
        String requestUri = request.getRequestURI();
        String method = request.getMethod();
        
        logger.debug("=== JWT認証フィルター開始 ===");
        logger.debug("リクエスト: {} {}", method, requestUri);
        
        // ★認証不要のパスかチェック
        if (isPublicPath(requestUri)) {
            logger.debug("認証スキップ: このパスは認証不要です");
            logger.debug("=== JWT認証フィルター終了 (スキップ) ===");
            filterChain.doFilter(request, response);
            return;
        }
        
        try {
            // Authorizationヘッダーからトークンを取得
            String token = extractTokenFromRequest(request);
            
            logger.debug("トークン抽出結果: {}", token != null ? "あり (長さ: " + token.length() + ")" : "なし");

            // トークンが存在し、有効な場合
            if (token != null) {
                boolean isValid = jwtUtil.validateToken(token);
                logger.debug("トークン検証結果: {}", isValid);
                
                if (isValid) {
                    String tokenType = jwtUtil.getTokenType(token);
                    logger.debug("トークンタイプ: {}", tokenType);
                    
                    // アクセストークンであることを確認
                    if ("access".equals(tokenType)) {
                        // ユーザーIDを取得
                        Long userId = jwtUtil.getUserIdFromToken(token);
                        logger.debug("ユーザーID: {}", userId);

                        // 認証オブジェクトを作成
                        UsernamePasswordAuthenticationToken authentication =
                                new UsernamePasswordAuthenticationToken(
                                        userId,
                                        null,
                                        new ArrayList<>() // 権限リスト（必要に応じて追加）
                                );

                        authentication.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));

                        // SecurityContextに認証情報を設定
                        SecurityContextHolder.getContext().setAuthentication(authentication);
                        logger.debug("認証成功: SecurityContextに設定完了");
                    } else {
                        logger.warn("トークンタイプが不正: expected=access, actual={}", tokenType);
                    }
                } else {
                    logger.warn("トークン検証失敗");
                }
            } else {
                logger.debug("Authorizationヘッダーにトークンがありません");
            }
        } catch (Exception e) {
            // トークン検証エラーの場合、ログに記録して続行
            logger.error("JWT認証エラー: {}", e.getMessage(), e);
        }

        logger.debug("=== JWT認証フィルター終了 ===");
        
        // 次のフィルターに処理を渡す
        filterChain.doFilter(request, response);
    }

    /**
     * ★認証不要のパスかどうかをチェック
     * @param requestUri リクエストURI
     * @return 認証不要の場合true
     */
    private boolean isPublicPath(String requestUri) {
        return PUBLIC_PATHS.stream().anyMatch(requestUri::startsWith);
    }

    /**
     * リクエストからトークンを抽出
     * @param request HTTPリクエスト
     * @return JWTトークン（存在しない場合はnull）
     */
    private String extractTokenFromRequest(HttpServletRequest request) {
        String bearerToken = request.getHeader("Authorization");
        logger.debug("Authorizationヘッダー: {}", bearerToken != null ? bearerToken.substring(0, Math.min(30, bearerToken.length())) + "..." : "null");
        
        if (bearerToken != null && bearerToken.startsWith("Bearer ")) {
            return bearerToken.substring(7);
        }
        return null;
    }
}