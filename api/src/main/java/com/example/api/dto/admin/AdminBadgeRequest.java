package com.example.api.dto.admin;

import jakarta.validation.constraints.NotBlank;

public class AdminBadgeRequest {

    @NotBlank(message = "バッジ名は必須です")
    private String badgeName;

    @NotBlank(message = "取得条件は必須です")
    private String acquisitionCondition;

    private String imageUrl;
    private Integer mode;
    private Boolean isActive = true;

    public String getBadgeName() { return badgeName; }
    public void setBadgeName(String badgeName) { this.badgeName = badgeName; }
    public String getAcquisitionCondition() { return acquisitionCondition; }
    public void setAcquisitionCondition(String acquisitionCondition) { this.acquisitionCondition = acquisitionCondition; }
    public String getImageUrl() { return imageUrl; }
    public void setImageUrl(String imageUrl) { this.imageUrl = imageUrl; }
    public Integer getMode() { return mode; }
    public void setMode(Integer mode) { this.mode = mode; }
    public Boolean getIsActive() { return isActive; }
    public void setIsActive(Boolean isActive) { this.isActive = isActive; }
}
