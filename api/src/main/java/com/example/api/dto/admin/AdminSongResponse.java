package com.example.api.dto.admin;

import java.time.LocalDateTime;
import java.util.List;

/**
 * 管理者用楽曲レスポンスDTO
 */
public class AdminSongResponse {

    private Long songId;
    private Long artistId;
    private String artistName;
    private String songname;
    private String spotifyTrackId;
    private Long geniusSongId;
    private String language;
    private Boolean isActive;
    private LocalDateTime createdAt;

    public Long getSongId() { return songId; }
    public void setSongId(Long songId) { this.songId = songId; }
    public Long getArtistId() { return artistId; }
    public void setArtistId(Long artistId) { this.artistId = artistId; }
    public String getArtistName() { return artistName; }
    public void setArtistName(String artistName) { this.artistName = artistName; }
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
    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public static class ListResponse {
        private List<AdminSongResponse> songs;
        private int page;
        private int size;
        private long totalElements;
        private int totalPages;

        public ListResponse(List<AdminSongResponse> songs, int page, int size, long totalElements, int totalPages) {
            this.songs = songs;
            this.page = page;
            this.size = size;
            this.totalElements = totalElements;
            this.totalPages = totalPages;
        }

        public List<AdminSongResponse> getSongs() { return songs; }
        public int getPage() { return page; }
        public int getSize() { return size; }
        public long getTotalElements() { return totalElements; }
        public int getTotalPages() { return totalPages; }
    }
}
