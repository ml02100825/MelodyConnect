package com.example.api.dto;

import com.fasterxml.jackson.annotation.JsonIgnore;

/**
 * ランキングエントリーDTO
 */
public class RankingEntryDto {
    private int rank;
    private String name;
    private int rate;
    private boolean isMe;
    private boolean isFriend;
    
    @JsonIgnore // ★JSONレスポンスには含めない（内部処理用）
    private Long userId;

    // Getters and Setters
    public int getRank() {
        return rank;
    }

    public void setRank(int rank) {
        this.rank = rank;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public int getRate() {
        return rate;
    }

    public void setRate(int rate) {
        this.rate = rate;
    }

    public boolean isMe() {
        return isMe;
    }

    public void setMe(boolean me) {
        isMe = me;
    }

    public boolean isFriend() {
        return isFriend;
    }

    public void setFriend(boolean friend) {
        isFriend = friend;
    }

    public Long getUserId() {
        return userId;
    }

    public void setUserId(Long userId) {
        this.userId = userId;
    }
}