package com.example.api.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;

/**
 * レート(rate)テーブルのエンティティ
 *
 * 物理名: rate
 * - rate_id       PK, AUTO_INCREMENT
 * - user_id       FK -> users.id
 * - season        int(3)
 * - rate          int(5) 既定値 1500
 * - updated_at    datetime
 * - created_at    datetime
 */
@Entity
@Table(
    name = "rate",
    uniqueConstraints = {
        // 1ユーザ1シーズンで一意にしたい場合
        @UniqueConstraint(name = "uk_rate_user_season", columnNames = {"user_id", "season"})
    },
    indexes = {
        @Index(name = "idx_rate_user_id", columnList = "user_id"),
        @Index(name = "idx_rate_season", columnList = "season")
    }
)
public class Rate {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "rate_id", nullable = false)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(
        name = "user_id",
        nullable = false,
        foreignKey = @ForeignKey(name = "fk_rate_user")
    )
    private User user;

    /** シーズン番号（例: 1,2,3 ...） */
    @Column(name = "season", nullable = false)
    private Integer season;

    /** レート値（初期値 1500） */
    @Column(name = "rate", nullable = false/* MySQLに既定値を付けたいなら↓を有効化 */
            // , columnDefinition = "int default 1500"
    )
    private Integer rate = 1500;

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    /* ====== ライフサイクル ====== */
    @PrePersist
    protected void onCreate() {
        final LocalDateTime now = LocalDateTime.now();
        if (createdAt == null) createdAt = now;
        updatedAt = now;
        if (rate == null) rate = 1500;
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }

    /* ====== getter / setter ====== */
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public User getUser() { return user; }
    public void setUser(User user) { this.user = user; }

    public Integer getSeason() { return season; }
    public void setSeason(Integer season) { this.season = season; }

    public Integer getRate() { return rate; }
    public void setRate(Integer rate) { this.rate = rate; }

    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
}
