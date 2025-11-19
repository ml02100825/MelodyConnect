package com.example.api.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

/**
 * ユーザー登録リクエストDTO（ステップ1: 認証情報のみ）
 * ユーザー名とアイコンは後でプロフィール設定画面で設定
 */
public class RegisterRequest {

    @NotBlank(message = "メールアドレスは必須です")
    @Email(message = "有効なメールアドレスを入力してください")
    @Size(max = 30, message = "メールアドレスは30文字以下である必要があります")
    private String email;

    @NotBlank(message = "パスワードは必須です")
    @Size(min = 8, max = 50, message = "パスワードは8文字以上50文字以下である必要があります")
    @Pattern(
        regexp = "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)(?=.*[@$!%*?&#])[A-Za-z\\d@$!%*?&#]+$",
        message = "パスワードは大文字、小文字、数字、特殊文字を含む必要があります"
    )
    private String password;

    @NotBlank(message = "ユーザーIDは必須です")
    @Size(min = 4, max = 20, message = "ユーザーIDは4文字以上20文字以下である必要があります")
    @Pattern(
        regexp = "^[a-zA-Z0-9_]+$",
        message = "ユーザーIDは英数字とアンダースコアのみ使用できます"
    )
    private String userUuid;

    public RegisterRequest() {
    }

    public RegisterRequest(String email, String password, String userUuid) {
        this.email = email;
        this.password = password;
        this.userUuid = userUuid;
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

    public String getUserUuid() {
        return userUuid;
    }

    public void setUserUuid(String userUuid) {
        this.userUuid = userUuid;
    }
}
