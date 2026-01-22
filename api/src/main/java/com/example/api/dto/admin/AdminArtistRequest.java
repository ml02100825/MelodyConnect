package com.example.api.dto.admin;

import jakarta.validation.constraints.NotBlank;

public class AdminArtistRequest {

    @NotBlank(message = "アーティスト名は必須です")
    private String artistName;

    private String imageUrl;
    private String artistApiId;
    private Boolean isActive = true;

    public String getArtistName() { return artistName; }
    public void setArtistName(String artistName) { this.artistName = artistName; }
    public String getImageUrl() { return imageUrl; }
    public void setImageUrl(String imageUrl) { this.imageUrl = imageUrl; }
    public String getArtistApiId() { return artistApiId; }
    public void setArtistApiId(String artistApiId) { this.artistApiId = artistApiId; }
    public Boolean getIsActive() { return isActive; }
    public void setIsActive(Boolean isActive) { this.isActive = isActive; }
}
