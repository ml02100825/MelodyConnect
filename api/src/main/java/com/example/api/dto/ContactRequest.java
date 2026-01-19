package com.example.api.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public class ContactRequest {

    @NotNull(message = "ユーザーIDは必須です")
    private Long userId;

    @NotBlank(message = "件名は必須です")
    @Size(max = 50, message = "件名は50文字以内で入力してください")
    private String title;

    @NotBlank(message = "お問い合わせ内容は必須です")
    @Size(max = 500, message = "お問い合わせ内容は500文字以内で入力してください")
    private String content; // contact_detailに対応

    private String imageUrl;

    // コンストラクタ
    public ContactRequest() {}

    // Getters / Setters
    public Long getUserId() { return userId; }
    public void setUserId(Long userId) { this.userId = userId; }

    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }

    public String getContent() { return content; }
    public void setContent(String content) { this.content = content; }

    public String getImageUrl() { return imageUrl; }
    public void setImageUrl(String imageUrl) { this.imageUrl = imageUrl; }
}