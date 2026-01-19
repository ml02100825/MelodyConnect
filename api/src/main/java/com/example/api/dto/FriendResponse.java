package com.example.api.dto;

import java.time.LocalDateTime;

/**
 * フレンド情報レスポンスDTO
 */
public class FriendResponse {

    private Long friendId;
    private Long userId;
    private String username;
    private String userUuid;
    private String imageUrl;
    private LocalDateTime acceptedAt;

    public FriendResponse() {
    }

    public FriendResponse(Long friendId, Long userId, String username, String userUuid, String imageUrl, LocalDateTime acceptedAt) {
        this.friendId = friendId;
        this.userId = userId;
        this.username = username;
        this.userUuid = userUuid;
        this.imageUrl = imageUrl;
        this.acceptedAt = acceptedAt;
    }

    public Long getFriendId() {
        return friendId;
    }

    public void setFriendId(Long friendId) {
        this.friendId = friendId;
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

    public LocalDateTime getAcceptedAt() {
        return acceptedAt;
    }

    public void setAcceptedAt(LocalDateTime acceptedAt) {
        this.acceptedAt = acceptedAt;
    }
}
