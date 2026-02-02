package com.example.api.dto;

import java.time.LocalDateTime;

/**
 * バッジ情報レスポンスDTO
 */
public class BadgeResponse {

    private Long badgeId;
    private String badgeName;
    private String description;
    private String imageUrl;
    private LocalDateTime acquiredAt;

    public BadgeResponse() {
    }

    public BadgeResponse(Long badgeId, String badgeName, String description, String imageUrl, LocalDateTime acquiredAt) {
        this.badgeId = badgeId;
        this.badgeName = badgeName;
        this.description = description;
        this.imageUrl = imageUrl;
        this.acquiredAt = acquiredAt;
    }

    public Long getBadgeId() {
        return badgeId;
    }

    public void setBadgeId(Long badgeId) {
        this.badgeId = badgeId;
    }

    public String getBadgeName() {
        return badgeName;
    }

    public void setBadgeName(String badgeName) {
        this.badgeName = badgeName;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public String getImageUrl() {
        return imageUrl;
    }

    public void setImageUrl(String imageUrl) {
        this.imageUrl = imageUrl;
    }

    public LocalDateTime getAcquiredAt() {
        return acquiredAt;
    }

    public void setAcquiredAt(LocalDateTime acquiredAt) {
        this.acquiredAt = acquiredAt;
    }
}
