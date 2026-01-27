package com.example.api.dto.admin;

import java.time.Instant;

/**
 * ユーザー検索リクエストDTO（一般ユーザー検索用）
 */
public class UserSearchRequest {

    private Long id;
    private String userUuid;
    private String username;
    private String email;
    private Boolean banFlag;
    private Boolean subscribeFlag;
    private Instant createdFrom;
    private Instant createdTo;
    private Instant offlineFrom;
    private Instant offlineTo;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getUserUuid() { return userUuid; }
    public void setUserUuid(String userUuid) { this.userUuid = userUuid; }
    public String getUsername() { return username; }
    public void setUsername(String username) { this.username = username; }
    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }
    public Boolean getBanFlag() { return banFlag; }
    public void setBanFlag(Boolean banFlag) { this.banFlag = banFlag; }
    public Boolean getSubscribeFlag() { return subscribeFlag; }
    public void setSubscribeFlag(Boolean subscribeFlag) { this.subscribeFlag = subscribeFlag; }
    public Instant getCreatedFrom() { return createdFrom; }
    public void setCreatedFrom(Instant createdFrom) { this.createdFrom = createdFrom; }
    public Instant getCreatedTo() { return createdTo; }
    public void setCreatedTo(Instant createdTo) { this.createdTo = createdTo; }
    public Instant getOfflineFrom() { return offlineFrom; }
    public void setOfflineFrom(Instant offlineFrom) { this.offlineFrom = offlineFrom; }
    public Instant getOfflineTo() { return offlineTo; }
    public void setOfflineTo(Instant offlineTo) { this.offlineTo = offlineTo; }
}
