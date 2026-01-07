package com.example.api.dto;

/**
 * ユーザー検索結果レスポンスDTO
 */
public class UserSearchResponse {

    private Long userId;
    private String username;
    private String userUuid;
    private String imageUrl;

    public UserSearchResponse() {
    }

    public UserSearchResponse(Long userId, String username, String userUuid, String imageUrl) {
        this.userId = userId;
        this.username = username;
        this.userUuid = userUuid;
        this.imageUrl = imageUrl;
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
}
