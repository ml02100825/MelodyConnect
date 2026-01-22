package com.example.api.dto.admin;

import jakarta.validation.constraints.NotNull;

/**
 * 管理者ログインリクエストDTO
 */
public class AdminLoginRequest {

    @NotNull(message = "管理者IDは必須です")
    private Long adminId;

    @NotNull(message = "パスワードは必須です")
    private String password;

    // Constructors
    public AdminLoginRequest() {}

    public AdminLoginRequest(Long adminId, String password) {
        this.adminId = adminId;
        this.password = password;
    }

    // Getters and Setters
    public Long getAdminId() {
        return adminId;
    }

    public void setAdminId(Long adminId) {
        this.adminId = adminId;
    }

    public String getPassword() {
        return password;
    }

    public void setPassword(String password) {
        this.password = password;
    }
}
