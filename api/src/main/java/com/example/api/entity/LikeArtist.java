package com.example.api.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;

/**
 * like_artist テーブルのエンティティ
 *
 * 物理名: like_artist
 * - like_artist   PK, AUTO_INCREMENT
 * - user_id       int NOT NULL
 * - artist_id     int NOT NULL
 * - created_at    datetime NOT NULL
 *
 * 同一ユーザーが同一アーティストを重複登録しないように
 * (user_id, artist_id) のユニーク制約を付与。
 */
@Entity
@Table(
    name = "like_artist",
    uniqueConstraints = {
        @UniqueConstraint(name = "uk_like_artist_user_artist", columnNames = {"user_id", "artist_id"})
    },
    indexes = {
        @Index(name = "idx_like_artist_user", columnList = "user_id"),
        @Index(name = "idx_like_artist_artist", columnList = "artist_id")
    }
)
public class LikeArtist {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "like_artist", nullable = false)
    private Long id;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "artist_id", nullable = false)
    private Integer artistId;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    /* ===== lifecycle ===== */
    @PrePersist
    protected void onCreate() {
        if (createdAt == null) {
            createdAt = LocalDateTime.now().truncatedTo(ChronoUnit.SECONDS);
        }
    }

    /* ===== getters / setters ===== */
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Long getUserId() { return userId; }
    public void setUserId(Long userId) { this.userId = userId; }

    public Long getArtistId() { return artistId; }
    public void setArtistId(Long artistId) { this.artistId = artistId; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
}
