package com.example.api.entity;
 
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
 
import java.time.LocalDateTime;
 
@Entity
@Table(name = "item")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Item {
 
    /**
     * アイテムID（主キー）
     */
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "item_id", nullable = false)
    private Integer itemId;
 
    /**
     * 表示名
     */
    @Column(name = "name", length = 100, nullable = false)
    private String name;
 
    /**
     * 説明文
     */
    @Column(name = "description", length = 255)
    private String description;
 
    /**
     * 回復量（固定回復）
     */
    @Column(name = "heal_amount", nullable = false)
    private Integer healAmount;
 
    /**
     * 利用可否フラグ（管理者が停止する場合に使用）
     */
    @Column(name = "is_active", nullable = false)
    private Boolean isActive = true;
 
    /**
     * 作成日時
     */
    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;
 
    /**
     * 更新日時
     */
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
 
    /**
     * 楽観ロック用バージョン
     */
    @Version
    @Column(name = "version")
    private Long version;
 
    /**
     * 新規作成時の初期値設定
     */
    @PrePersist
    protected void onCreate() {
        LocalDateTime now = LocalDateTime.now();
        if (createdAt == null) createdAt = now;
        if (updatedAt == null) updatedAt = now;
        if (isActive == null) isActive = true;
    }
 
    /**
     * 更新時刻の更新
     */
    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}