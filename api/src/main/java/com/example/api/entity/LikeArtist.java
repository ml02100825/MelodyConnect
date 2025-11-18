package com.example.api.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;

/**
 * like_artist テーブルのエンティティ
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

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "artist_id", nullable = false)
    private Artist artist;

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

    public User getUser() { return user; }
    public void setUser(User user) { this.user = user; }

    public Artist getArtist() { return artist; }
    public void setArtist(Artist artist) { this.artist = artist; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
}
