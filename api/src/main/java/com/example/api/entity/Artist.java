package com.example.api.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.Where;

import java.time.LocalDateTime;

/**
 * Artistエンティティ
 * アーティスト情報を管理するテーブル
 */
@Entity
@Table(name = "artist")
@Where(clause = "is_active = true AND is_deleted = false")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Artist {

    /**
     * アーティストID（主キー）
     */
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "artist_id", nullable = false)
    private Long artistId;

    /**
     * アーティスト名
     */
    @Column(name = "artist_name", length = 50)
    private String artistName;

    /**
     * 画像URL
     */
    @Column(name = "image_url", length = 200)
    private String imageUrl;

    /**
     * 追加日時
     */
    @Column(name = "created_at")
    private LocalDateTime createdAt;

    /**
     * 更新日時
     */
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    /**
     * アーティストAPIID
     * SpotifyAPIで使用されるID
     */
    @Column(name = "artist_api_id", length = 50)
    private String artistApiId;

    /**
     * アーティストの楽曲を最後に同期した日時
     * nullの場合は未同期
     */
    @Column(name = "last_synced_at")
    private LocalDateTime lastSyncedAt;

    /**
     * 有効フラグ
     */
    @Column(name = "is_active", nullable = false)
    private Boolean isActive = true;

    /**
     * 削除フラグ
     */
    @Column(name = "is_deleted", nullable = false)
    private Boolean isDeleted = false;

    /**
     * メインジャンルID
     * Artistテーブルのgenre_idカラムとマッピング
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "genre_id")
    private Genre genre;

    /**
     * エンティティ保存前に自動的に日時を設定
     */
    @PrePersist
    protected void onCreate() {
        if (createdAt == null) {
            createdAt = LocalDateTime.now();
        }
        if (updatedAt == null) {
            updatedAt = LocalDateTime.now();
        }
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}