package com.example.api.dto;

/**
 * ユーザーランキング用プロジェクション
 * ユーザーIDとユーザー名のみを保持
 */
public class UserRanking {
    private Long userId;
    private String username;

    // Constructors
    public UserRanking() {
    }

    public UserRanking(Long userId, String username) {
        this.userId = userId;
        this.username = username;
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
}