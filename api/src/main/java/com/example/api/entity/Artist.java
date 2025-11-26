package com.example.api.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * Artistエンティティ
 * アーティスト情報を管理するテーブル
 */
@Entity
@Table(name = "artist")
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
    private Integer artistId;

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
     * エンティティ保存前に自動的に追加日時を設定
     */
    @PrePersist
    protected void onCreate() {
        if (createdAt == null) {
            createdAt = LocalDateTime.now();
        }
    }
}