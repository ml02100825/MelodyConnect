package com.example.api.dto.admin;

import java.time.LocalDateTime;

/**
 * 管理者用ユーザー詳細レスポンスDTO（一般ユーザーの詳細表示用）
 */
public class AdminUserDetailResponse {

    private Long id;
    private String userUuid;
    private String username;
    private String email;
    private boolean banFlag;
    private boolean subscribeFlag;
    private LocalDateTime createdAt;
    private LocalDateTime offlineAt;
    private LocalDateTime acceptedAt;
    private LocalDateTime canceledAt;

    public AdminUserDetailResponse() {}

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getUserUuid() { return userUuid; }
    public void setUserUuid(String userUuid) { this.userUuid = userUuid; }
    public String getUsername() { return username; }
    public void setUsername(String username) { this.username = username; }
    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }
    public boolean isBanFlag() { return banFlag; }
    public void setBanFlag(boolean banFlag) { this.banFlag = banFlag; }
    public boolean isSubscribeFlag() { return subscribeFlag; }
    public void setSubscribeFlag(boolean subscribeFlag) { this.subscribeFlag = subscribeFlag; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
    public LocalDateTime getOfflineAt() { return offlineAt; }
    public void setOfflineAt(LocalDateTime offlineAt) { this.offlineAt = offlineAt; }
    public LocalDateTime getAcceptedAt() { return acceptedAt; }
    public void setAcceptedAt(LocalDateTime acceptedAt) { this.acceptedAt = acceptedAt; }
    public LocalDateTime getCanceledAt() { return canceledAt; }
    public void setCanceledAt(LocalDateTime canceledAt) { this.canceledAt = canceledAt; }
}
