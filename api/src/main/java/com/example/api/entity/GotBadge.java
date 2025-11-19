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
        @UniqueConstraint(name = "uk_getedbadge_user_badge", columnNames = {"user_id", "badge_id"})
    }
)
public class GotBadge {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "getedbadge_id")
    private Long getedbadge_id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "badge_id", nullable = false)
    private Badge badge;

    @Column(name = "acquired_at", nullable = false)
    private LocalDateTime acquired_at;

    @PrePersist
    void onCreate() {
        if (acquired_at == null) acquired_at = LocalDateTime.now();
    }

    // ===== getters / setters =====
    public Long getGetedbadge_id() { return getedbadge_id; }
    public void setGetedbadge_id(Long getedbadge_id) { this.getedbadge_id = getedbadge_id; }

    public User getUser() { return user; }
    public void setUser(User user) { this.user = user; }

    public Badge getBadge() { return badge; }
    public void setBadge(Badge badge) { this.badge = badge; }

    public LocalDateTime getAcquired_at() { return acquired_at; }
    public void setAcquired_at(LocalDateTime acquired_at) { this.acquired_at = acquired_at; }
}
