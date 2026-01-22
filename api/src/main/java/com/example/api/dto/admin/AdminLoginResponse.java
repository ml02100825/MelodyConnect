package com.example.api.dto.admin;

/**
 * 管理者ログインレスポンスDTO
 */
public class AdminLoginResponse {

    private Long adminId;
    private String accessToken;
    private String refreshToken;
    private Long expiresIn;

    // Constructors
    public AdminLoginResponse() {}

    public AdminLoginResponse(Long adminId, String accessToken, String refreshToken, Long expiresIn) {
        this.adminId = adminId;
        this.accessToken = accessToken;
        this.refreshToken = refreshToken;
        this.expiresIn = expiresIn;
    }

    // Getters and Setters
    public Long getAdminId() {
        return adminId;
    }

    public void setAdminId(Long adminId) {
        this.adminId = adminId;
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
