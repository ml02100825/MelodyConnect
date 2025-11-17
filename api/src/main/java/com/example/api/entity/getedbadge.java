package com.example.api.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(
    name = "getedbadge",
    indexes = {
        @Index(name = "idx_getedbadge_user_id", columnList = "user_id"),
        @Index(name = "idx_getedbadge_badge_id", columnList = "badge_id")
    },
    uniqueConstraints = {
        // 重複取得を禁止する場合は残す。許可するならこのブロックを削除してください。
        @UniqueConstraint(name = "uk_getedbadge_user_badge", columnNames = {"user_id", "badge_id"})
    }
)
public class getedbadge {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "getedbadge_id")
    private Long getedbadge_id;

    @Column(name = "user_id", nullable = false)
    private User user_id;

    @Column(name = "badge_id", nullable = false)
    private Badge badge_id;

    @Column(name = "acquired_at", nullable = false)
    private LocalDateTime acquired_at;

    @PrePersist
    void onCreate() {
        if (acquired_at == null) acquired_at = LocalDateTime.now();
    }

    // ===== getters / setters =====
    public Long getGetedbadge_id() { return getedbadge_id; }
    public void setGetedbadge_id(Long getedbadge_id) { this.getedbadge_id = getedbadge_id; }

    public Long getUser_id() { return user_id; }
    public void setUser_id(Long user_id) { this.user_id = user_id; }

    public Long getBadge_id() { return badge_id; }
    public void setBadge_id(Long badge_id) { this.badge_id = badge_id; }

    public LocalDateTime getAcquired_at() { return acquired_at; }
    public void setAcquired_at(LocalDateTime acquired_at) { this.acquired_at = acquired_at; }
}
