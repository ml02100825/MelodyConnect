package com.example.api.dto.admin;

import java.time.Instant;

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
    private Instant createdAt;
    private Instant offlineAt;
    private Instant acceptedAt;
    private Instant canceledAt;

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
    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
    public Instant getOfflineAt() { return offlineAt; }
    public void setOfflineAt(Instant offlineAt) { this.offlineAt = offlineAt; }
    public Instant getAcceptedAt() { return acceptedAt; }
    public void setAcceptedAt(Instant acceptedAt) { this.acceptedAt = acceptedAt; }
    public Instant getCanceledAt() { return canceledAt; }
    public void setCanceledAt(Instant canceledAt) { this.canceledAt = canceledAt; }
}
