package com.example.api.dto;

import jakarta.validation.constraints.NotBlank;

/**
 * ログアウト用リクエストDTO
 */
public class LogoutRequest {

    @NotBlank(message = "リフレッシュトークンは必須です")
    private String refreshToken;

    // デフォルトコンストラクタ（JSONデシリアライズ用）
    public LogoutRequest() {
    }

    public LogoutRequest(String refreshToken) {
        this.refreshToken = refreshToken;
    }

    public String getRefreshToken() {
        return refreshToken;
    }

    public void setRefreshToken(String refreshToken) {
        this.refreshToken = refreshToken;
    }
}