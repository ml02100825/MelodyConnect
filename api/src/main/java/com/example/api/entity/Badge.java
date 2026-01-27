package com.example.api.entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import java.time.LocalDateTime;

@Data
@Entity
@Table(
    name = "badge",
    indexes = {
        @Index(name = "idx_badge_name", columnList = "badge_name")
    }
)
@NoArgsConstructor
@AllArgsConstructor
public class Badge {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "badge_id")
    private Long badgeId;

    @Column(name = "badge_name", length = 50, nullable = false)
    private String badgeName;

    @Column(name = "acq_cond", length = 200, nullable = false)
    private String acquisitionCondition;

    @Column(name = "image_url", length = 200)
    private String imageUrl;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    // ★有効フラグ
    @Column(name = "is_active", nullable = false)
    private Boolean isActive = true;

    // ★削除フラグ
    @Column(name = "is_deleted", nullable = false)
    private Boolean isDeleted = false;

    @Column(name = "active_flag")
    private Integer activeFlag;

    @Column(name = "mode")
    private Integer mode;

    @PrePersist
    void onCreate() {
        if (createdAt == null) createdAt = LocalDateTime.now();
        if (isActive == null) isActive = true;
        if (isDeleted == null) isDeleted = false;
    }

    // ===== getters / setters =====
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getBadgeName() { return badgeName; }
    public void setBadgeName(String badgeName) { this.badgeName = badgeName; }

    public String getAcquisitionCondition() { return acquisitionCondition; }
    public void setAcquisitionCondition(String acquisitionCondition) { this.acquisitionCondition = acquisitionCondition; }

    public String getImageUrl() { return imageUrl; }
    public void setImageUrl(String imageUrl) { this.imageUrl = imageUrl; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public boolean isActiveFlag() { return isActive; }
    public void setActiveFlag(boolean isActive) { this.isActive = isActive; }

    public Boolean getIsDeleted() { return isDeleted; }
    public void setIsDeleted(Boolean isDeleted) { this.isDeleted = isDeleted; }

    public String getMode() { return mode; }
    public void setMode(String mode) { this.mode = mode; }
}
