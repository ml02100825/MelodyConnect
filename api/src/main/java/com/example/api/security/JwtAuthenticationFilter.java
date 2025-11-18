package com.example.api.security;

import com.example.api.util.JwtUtil;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.ArrayList;

/**
 * JWTトークン認証フィルター
 * リクエストヘッダーからJWTトークンを取得し、認証を行います
 */
@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    @Autowired
    private JwtUtil jwtUtil;

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {
        try {
            // Authorizationヘッダーからトークンを取得
            String token = extractTokenFromRequest(request);

            // トークンが存在し、有効な場合
            if (token != null && jwtUtil.validateToken(token)) {
                // アクセストークンであることを確認
                if ("access".equals(jwtUtil.getTokenType(token))) {
                    // ユーザーIDを取得
                    Long userId = jwtUtil.getUserIdFromToken(token);

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
                }
            }
        } catch (Exception e) {
            // トークン検証エラーの場合、ログに記録して続行
            logger.error("JWT認証エラー: " + e.getMessage());
        }

        // 次のフィルターに処理を渡す
        filterChain.doFilter(request, response);
    }

    /**
     * リクエストからトークンを抽出
     * @param request HTTPリクエスト
     * @return JWTトークン（存在しない場合はnull）
     */
    private String extractTokenFromRequest(HttpServletRequest request) {
        String bearerToken = request.getHeader("Authorization");
        if (bearerToken != null && bearerToken.startsWith("Bearer ")) {
            return bearerToken.substring(7);
        }
        return null;
    }
}
