package com.example.api.dto.battle;

/**
 * プレイヤー情報DTO
 * バトル開始時のユーザー情報を返すために使用
 */
public class PlayerInfoDto {
    private Long userId;
    private String username;
    private String imageUrl;
    private Integer rate;

    public PlayerInfoDto() {
    }

    public PlayerInfoDto(Long userId, String username, String imageUrl, Integer rate) {
        this.userId = userId;
        this.username = username;
        this.imageUrl = imageUrl;
        this.rate = rate;
    }

    // Getters and Setters
    public Long getUserId() {
        return userId;
    }

    public void setUserId(Long userId) {
        this.userId = userId;
    }

    public String getUsername() {
        return username;
    }

    public void setUsername(String username) {
        this.username = username;
    }

    public String getImageUrl() {
        return imageUrl;
    }

    public void setImageUrl(String imageUrl) {
        this.imageUrl = imageUrl;
    }

    public Integer getRate() {
        return rate;
    }

    public void setRate(Integer rate) {
        this.rate = rate;
    }
}
