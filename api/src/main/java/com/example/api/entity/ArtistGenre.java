package com.example.api.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(
    name = "artist_genre",
    indexes = {
        @Index(name = "idx_artist_genre_artist", columnList = "artist_id"),
        @Index(name = "idx_artist_genre_genre",  columnList = "genre_id")
    },
    uniqueConstraints = {
        @UniqueConstraint(
            name = "uk_artist_genre_artist_genre",
            columnNames = {"artist_id", "genre_id"}
        )
    }
)
public class ArtistGenre {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "artist_genre_id")
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(
        name = "artist_id",
        nullable = false,
        foreignKey = @ForeignKey(name = "fk_artist_genre_artist")
    )
    private Artist artist;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(
        name = "genre_id",
        nullable = false,
        foreignKey = @ForeignKey(name = "fk_artist_genre_genre")
    )
    private Genre genre;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @PrePersist
    void onCreate() {
        if (createdAt == null) createdAt = LocalDateTime.now();
    }

    // ====== getter / setter ======
    public Long getId() { return id; }
    public Artist getArtist() { return artist; }
    public Genre getGenre() { return genre; }
    public LocalDateTime getCreatedAt() { return createdAt; }

    public void setId(Long id) { this.id = id; }
    public void setArtist(Artist artist) { this.artist = artist; }
    public void setGenre(Genre genre) { this.genre = genre; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
}
