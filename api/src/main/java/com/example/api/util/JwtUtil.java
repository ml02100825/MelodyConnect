package com.example.api.util;

import io.jsonwebtoken.*;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;

/**
 * JWTトークンのユーティリティクラス
 * トークンの生成、検証、解析を行います
 */
@Component
public class JwtUtil {

    @Value("${jwt.secret}")
    private String secret;

    @Value("${jwt.access-token-expiration}")
    private Long accessTokenExpiration;

    @Value("${jwt.refresh-token-expiration}")
    private Long refreshTokenExpiration;

    /**
     * 秘密鍵を取得
     * @return SecretKey
     */
    private SecretKey getSigningKey() {
        return Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
    }

    /**
     * アクセストークンを生成
     * @param userId ユーザーID
     * @param email メールアドレス
     * @return JWTアクセストークン
     */
    public String generateAccessToken(Long userId, String email) {
        Date now = new Date();
        Date expiryDate = new Date(now.getTime() + accessTokenExpiration);

        return Jwts.builder()
                .subject(userId.toString())
                .claim("email", email)
                .claim("type", "access")
                .issuedAt(now)
                .expiration(expiryDate)
                .signWith(getSigningKey())
                .compact();
    }

    /**
     * リフレッシュトークンを生成
     * @param userId ユーザーID
     * @return JWTリフレッシュトークン
     */
    public String generateRefreshToken(Long userId) {
        Date now = new Date();
        Date expiryDate = new Date(now.getTime() + refreshTokenExpiration);

        return Jwts.builder()
                .subject(userId.toString())
                .claim("type", "refresh")
                .issuedAt(now)
                .expiration(expiryDate)
                .signWith(getSigningKey())
                .compact();
    }

    /**
     * トークンからユーザーIDを取得
     * @param token JWTトークン
     * @return ユーザーID
     */
    public Long getUserIdFromToken(String token) {
        Claims claims = Jwts.parser()
                .verifyWith(getSigningKey())
                .build()
                .parseSignedClaims(token)
                .getPayload();
        return Long.parseLong(claims.getSubject());
    }

    /**
     * トークンからメールアドレスを取得
     * @param token JWTトークン
     * @return メールアドレス
     */
    public String getEmailFromToken(String token) {
        Claims claims = Jwts.parser()
                .verifyWith(getSigningKey())
                .build()
                .parseSignedClaims(token)
                .getPayload();
        return claims.get("email", String.class);
    }

    /**
     * トークンの有効性を検証
     * @param token JWTトークン
     * @return 有効な場合true
     */
    public boolean validateToken(String token) {
        try {
            Jwts.parser()
                    .verifyWith(getSigningKey())
                    .build()
                    .parseSignedClaims(token);
            return true;
        } catch (JwtException | IllegalArgumentException e) {
            // トークンが無効、期限切れ、または不正な形式の場合
            return false;
        }
    }

    /**
     * トークンのタイプを取得
     * @param token JWTトークン
     * @return トークンタイプ（"access" or "refresh"）
     */
    public String getTokenType(String token) {
        Claims claims = Jwts.parser()
                .verifyWith(getSigningKey())
                .build()
                .parseSignedClaims(token)
                .getPayload();
        return claims.get("type", String.class);
    }

    /**
     * 管理者用アクセストークンを生成
     * @param adminId 管理者ID
     * @return JWTアクセストークン（role=ADMINクレーム付き）
     */
    public String generateAdminAccessToken(Long adminId) {
        Date now = new Date();
        Date expiryDate = new Date(now.getTime() + accessTokenExpiration);

        return Jwts.builder()
                .subject(adminId.toString())
                .claim("role", "ADMIN")
                .claim("type", "access")
                .issuedAt(now)
                .expiration(expiryDate)
                .signWith(getSigningKey())
                .compact();
    }

    /**
     * 管理者用リフレッシュトークンを生成
     * @param adminId 管理者ID
     * @return JWTリフレッシュトークン（role=ADMINクレーム付き）
     */
    public String generateAdminRefreshToken(Long adminId) {
        Date now = new Date();
        Date expiryDate = new Date(now.getTime() + refreshTokenExpiration);

        return Jwts.builder()
                .subject(adminId.toString())
                .claim("role", "ADMIN")
                .claim("type", "refresh")
                .issuedAt(now)
                .expiration(expiryDate)
                .signWith(getSigningKey())
                .compact();
    }

    /**
     * トークンからロールを取得
     * @param token JWTトークン
     * @return ロール（"ADMIN" or "USER" or null）
     */
    public String getRoleFromToken(String token) {
        Claims claims = Jwts.parser()
                .verifyWith(getSigningKey())
                .build()
                .parseSignedClaims(token)
                .getPayload();
        return claims.get("role", String.class);
    }

    /**
     * アクセストークンの有効期限を取得（ミリ秒）
     * @return 有効期限
     */
    public Long getAccessTokenExpiration() {
        return accessTokenExpiration;
    }

    /**
     * リフレッシュトークンの有効期限を取得（ミリ秒）
     * @return 有効期限
     */
    public Long getRefreshTokenExpiration() {
        return refreshTokenExpiration;
    }
}
