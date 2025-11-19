package com.example.api.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/**
 * プロフィール更新リクエストDTO（ステップ2: ユーザー名、アイコン、ユーザーID設定）
 */
public class ProfileUpdateRequest {

    @NotBlank(message = "ユーザー名は必須です")
    @Size(min = 3, max = 20, message = "ユーザー名は3文字以上20文字以下である必要があります")
    private String username;

    @Size(max = 200, message = "画像URLは200文字以下である必要があります")
    private String imageUrl;

    @NotBlank(message = "ユーザーIDは必須です")
    @Size(min = 4, max = 36, message = "ユーザーIDは4文字以上36文字以下である必要があります")
    private String userUuid;

    public ProfileUpdateRequest() {
    }

    public ProfileUpdateRequest(String username, String imageUrl, String userUuid) {
        this.username = username;
        this.imageUrl = imageUrl;
        this.userUuid = userUuid;
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

    public String getUserUuid() {
        return userUuid;
    }

    public void setUserUuid(String userUuid) {
        this.userUuid = userUuid;
    }
}
