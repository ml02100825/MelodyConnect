package com.example.api.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import java.time.LocalDateTime;

@Entity
@Table(name = "user_item")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class UserItem {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "user_item_id", nullable = false)
    private Integer userItemId;

    // 重要: 以前 @Column だった場所を @ManyToOne に変更
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    // 重要: 同上
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "item_id", nullable = false)
    private Item item;

    @Column(name = "quantity", nullable = false)
    private Integer quantity = 0;

    @Column(name = "obtained_at")
    private LocalDateTime obtainedAt;

    @PrePersist
    protected void onCreate() {
        if (obtainedAt == null) obtainedAt = LocalDateTime.now();
        if (quantity == null) quantity = 0;
    }

    public void addQuantity(int amount) {
        if (this.quantity == null) this.quantity = 0;
        this.quantity += amount;
    }
}