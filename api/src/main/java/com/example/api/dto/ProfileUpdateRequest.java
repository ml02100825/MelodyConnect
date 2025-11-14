package com.example.api.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/**
 * プロフィール更新リクエストDTO（ステップ2: ユーザー名とアイコン設定）
 */
public class ProfileUpdateRequest {

    @NotBlank(message = "ユーザー名は必須です")
    @Size(min = 3, max = 20, message = "ユーザー名は3文字以上20文字以下である必要があります")
    private String username;

    @Size(max = 200, message = "画像URLは200文字以下である必要があります")
    private String imageUrl;

    public ProfileUpdateRequest() {
    }

    public ProfileUpdateRequest(String username, String imageUrl) {
        this.username = username;
        this.imageUrl = imageUrl;
    }

    public String getUsername() {
        return username;
    }

    public void setUsername(String username) {
        this.username = username;
    }

    public String getImageUrl() {
        return imageUrl;
    }

    public void setImageUrl(String imageUrl) {
        this.imageUrl = imageUrl;
    }
}
