package com.example.api.dto;

import java.time.LocalDateTime;

/**
 * フレンド申請情報レスポンスDTO
 */
public class FriendRequestResponse {

    private Long friendId;
    private Long requesterId;
    private String requesterUsername;
    private String requesterUserUuid;
    private String requesterImageUrl;
    private LocalDateTime requestedAt;

    public FriendRequestResponse() {
    }

    public FriendRequestResponse(Long friendId, Long requesterId, String requesterUsername,
                                  String requesterUserUuid, String requesterImageUrl, LocalDateTime requestedAt) {
        this.friendId = friendId;
        this.requesterId = requesterId;
        this.requesterUsername = requesterUsername;
        this.requesterUserUuid = requesterUserUuid;
        this.requesterImageUrl = requesterImageUrl;
        this.requestedAt = requestedAt;
    }

    public Long getFriendId() {
        return friendId;
    }

    public void setFriendId(Long friendId) {
        this.friendId = friendId;
    }

    public Long getRequesterId() {
        return requesterId;
    }

    public void setRequesterId(Long requesterId) {
        this.requesterId = requesterId;
    }

    public String getRequesterUsername() {
        return requesterUsername;
    }

    public void setRequesterUsername(String requesterUsername) {
        this.requesterUsername = requesterUsername;
    }

    public String getRequesterUserUuid() {
        return requesterUserUuid;
    }

    public void setRequesterUserUuid(String requesterUserUuid) {
        this.requesterUserUuid = requesterUserUuid;
    }

    public String getRequesterImageUrl() {
        return requesterImageUrl;
    }

    public void setRequesterImageUrl(String requesterImageUrl) {
        this.requesterImageUrl = requesterImageUrl;
    }

    public LocalDateTime getRequestedAt() {
        return requestedAt;
    }

    public void setRequestedAt(LocalDateTime requestedAt) {
        this.requestedAt = requestedAt;
    }
}
