package com.example.api.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;

/**
 * friend テーブルのエンティティ
 */
@Entity
@Table(
    name = "friend",
    uniqueConstraints = {
        @UniqueConstraint(name = "uk_friend_pair", columnNames = {"user_id_low", "user_id_high"})
    },
    indexes = {
        @Index(name = "idx_friend_low", columnList = "user_id_low"),
        @Index(name = "idx_friend_high", columnList = "user_id_high"),
        @Index(name = "idx_friend_requester", columnList = "requester_id")
    }
)
public class Friend {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "friend_id", nullable = false)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id_low", nullable = false)
    private User userLow;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id_high", nullable = false)
    private User userHigh;

    @Column(name = "friend_flag", nullable = false)
    private Boolean friendFlag;

    @Column(name = "invite_flag", nullable = false)
    private Boolean inviteFlag;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "requester_id", nullable = false)
    private User requester;

    @Column(name = "accepted_at")
    private LocalDateTime acceptedAt;

    @Column(name = "requested_at", nullable = false)
    private LocalDateTime requestedAt;

    /* ===== lifecycle ===== */
    @PrePersist
    protected void onCreate() {
        if (requestedAt == null) {
            requestedAt = LocalDateTime.now().truncatedTo(ChronoUnit.SECONDS);
        }
        if (friendFlag == null) friendFlag = Boolean.FALSE;
        if (inviteFlag == null) inviteFlag = Boolean.FALSE;
    }

    /* ===== getters / setters ===== */
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public User getUserLow() { return userLow; }
    public void setUserLow(User userLow) { this.userLow = userLow; }

    public User getUserHigh() { return userHigh; }
    public void setUserHigh(User userHigh) { this.userHigh = userHigh; }

    public Boolean getFriendFlag() { return friendFlag; }
    public void setFriendFlag(Boolean friendFlag) { this.friendFlag = friendFlag; }

    public Boolean getInviteFlag() { return inviteFlag; }
    public void setInviteFlag(Boolean inviteFlag) { this.inviteFlag = inviteFlag; }

    public User getRequester() { return requester; }
    public void setRequester(User requester) { this.requester = requester; }

    public LocalDateTime getAcceptedAt() { return acceptedAt; }
    public void setAcceptedAt(LocalDateTime acceptedAt) { this.acceptedAt = acceptedAt; }

    public LocalDateTime getRequestedAt() { return requestedAt; }
    public void setRequestedAt(LocalDateTime requestedAt) { this.requestedAt = requestedAt; }
}
