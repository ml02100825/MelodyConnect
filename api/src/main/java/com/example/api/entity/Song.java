package com.example.api.entity;

import java.time.LocalDateTime;

import jakarta.persistence.*;
import org.hibernate.annotations.Where;

/**
 * Song テーブル Entity（ファイル名・クラス名とも物理名に合わせています）
 */
@Entity
@Table(name = "song")
@Where(clause = "is_active = true AND is_deleted = false")
public class Song {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "song_id")
    private Long songId;

    // ※定義書の物理名が「aritst_id」になっているため、そのまま採用
    @Column(name = "aritst_id", nullable = false)
    private Long artistId;

    @Column(name = "songname", nullable = false, length = 1000)
    private String songname;

    @Column(name = "spotify_track_id", length = 200)
    private String spotifyTrackId;

    @Column(name = "genius_song_id")
    private Long geniusSongId;

    @Column(name = "language", length = 10)
    private String language;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime created_at;

    /**
     * 有効フラグ
     */
    @Column(name = "is_active", nullable = false)
    private Boolean isActive = true;

    /**
     * 削除フラグ
     */
    @Column(name = "is_deleted", nullable = false)
    private Boolean isDeleted = false;

    @PrePersist
    void onCreate() {
        if (this.created_at == null) {
            this.created_at = LocalDateTime.now();
        }
    }

    // -------- getters / setters --------
    public Long getSongId() {
        return songId;
    }

    public void setSongId(Long songId) {
        this.songId = songId;
    }

    public Long getArtistId() {
        return artistId;
    }

    public void setArtistId(Long artistId) {
        this.artistId = artistId;
    }

    public String getSongname() {
        return songname;
    }

    public void setSongname(String songname) {
        this.songname = songname;
    }

    public String getSpotifyTrackId() {
        return spotifyTrackId;
    }

    public void setSpotifyTrackId(String spotifyTrackId) {
        this.spotifyTrackId = spotifyTrackId;
    }

    public Long getGeniusSongId() {
        return geniusSongId;
    }

    public void setGeniusSongId(Long geniusSongId) {
        this.geniusSongId = geniusSongId;
    }

    public String getLanguage() {
        return language;
    }

    public void setLanguage(String language) {
        this.language = language;
    }


    public LocalDateTime getCreated_at() {
        return created_at;
    }

    public void setCreated_at(LocalDateTime created_at) {
        this.created_at = created_at;
    }

    public Boolean getIsActive() {
        return isActive;
    }

    public void setIsActive(Boolean isActive) {
        this.isActive = isActive;
    }

    public Boolean getIsDeleted() {
        return isDeleted;
    }

    public void setIsDeleted(Boolean isDeleted) {
        this.isDeleted = isDeleted;
    }




}
