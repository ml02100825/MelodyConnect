package com.example.api.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;

/**
 * セッションエンティティクラス
 * データベースのsessionsテーブルにマッピングされます
 */
@Entity
@Table(name = "sessions")
public class Session {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "session_id")
    private Long sessionId;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "refresh_hash", nullable = false, length = 200)
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
     * @param userId ユーザーID
     * @param refreshHash ハッシュ化されたリフレッシュトークン
     * @param expiresAt 有効期限（30日後）
     * @param userAgent ユーザーエージェント情報
     * @param ip IPアドレス
     */
    public Session(Long userId, String refreshHash, LocalDateTime expiresAt,
                   String userAgent, String ip) {
        this.userId = userId;
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

    public Long getUserId() {
        return userId;
    }

    public void setUserId(Long userId) {
        this.userId = userId;
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
}
