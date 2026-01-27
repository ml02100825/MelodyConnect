package com.example.api.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/**
 * パスワード更新実行用リクエストDTO
 */
public class ResetPasswordRequest {

    @NotBlank(message = "トークンは必須です")
    private String token;

    @NotBlank(message = "新しいパスワードは必須です")
    @Size(min = 8, message = "パスワードは8文字以上である必要があります")
    // 必要に応じて @Pattern などを追加して強度チェックをここでも行う
    private String newPassword;

    // デフォルトコンストラクタ
    public ResetPasswordRequest() {
    }

    public ResetPasswordRequest(String token, String newPassword) {
        this.token = token;
        this.newPassword = newPassword;
    }

    public String getToken() {
        return token;
    }

    public void setToken(String token) {
        this.token = token;
    }

    public String getNewPassword() {
        return newPassword;
    }

    public void setNewPassword(String newPassword) {
        this.newPassword = newPassword;
    }
}