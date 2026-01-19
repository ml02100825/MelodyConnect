package com.example.api.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

/**
 * プロフィール更新リクエストDTO
 * ユーザー名、アイコン、ユーザーID（検索用ID）を変更します
 */
public class ProfileUpdateRequest {

    @NotBlank(message = "ユーザー名は必須です")
    @Size(min = 3, max = 20, message = "ユーザー名は3文字以上20文字以下である必要があります")
    private String username;

    @Size(max = 200, message = "画像URLは200文字以下である必要があります")
    private String imageUrl;

    @NotBlank(message = "ユーザーIDは必須です")
    @Size(min = 4, max = 20, message = "ユーザーIDは4文字以上20文字以下である必要があります")
    @Pattern(regexp = "^[a-zA-Z0-9_]+$", message = "ユーザーIDは半角英数字とアンダースコアのみ使用できます")
    private String userUuid;

    // コンストラクタ
    public ProfileUpdateRequest() {}

    public ProfileUpdateRequest(String username, String imageUrl, String userUuid) {
        this.username = username;
        this.imageUrl = imageUrl;
        this.userUuid = userUuid;
    }

    // Getters / Setters
    public String getUsername() { return username; }
    public void setUsername(String username) { this.username = username; }

    public String getImageUrl() { return imageUrl; }
    public void setImageUrl(String imageUrl) { this.imageUrl = imageUrl; }

    public String getUserUuid() { return userUuid; }
    public void setUserUuid(String userUuid) { this.userUuid = userUuid; }
}