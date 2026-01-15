package com.example.api.entity;

import jakarta.persistence.*;

@Entity
@Table(name = "friend")
public class FriendRanking {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "friend_user_id", nullable = false)
    private Long friendUserId;

    @Column(name = "status")
    private String status;

    // getters / setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Long getUserId() { return userId; }
    public void setUserId(Long userId) { this.userId = userId; }
    public Long getFriendUserId() { return friendUserId; }
    public void setFriendUserId(Long friendUserId) { this.friendUserId = friendUserId; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
}