package com.example.api.dto;

import jakarta.validation.constraints.NotBlank;

/**
 * フレンド申請リクエストDTO
 */
public class FriendRequestDto {

    @NotBlank(message = "ユーザーIDは必須です")
    private String targetUserUuid;

    public FriendRequestDto() {
    }

    public FriendRequestDto(String targetUserUuid) {
        this.targetUserUuid = targetUserUuid;
    }

    public String getTargetUserUuid() {
        return targetUserUuid;
    }

    public void setTargetUserUuid(String targetUserUuid) {
        this.targetUserUuid = targetUserUuid;
    }
}
