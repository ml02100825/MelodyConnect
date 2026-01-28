package com.example.api.dto.admin;

import java.time.LocalDateTime;

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
    private LocalDateTime createdFrom;
    private LocalDateTime createdTo;
    private LocalDateTime offlineFrom;
    private LocalDateTime offlineTo;

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
    public LocalDateTime getCreatedFrom() { return createdFrom; }
    public void setCreatedFrom(LocalDateTime createdFrom) { this.createdFrom = createdFrom; }
    public LocalDateTime getCreatedTo() { return createdTo; }
    public void setCreatedTo(LocalDateTime createdTo) { this.createdTo = createdTo; }
    public LocalDateTime getOfflineFrom() { return offlineFrom; }
    public void setOfflineFrom(LocalDateTime offlineFrom) { this.offlineFrom = offlineFrom; }
    public LocalDateTime getOfflineTo() { return offlineTo; }
    public void setOfflineTo(LocalDateTime offlineTo) { this.offlineTo = offlineTo; }
}
