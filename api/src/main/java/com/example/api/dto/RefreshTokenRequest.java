package com.example.api.dto;

import jakarta.validation.constraints.NotBlank;

/**
 * リフレッシュトークンリクエストDTO
 */
public class RefreshTokenRequest {

    @NotBlank(message = "リフレッシュトークンは必須です")
    private String refreshToken;

    public RefreshTokenRequest() {
    }

    public RefreshTokenRequest(String refreshToken) {
        this.refreshToken = refreshToken;
    }

    public String getRefreshToken() {
        return refreshToken;
    }

    public void setRefreshToken(String refreshToken) {
        this.refreshToken = refreshToken;
    }
}
