package com.example.api.dto.admin;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

/**
 * 管理者用楽曲作成・更新リクエストDTO
 */
public class AdminSongRequest {

    @NotNull(message = "アーティストIDは必須です")
    private Long artistId;

    @NotBlank(message = "曲名は必須です")
    private String songname;

    private String spotifyTrackId;
    private Long geniusSongId;
    private String language;
    private Boolean isActive = true;

    public Long getArtistId() { return artistId; }
    public void setArtistId(Long artistId) { this.artistId = artistId; }
    public String getSongname() { return songname; }
    public void setSongname(String songname) { this.songname = songname; }
    public String getSpotifyTrackId() { return spotifyTrackId; }
    public void setSpotifyTrackId(String spotifyTrackId) { this.spotifyTrackId = spotifyTrackId; }
    public Long getGeniusSongId() { return geniusSongId; }
    public void setGeniusSongId(Long geniusSongId) { this.geniusSongId = geniusSongId; }
    public String getLanguage() { return language; }
    public void setLanguage(String language) { this.language = language; }
    public Boolean getIsActive() { return isActive; }
    public void setIsActive(Boolean isActive) { this.isActive = isActive; }
}
