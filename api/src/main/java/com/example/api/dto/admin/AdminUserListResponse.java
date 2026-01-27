package com.example.api.dto.admin;

import java.time.Instant;
import java.util.List;

/**
 * 管理者用ユーザー一覧レスポンスDTO
 */
public class AdminUserListResponse {

    private List<AdminUserSummary> users;
    private int page;
    private int size;
    private long totalElements;
    private int totalPages;

    // Constructors
    public AdminUserListResponse() {}

    public AdminUserListResponse(List<AdminUserSummary> users, int page, int size, long totalElements, int totalPages) {
        this.users = users;
        this.page = page;
        this.size = size;
        this.totalElements = totalElements;
        this.totalPages = totalPages;
    }

    // Inner class for user summary
    public static class AdminUserSummary {
        private Long id;
        private String userUuid;
        private String username;
        private String email;
        private boolean banFlag;
        private boolean subscribeFlag;
        private Instant createdAt;
        private Instant offlineAt;

        public AdminUserSummary() {}

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
    }

    // Getters and Setters
    public List<AdminUserSummary> getUsers() { return users; }
    public void setUsers(List<AdminUserSummary> users) { this.users = users; }
    public int getPage() { return page; }
    public void setPage(int page) { this.page = page; }
    public int getSize() { return size; }
    public void setSize(int size) { this.size = size; }
    public long getTotalElements() { return totalElements; }
    public void setTotalElements(long totalElements) { this.totalElements = totalElements; }
    public int getTotalPages() { return totalPages; }
    public void setTotalPages(int totalPages) { this.totalPages = totalPages; }
}
