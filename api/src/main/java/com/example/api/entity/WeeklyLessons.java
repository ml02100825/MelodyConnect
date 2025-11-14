package com.example.api.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;

/**
 * weeklylessons テーブルのエンティティ
 *
 * 物理名: weeklylessons
 * - weeklylessons_id  PK, AUTO_INCREMENT
 * - lessonsnum        int  既定値 0
 * - user_id           FK -> users.id
 * - created_at        datetime
 * - week_flag         boolean  (作成から1週間で false にしたい要件)
 * - updated_at        datetime
 */
@Entity
@Table(
    name = "weeklylessons",
    indexes = {
        @Index(name = "idx_weeklylessons_user_id", columnList = "user_id"),
        @Index(name = "idx_weeklylessons_week_flag", columnList = "week_flag")
    }
)
public class WeeklyLessons {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "weeklylessons_id", nullable = false)
    private Long id;

    /** 学習回数（初期値 0） */
    @Column(name = "lessonsnum", nullable = false)
    private Integer lessonsNum = 0;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(
        name = "user_id",
        nullable = false,
        foreignKey = @ForeignKey(name = "fk_weeklylessons_user")
    )
    private User user;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @Column(name = "week_flag", nullable = false)
    private Boolean weekFlag = true;

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    /* ====== ライフサイクル ====== */
    @PrePersist
    protected void onCreate() {
        final LocalDateTime now = LocalDateTime.now().truncatedTo(ChronoUnit.SECONDS);
        if (createdAt == null) createdAt = now;
        updatedAt = now;
        if (lessonsNum == null) lessonsNum = 0;
        if (weekFlag == null) weekFlag = true;
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now().truncatedTo(ChronoUnit.SECONDS);
    }

    /* ====== 便利プロパティ（DB列にはしない） ====== */
    /** 作成から1週間経過していないかどうか（true = まだ有効） */
    @Transient
    public boolean isWithinOneWeek() {
        return createdAt != null && createdAt.plusDays(7).isAfter(LocalDateTime.now());
    }

    /* ====== getter / setter ====== */
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Integer getLessonsNum() { return lessonsNum; }
    public void setLessonsNum(Integer lessonsNum) { this.lessonsNum = lessonsNum; }

    public User getUser() { return user; }
    public void setUser(User user) { this.user = user; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public Boolean getWeekFlag() { return weekFlag; }
    public void setWeekFlag(Boolean weekFlag) { this.weekFlag = weekFlag; }

    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }
}
