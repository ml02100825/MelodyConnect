package com.example.api.dto;

import java.util.List;

/**
 * フレンドプロフィール詳細レスポンスDTO
 */
public class FriendProfileResponse {

    private Long userId;
    private String username;
    private String userUuid;
    private String imageUrl;
    private int totalPlay;
    private Integer rate;
    private List<BadgeResponse> badges;

    public FriendProfileResponse() {
    }

    public FriendProfileResponse(Long userId, String username, String userUuid, String imageUrl,
                                  int totalPlay, Integer rate, List<BadgeResponse> badges) {
        this.userId = userId;
        this.username = username;
        this.userUuid = userUuid;
        this.imageUrl = imageUrl;
        this.totalPlay = totalPlay;
        this.rate = rate;
        this.badges = badges;
    }

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

    public String getUserUuid() {
        return userUuid;
    }

    public void setUserUuid(String userUuid) {
        this.userUuid = userUuid;
    }

    public String getImageUrl() {
        return imageUrl;
    }

    public void setImageUrl(String imageUrl) {
        this.imageUrl = imageUrl;
    }

    public int getTotalPlay() {
        return totalPlay;
    }

    public void setTotalPlay(int totalPlay) {
        this.totalPlay = totalPlay;
    }

    public Integer getRate() {
        return rate;
    }

    public void setRate(Integer rate) {
        this.rate = rate;
    }

    public List<BadgeResponse> getBadges() {
        return badges;
    }

    public void setBadges(List<BadgeResponse> badges) {
        this.badges = badges;
    }
}
