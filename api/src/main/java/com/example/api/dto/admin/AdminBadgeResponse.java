package com.example.api.dto.admin;

import java.time.LocalDateTime;
import java.util.List;

public class AdminBadgeResponse {

    private Long id;
    private String badgeName;
    private String acquisitionCondition;
    private String imageUrl;
    private Integer mode;
    private Boolean isActive;
    private Boolean isDeleted;
    private LocalDateTime createdAt;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getBadgeName() { return badgeName; }
    public void setBadgeName(String badgeName) { this.badgeName = badgeName; }
    public String getAcquisitionCondition() { return acquisitionCondition; }
    public void setAcquisitionCondition(String acquisitionCondition) { this.acquisitionCondition = acquisitionCondition; }
    public String getImageUrl() { return imageUrl; }
    public void setImageUrl(String imageUrl) { this.imageUrl = imageUrl; }
    public Integer getMode() { return mode; }
    public void setMode(Integer mode) { this.mode = mode; }
    public Boolean getIsActive() { return isActive; }
    public void setIsActive(Boolean isActive) { this.isActive = isActive; }
    public Boolean getIsDeleted() { return isDeleted; }
    public void setIsDeleted(Boolean isDeleted) { this.isDeleted = isDeleted; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public static class ListResponse {
        private List<AdminBadgeResponse> badges;
        private int page;
        private int size;
        private long totalElements;
        private int totalPages;

        public ListResponse(List<AdminBadgeResponse> badges, int page, int size, long totalElements, int totalPages) {
            this.badges = badges;
            this.page = page;
            this.size = size;
            this.totalElements = totalElements;
            this.totalPages = totalPages;
        }

        public List<AdminBadgeResponse> getBadges() { return badges; }
        public int getPage() { return page; }
        public int getSize() { return size; }
        public long getTotalElements() { return totalElements; }
        public int getTotalPages() { return totalPages; }
    }
}
