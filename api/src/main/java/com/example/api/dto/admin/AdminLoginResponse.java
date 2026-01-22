package com.example.api.dto.admin;

/**
 * 管理者ログインレスポンスDTO
 */
public class AdminLoginResponse {

    private Long adminId;
    private String email;
    private String accessToken;
    private String refreshToken;
    private Long expiresIn;

    // Constructors
    public AdminLoginResponse() {}

    public AdminLoginResponse(Long adminId, String email, String accessToken, String refreshToken, Long expiresIn) {
        this.adminId = adminId;
        this.email = email;
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
