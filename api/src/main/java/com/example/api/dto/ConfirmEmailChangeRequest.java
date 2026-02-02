package com.example.api.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

/**
 * メールアドレス変更確認リクエスト
 */
public class ConfirmEmailChangeRequest {

    @NotBlank(message = "トークンは必須です")
    private String token;

    @NotBlank(message = "新しいメールアドレスは必須です")
    @Email(message = "有効なメールアドレスを入力してください")
    private String newEmail;

    public String getToken() {
        return token;
    }

    public void setToken(String token) {
        this.token = token;
    }

    public String getNewEmail() {
        return newEmail;
    }

    public void setNewEmail(String newEmail) {
        this.newEmail = newEmail;
    }
}
