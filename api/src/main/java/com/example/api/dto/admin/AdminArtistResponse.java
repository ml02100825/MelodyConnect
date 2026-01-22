package com.example.api.dto.admin;

import java.time.LocalDateTime;
import java.util.List;

public class AdminArtistResponse {

    private Long artistId;
    private String artistName;
    private String imageUrl;
    private String artistApiId;
    private Boolean isActive;
    private LocalDateTime createdAt;
    private LocalDateTime lastSyncedAt;

    public Long getArtistId() { return artistId; }
    public void setArtistId(Long artistId) { this.artistId = artistId; }
    public String getArtistName() { return artistName; }
    public void setArtistName(String artistName) { this.artistName = artistName; }
    public String getImageUrl() { return imageUrl; }
    public void setImageUrl(String imageUrl) { this.imageUrl = imageUrl; }
    public String getArtistApiId() { return artistApiId; }
    public void setArtistApiId(String artistApiId) { this.artistApiId = artistApiId; }
    public Boolean getIsActive() { return isActive; }
    public void setIsActive(Boolean isActive) { this.isActive = isActive; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
    public LocalDateTime getLastSyncedAt() { return lastSyncedAt; }
    public void setLastSyncedAt(LocalDateTime lastSyncedAt) { this.lastSyncedAt = lastSyncedAt; }

    public static class ListResponse {
        private List<AdminArtistResponse> artists;
        private int page;
        private int size;
        private long totalElements;
        private int totalPages;

        public ListResponse(List<AdminArtistResponse> artists, int page, int size, long totalElements, int totalPages) {
            this.artists = artists;
            this.page = page;
            this.size = size;
            this.totalElements = totalElements;
            this.totalPages = totalPages;
        }

        public List<AdminArtistResponse> getArtists() { return artists; }
        public int getPage() { return page; }
        public int getSize() { return size; }
        public long getTotalElements() { return totalElements; }
        public int getTotalPages() { return totalPages; }
    }
}
