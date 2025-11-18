package com.example.api.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;

/**
 * friend テーブルのエンティティ
 *
 * 物理名: friend
 * - friend_id     PK, AUTO_INCREMENT
 * - user_id_low   int  NOT NULL  … 小さい方のユーザーID
 * - user_id_high  int  NOT NULL  … 大きい方のユーザーID
 * - friend_flag   boolean NOT NULL  … 相互承認済みか
 * - invite_flag   boolean NOT NULL  … 招待送信済みか
 * - requester_id  int NOT NULL      … 申請者ユーザーID
 * - accepted_at   datetime          … 承認日時
 * - requested_at  datetime NOT NULL … 申請日時
 *
 * (user_id_low, user_id_high) の組でユニーク。
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

    @Column(name = "user_id_low", nullable = false)
    private User userIdLow;

    @Column(name = "user_id_high", nullable = false)
    private User userIdHigh;

    @Column(name = "friend_flag", nullable = false)
    private Boolean friendFlag;

    @Column(name = "invite_flag", nullable = false)
    private Boolean inviteFlag;

    @Column(name = "requester_id", nullable = false)
    private User requesterId;

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

    public Long getUserIdLow() { return userIdLow; }
    public void setUserIdLow(Long userIdLow) { this.userIdLow = userIdLow; }

    public Long getUserIdHigh() { return userIdHigh; }
    public void setUserIdHigh(Long userIdHigh) { this.userIdHigh = userIdHigh; }

    public Boolean getFriendFlag() { return friendFlag; }
    public void setFriendFlag(Boolean friendFlag) { this.friendFlag = friendFlag; }

    public Boolean getInviteFlag() { return inviteFlag; }
    public void setInviteFlag(Boolean inviteFlag) { this.inviteFlag = inviteFlag; }

    public Long getRequesterId() { return requesterId; }
    public void setRequesterId(Long requesterId) { this.requesterId = requesterId; }

    public LocalDateTime getAcceptedAt() { return acceptedAt; }
    public void setAcceptedAt(LocalDateTime acceptedAt) { this.acceptedAt = acceptedAt; }

    public LocalDateTime getRequestedAt() { return requestedAt; }
    public void setRequestedAt(LocalDateTime requestedAt) { this.requestedAt = requestedAt; }
}
