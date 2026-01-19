package com.example.api.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * ユーザーの詳細プライバシー設定エンティティ
 * 既存のUser.privacyフィールドと連携
 */
@Entity
@Table(name = "user_privacy_settings")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserPrivacySettings {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", referencedColumnName = "user_id", nullable = false, unique = true)
    private User user;

    // === 新しい詳細設定 ===
    
    @Column(name = "show_online_status", nullable = false)
    @Builder.Default
    private boolean showOnlineStatus = true;

    @Column(name = "allow_tagging", nullable = false)
    @Builder.Default
    private boolean allowTagging = true;

    @Column(name = "allow_message_from_non_friends", nullable = false)
    @Builder.Default
    private boolean allowMessageFromNonFriends = false;

    @Column(name = "allow_friend_requests", nullable = false)
    @Builder.Default
    private boolean allowFriendRequests = true;

    @Column(name = "show_play_history", nullable = false)
    @Builder.Default
    private boolean showPlayHistory = true;

    @Column(name = "blocked_users_count", nullable = false)
    @Builder.Default
    private int blockedUsersCount = 0;

    @Column(name = "data_sharing_consent", nullable = false)
    @Builder.Default
    private boolean dataSharingConsent = false;

    @Column(name = "marketing_emails", nullable = false)
    @Builder.Default
    private boolean marketingEmails = false;

    @Column(name = "notification_sounds", nullable = false)
    @Builder.Default
    private boolean notificationSounds = true;

    @Column(name = "vibration_enabled", nullable = false)
    @Builder.Default
    private boolean vibrationEnabled = true;

    // === 管理用フィールド ===
    
    @Column(name = "last_settings_update_at")
    private LocalDateTime lastSettingsUpdateAt;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    @Version
    @Column(name = "version")
    private Long version;

    @PrePersist
    protected void onCreate() {
        LocalDateTime now = LocalDateTime.now();
        this.createdAt = now;
        this.updatedAt = now;
        this.lastSettingsUpdateAt = now;
    }

    @PreUpdate
    protected void onUpdate() {
        this.updatedAt = LocalDateTime.now();
        this.lastSettingsUpdateAt = LocalDateTime.now();
    }

    // === 既存のprivacyフィールドと連携する便利メソッド ===
    
    /**
     * 既存のUser.privacyフィールドからアカウント公開状態を取得
     * @return true=公開, false=非公開
     */
    public boolean isAccountPublic() {
        if (this.user == null) {
            return true; // デフォルト公開
        }
        return this.user.getPrivacy() == 0; // 0 = 公開
    }

    /**
     * 既存のUser.privacyフィールドを更新
     * @param isPublic true=公開, false=非公開
     */
    public void setAccountPublic(boolean isPublic) {
        if (this.user != null) {
            this.user.setPrivacy(isPublic ? 0 : 1);
        }
    }

    /**
     * 詳細設定から既存のprivacy値へのマッピング
     * 複数の詳細設定を考慮した上で、全体のプライバシーレベルを計算
     */
    public int calculatePrivacyLevel() {
        // 0 = 完全公開（すべての詳細設定が公開）
        // 1 = 制限公開（一部非公開）
        // 2 = 非公開（すべて非公開）
        
        int publicSettingsCount = 0;
        int totalSettings = 4; // 主要な設定の数
        
        if (showOnlineStatus) publicSettingsCount++;
        if (allowTagging) publicSettingsCount++;
        if (allowFriendRequests) publicSettingsCount++;
        if (showPlayHistory) publicSettingsCount++;
        
        double publicRatio = (double) publicSettingsCount / totalSettings;
        
        if (publicRatio >= 0.75) {
            return 0; // 公開
        } else if (publicRatio >= 0.25) {
            return 1; // 制限公開
        } else {
            return 2; // 非公開
        }
    }
}