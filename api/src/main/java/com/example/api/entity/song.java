package com.example.api.entity;

import java.time.LocalDateTime;

import jakarta.persistence.*;

/**
 * song テーブル Entity（ファイル名・クラス名とも物理名に合わせています）
 */
@Entity
@Table(name = "song")
public class song {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "song_id")
    private Long song_id;

    // ※定義書の物理名が「aritst_id」になっているため、そのまま採用
    @Column(name = "aritst_id", nullable = false)
    private Artist aritst_id;

    @Column(name = "songname", nullable = false, length = 1000)
    private String songname;

    @Column(name = "spotify_track_id", length = 200)
    private String spotify_track_id;

    @Column(name = "genius_song_id")
    private Long genius_song_id;

    @Column(name = "language", length = 10)
    private String language;

    @Column(name = "genre", length = 50)
    private String genre;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime created_at;

    @PrePersist
    void onCreate() {
        if (this.created_at == null) {
            this.created_at = LocalDateTime.now();
        }
    }

    // -------- getters / setters --------
    public Long getSong_id() {
        return song_id;
    }

    public void setSong_id(Long song_id) {
        this.song_id = song_id;
    }

    public Long getAritst_id() {
        return aritst_id;
    }

    public void setAritst_id(Long aritst_id) {
        this.aritst_id = aritst_id;
    }

    public String getSongname() {
        return songname;
    }

    public void setSongname(String songname) {
        this.songname = songname;
    }

    public String getSpotify_track_id() {
        return spotify_track_id;
    }

    public void setSpotify_track_id(String spotify_track_id) {
        this.spotify_track_id = spotify_track_id;
    }

    public Long getGenius_song_id() {
        return genius_song_id;
    }

    public void setGenius_song_id(Long genius_song_id) {
        this.genius_song_id = genius_song_id;
    }

    public String getLanguage() {
        return language;
    }

    public void setLanguage(String language) {
        this.language = language;
    }

    public String getGenre() {
        return genre;
    }

    public void setGenre(String genre) {
        this.genre = genre;
    }

    public LocalDateTime getCreated_at() {
        return created_at;
    }

    public void setCreated_at(LocalDateTime created_at) {
        this.created_at = created_at;
    }
}
