package com.example.api.entity;
 
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import java.time.LocalDateTime;

 
import java.time.LocalDateTime;
 
/**
 * UserItemエンティティ
 * ユーザーのアイテム所持情報を管理するテーブル
 */
@Entity
@Table(name = "user_item")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class UserItem {

 
    /**
     * ユーザーアイテムID（主キー）
     */
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "user_item_id", nullable = false)
    private Integer userItemId;
 
    /**
     * ユーザーID（外部キー）
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User userId;
 
    /**
     * アイテムID（外部キー）
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "item_id", nullable = false)
    private Item itemId;
 
    /**
     * 所持数
     */
    @Column(name = "quantity", nullable = false)
    private Integer quantity = 0;
 
    /**
     * 取得日時
     */
    @Column(name = "obtained_at")
    private LocalDateTime obtainedAt;
 
    /**
     * エンティティ保存前にデフォルト値を設定
     */
    @PrePersist
    protected void onCreate() {
        if (obtainedAt == null) obtainedAt = LocalDateTime.now();
        if (quantity == null) quantity = 0;
    }
 
    /**
     * 所持数を増やす
     * @param amount 増やす数
     */
    public void addQuantity(int amount) {
        if (this.quantity == null) this.quantity = 0;
        this.quantity += amount;
    }
 
    /**
     * 所持数を減らす
     * @param amount 減らす数
     * @throws IllegalArgumentException 所持数が足りない場合
     */
    public void removeQuantity(int amount) {
        if (amount < 0) {
            throw new IllegalArgumentException("減少量は0以上でなければなりません");
        }
        if (this.quantity < amount) {
            throw new IllegalArgumentException("所持数が足りません（所持数: " + this.quantity + ", 必要数: " + amount + "）");
        }
        this.quantity -= amount;
    }
 
    /**
     * 所持数を設定
     * @param quantity 設定する数
     */
    public void setQuantity(Integer quantity) {
        if (quantity != null && quantity < 0) {
            throw new IllegalArgumentException("所持数は0以上でなければなりません");
        }
        this.quantity = quantity;
    }
 
    /**
     * アイテムを所持しているかチェック
     * @return 1個以上所持している場合true
     */
    public boolean hasItem() {
        return this.quantity != null && this.quantity > 0;
    }
 
    /**
     * 指定数以上所持しているかチェック
     * @param amount チェックする数
     * @return 指定数以上所持している場合true
     */
    public boolean hasEnough(int amount) {
        return this.quantity != null && this.quantity >= amount;
    }
}