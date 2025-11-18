package com.example.api.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;
import java.util.Objects;

/**
 * セッションエンティティクラス
 * データベースのsessionsテーブルにマッピングされます
 */
@Entity
@Table(
    name = "sessions",
    indexes = {
        @Index(name = "idx_sessions_refresh_hash", columnList = "refresh_hash", unique = true),
        @Index(name = "idx_sessions_user_id", columnList = "user_id")
    }
)
public class Session {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "session_id")
    private Long sessionId;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false,
        foreignKey = @ForeignKey(name = "fk_sessions_user"))
    private User user;

    @Column(name = "refresh_hash", nullable = false, length = 200, unique = true)
    private String refreshHash;

    @Column(name = "expires_at", nullable = false)
    private LocalDateTime expiresAt;

    @Column(name = "user_agent", length = 200)
    private String userAgent;

    @Column(name = "ip", length = 50)
    private String ip;

    @Column(name = "revoked_flag", nullable = false)
    private Boolean revokedFlag = false;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    /**
     * デフォルトコンストラクタ
     */
    public Session() {
    }

    /**
     * コンストラクタ
     * @param user ユーザーエンティティ
     * @param refreshHash ハッシュ化されたリフレッシュトークン
     * @param expiresAt 有効期限（30日後）
     * @param userAgent ユーザーエージェント情報
     * @param ip IPアドレス
     */
    public Session(User user, String refreshHash, LocalDateTime expiresAt,
                   String userAgent, String ip) {
        this.user = user;
        this.refreshHash = refreshHash;
        this.expiresAt = expiresAt;
        this.userAgent = userAgent;
        this.ip = ip;
        this.revokedFlag = false;
    }

    /**
     * エンティティ保存前の処理
     */
    @PrePersist
    protected void onCreate() {
        this.createdAt = LocalDateTime.now();
        if (this.revokedFlag == null) {
            this.revokedFlag = false;
        }
    }

    /**
     * セッションが有効かどうかを確認
     * @return セッションが有効な場合true
     */
    public boolean isValid() {
        return !this.revokedFlag && this.expiresAt.isAfter(LocalDateTime.now());
    }

    /**
     * セッションを無効化
     */
    public void revoke() {
        this.revokedFlag = true;
    }

    /**
     * セッションの有効期限を延長（30日後に更新）
     */
    public void extendExpiration() {
        this.expiresAt = LocalDateTime.now().plusDays(30);
    }

    // Getters and Setters

    public Long getSessionId() {
        return sessionId;
    }

    public void setSessionId(Long sessionId) {
        this.sessionId = sessionId;
    }

    public User getUser() {
        return user;
    }

    public void setUser(User user) {
        this.user = user;
    }

    /**
     * ユーザーIDを取得（後方互換性のため）
     * @return ユーザーID
     */
    public Long getUserId() {
        return user != null ? user.getId() : null;
    }

    public String getRefreshHash() {
        return refreshHash;
    }

    public void setRefreshHash(String refreshHash) {
        this.refreshHash = refreshHash;
    }

    public LocalDateTime getExpiresAt() {
        return expiresAt;
    }

    public void setExpiresAt(LocalDateTime expiresAt) {
        this.expiresAt = expiresAt;
    }

    public String getUserAgent() {
        return userAgent;
    }

    public void setUserAgent(String userAgent) {
        this.userAgent = userAgent;
    }

    public String getIp() {
        return ip;
    }

    public void setIp(String ip) {
        this.ip = ip;
    }

    public Boolean getRevokedFlag() {
        return revokedFlag;
    }

    public void setRevokedFlag(Boolean revokedFlag) {
        this.revokedFlag = revokedFlag;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    // equals/hashCode は ID 基準
    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof Session)) return false;
        Session other = (Session) o;
        return sessionId != null && Objects.equals(sessionId, other.sessionId);
    }

    @Override
    public int hashCode() { return 31; }
}
