package com.example.api.dto;

/**
 * 認証レスポンスDTO
 * ログインと登録のレスポンスに使用されます
 */
public class AuthResponse {

    private Long userId;
    private String username;
    private String email;
    private String accessToken;
    private String refreshToken;
    private Long expiresIn; // アクセストークンの有効期限（ミリ秒）

    public AuthResponse() {
    }

    public AuthResponse(Long userId, String username, String email, String accessToken, String refreshToken, Long expiresIn) {
        this.userId = userId;
        this.username = username;
        this.email = email;
        this.accessToken = accessToken;
        this.refreshToken = refreshToken;
        this.expiresIn = expiresIn;
    }

    public Long getUserId() {
        return userId;
    }

    public void setUserId(Long userId) {
        this.userId = userId;
    }

    public String getUsername() {
        return username;
    }

    public void setUsername(String username) {
        this.username = username;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getAccessToken() {
        return accessToken;
    }

    public void setAccessToken(String accessToken) {
        this.accessToken = accessToken;
    }

    public String getRefreshToken() {
        return refreshToken;
    }

    public void setRefreshToken(String refreshToken) {
        this.refreshToken = refreshToken;
    }

    public Long getExpiresIn() {
        return expiresIn;
    }

    public void setExpiresIn(Long expiresIn) {
        this.expiresIn = expiresIn;
    }
}
