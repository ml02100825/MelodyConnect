package com.example.api.entity;

import jakarta.persistence.*;
import jakarta.validation.constraints.*;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * ユーザーエンティティクラス
 * データベースのusersテーブルにマッピングされます
 */
@Entity
@Table(name = "users",
       indexes = {
           @Index(name = "idx_users_username", columnList = "username"),
           @Index(name = "idx_users_mailaddress", columnList = "mailaddress"),
           @Index(name = "idx_users_user_uuid", columnList = "userUuid", unique = true)
       })
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "user_id")
    private Long id;

    @NotBlank
    @Size(max = 20)
    @Column(name = "username", nullable = false, length = 20)
    private String username;

    @NotBlank
    @Size(max = 30)
    @Column(name = "mailaddress", nullable = false, length = 30)
    private String mailaddress;

    @NotBlank
    @Size(max = 255)
    @Column(name = "password", nullable = false, length = 255)
    private String password;

    @Column(name = "total_play", nullable = false)
    private int totalPlay = 0;

    @Size(max = 200)
    @Column(name = "image_url", length = 200)
    private String imageUrl;

    @Min(0)
    @Max(100)
    @Column(name = "volume", nullable = false)
    private int volume = 50;

    @Column(name = "language", nullable = false)
    private int language = 0;

    @Column(name = "privacy", nullable = false)
    private int privacy = 0;

    @Column(name = "subscribe_flag", nullable = false)
    private boolean subscribeFlag = false;

    @Column(name = "accepted_at")
    private LocalDateTime acceptedAt;

    @Column(name = "life", nullable = false)
    private int life = 5;

    @Column(name = "delete_flag", nullable = false)
    private boolean deleteFlag = false;

    @Column(name = "expires_at")
    private LocalDateTime expiresAt;

    @Column(name = "canceled_at")
    private LocalDateTime canceledAt;

    @Column(name = "offline_at")
    private LocalDateTime offlineAt;

    @Column(name = "user_uuid", length = 36, nullable = true, unique = true)
    private String userUuid;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @Column(name = "ban_flag", nullable = false)
    private boolean banFlag = false;

    /**
     * エンティティ保存前の処理
     */
    @PrePersist
    protected void onCreate() {
        if (createdAt == null) {
            createdAt = LocalDateTime.now();
        }
        // userUuidは手動で設定する（フレンド申請用のユーザーID）
    }

    // ====== getters / setters ======
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getUsername() { return username; }
    public void setUsername(String username) { this.username = username; }

    public String getMailaddress() { return mailaddress; }
    public void setMailaddress(String mailaddress) { this.mailaddress = mailaddress; }

    public String getPassword() { return password; }
    public void setPassword(String password) { this.password = password; }

    public int getTotalPlay() { return totalPlay; }
    public void setTotalPlay(int totalPlay) { this.totalPlay = totalPlay; }

    public String getImageUrl() { return imageUrl; }
    public void setImageUrl(String imageUrl) { this.imageUrl = imageUrl; }

    public int getVolume() { return volume; }
    public void setVolume(int volume) { this.volume = volume; }

    public int getLanguage() { return language; }
    public void setLanguage(int language) { this.language = language; }

    public int getPrivacy() { return privacy; }
    public void setPrivacy(int privacy) { this.privacy = privacy; }

    public boolean isSubscribeFlag() { return subscribeFlag; }
    public void setSubscribeFlag(boolean subscribeFlag) { this.subscribeFlag = subscribeFlag; }

    public LocalDateTime getAcceptedAt() { return acceptedAt; }
    public void setAcceptedAt(LocalDateTime acceptedAt) { this.acceptedAt = acceptedAt; }

    public int getLife() { return life; }
    public void setLife(int life) { this.life = life; }

    public boolean isDeleteFlag() { return deleteFlag; }
    public void setDeleteFlag(boolean deleteFlag) { this.deleteFlag = deleteFlag; }

    public LocalDateTime getExpiresAt() { return expiresAt; }
    public void setExpiresAt(LocalDateTime expiresAt) { this.expiresAt = expiresAt; }

    public LocalDateTime getCanceledAt() { return canceledAt; }
    public void setCanceledAt(LocalDateTime canceledAt) { this.canceledAt = canceledAt; }

    public LocalDateTime getOfflineAt() { return offlineAt; }
    public void setOfflineAt(LocalDateTime offlineAt) { this.offlineAt = offlineAt; }

    public String getUserUuid() { return userUuid; }
    public void setUserUuid(String userUuid) { this.userUuid = userUuid; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public boolean isBanFlag() { return banFlag; }
    public void setBanFlag(boolean banFlag) { this.banFlag = banFlag; }
}
