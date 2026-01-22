package com.example.api.dto.admin;

import java.time.LocalDateTime;
import java.util.List;

public class AdminContactResponse {

    private Long contactId;
    private Long userId;
    private String userEmail;
    private String title;
    private String contactDetail;
    private String imageUrl;
    private String status;
    private String adminMemo;
    private LocalDateTime createdAt;

    public Long getContactId() { return contactId; }
    public void setContactId(Long contactId) { this.contactId = contactId; }
    public Long getUserId() { return userId; }
    public void setUserId(Long userId) { this.userId = userId; }
    public String getUserEmail() { return userEmail; }
    public void setUserEmail(String userEmail) { this.userEmail = userEmail; }
    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }
    public String getContactDetail() { return contactDetail; }
    public void setContactDetail(String contactDetail) { this.contactDetail = contactDetail; }
    public String getImageUrl() { return imageUrl; }
    public void setImageUrl(String imageUrl) { this.imageUrl = imageUrl; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public String getAdminMemo() { return adminMemo; }
    public void setAdminMemo(String adminMemo) { this.adminMemo = adminMemo; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public static class ListResponse {
        private List<AdminContactResponse> contacts;
        private int page;
        private int size;
        private long totalElements;
        private int totalPages;

        public ListResponse(List<AdminContactResponse> contacts, int page, int size, long totalElements, int totalPages) {
            this.contacts = contacts;
            this.page = page;
            this.size = size;
            this.totalElements = totalElements;
            this.totalPages = totalPages;
        }

        public List<AdminContactResponse> getContacts() { return contacts; }
        public int getPage() { return page; }
        public int getSize() { return size; }
        public long getTotalElements() { return totalElements; }
        public int getTotalPages() { return totalPages; }
    }
}
