package com.example.api.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

/**
 * ユーザー登録リクエストDTO
 */
public class RegisterRequest {

    @NotBlank(message = "ユーザー名は必須です")
    @Size(min = 3, max = 20, message = "ユーザー名は3文字以上20文字以下である必要があります")
    private String username;

    @NotBlank(message = "メールアドレスは必須です")
    @Email(message = "有効なメールアドレスを入力してください")
    @Size(max = 30, message = "メールアドレスは30文字以下である必要があります")
    private String email;

    @NotBlank(message = "パスワードは必須です")
    @Size(min = 8, max = 100, message = "パスワードは8文字以上100文字以下である必要があります")
    @Pattern(
        regexp = "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)(?=.*[@$!%*?&#])[A-Za-z\\d@$!%*?&#]+$",
        message = "パスワードは大文字、小文字、数字、特殊文字を含む必要があります"
    )
    private String password;

    public RegisterRequest() {
    }

    public RegisterRequest(String username, String email, String password) {
        this.username = username;
        this.email = email;
        this.password = password;
    }

    public String getUsername() {
        return username;
    }

    public void setUsername(String username) {
        this.username = username;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getPassword() {
        return password;
    }

    public void setPassword(String password) {
        this.password = password;
    }
}
