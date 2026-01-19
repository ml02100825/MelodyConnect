// package は他のクラスに合わせて
package com.example.api.dto;

public class FriendAcceptRequestDto {
    private Long loginUserId;
    private Long otherUserId;

    public Long getLoginUserId() {
        return loginUserId;
    }

    public void setLoginUserId(Long loginUserId) {
        this.loginUserId = loginUserId;
    }

    public Long getOtherUserId() {
        return otherUserId;
    }

    public void setOtherUserId(Long otherUserId) {
        this.otherUserId = otherUserId;
    }
}
