package com.example.api.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;

/**
 * artist テーブルのエンティティ
 *
 * 物理名: artist
 * - artist_id     PK, AUTO_INCREMENT
 * - artist_name   varchar(50) NOT NULL
 * - genre         varchar(50) (任意)
 * - image_url     varchar(200) (任意)
 * - created_at    datetime NOT NULL
 */
@Entity
@Table(
    name = "artist",
    indexes = {
        @Index(name = "idx_artist_name", columnList = "artist_name"),
        @Index(name = "idx_artist_genre", columnList = "genre")
    }
)
public class Artist {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "artist_id", nullable = false)
    private Long id;

    @Column(name = "artist_name", length = 50, nullable = false)
    private String artistName;

    @Column(name = "genre", length = 50)
    private String genre;

    @Column(name = "image_url", length = 200)
    private String imageUrl;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    /* ====== lifecycle ====== */
    @PrePersist
    protected void onCreate() {
        if (createdAt == null) {
            createdAt = LocalDateTime.now().truncatedTo(ChronoUnit.SECONDS);
        }
    }

    /* ====== getters / setters ====== */
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getArtistName() { return artistName; }
    public void setArtistName(String artistName) { this.artistName = artistName; }

    public String getGenre() { return genre; }
    public void setGenre(String genre) { this.genre = genre; }

    public String getImageUrl() { return imageUrl; }
    public void setImageUrl(String imageUrl) { this.imageUrl = imageUrl; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
}
