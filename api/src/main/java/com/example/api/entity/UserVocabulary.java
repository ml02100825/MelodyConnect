package com.example.api.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * UserVocabularyエンティティ
 * ユーザーの学習済み単語情報を管理するテーブル
 */
@Entity
@Table(name = "user_vocabulary")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class UserVocabulary {

    /**
     * 学習済み単語ID（主キー）
     */
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "user_vocab_id", nullable = false)
    private Integer userVocabId;

    /**
     * ユーザーID（外部キー）
     */
    @Column(name = "user_id", nullable = false)
    private Long userId;

    /**
     * 単語ID（外部キー）
     */
    @Column(name = "vocab_id", nullable = false)
    private Integer vocabId;

    /**
     * 始めて学習した日
     */
    @Column(name = "first_learned_at", nullable = false)
    private LocalDateTime firstLearnedAt;

    /**
     * 最後に復習した日
     */
    @Column(name = "last_reviewed_at")
    private LocalDateTime lastReviewedAt;

    /**
     * 習熟度レベル
     */
    @Column(name = "mastery_level")
    private Integer masteryLevel;

    /**
     * 正解回数
     */
    @Column(name = "times_correct")
    private Integer timesCorrect;

    /**
     * 不正解回数
     */
    @Column(name = "times_incorrect")
    private Integer timesIncorrect;

    /**
     * 学習済みフラグ
     */
    @Column(name = "learned_word_flag", nullable = false)
    private Boolean learnedWordFlag;

    /**
     * お気に入りフラグ
     */
    @Column(name = "favorite_flag", nullable = false)
    private Boolean favoriteFlag;

    /**
     * エンティティ保存前にデフォルト値を設定
     */
    @PrePersist
    protected void onCreate() {
        if (firstLearnedAt == null) {
            firstLearnedAt = LocalDateTime.now();
        }
        if (lastReviewedAt == null) {
            lastReviewedAt = LocalDateTime.now();
        }
        if (masteryLevel == null) {
            masteryLevel = 1;
        }
        if (timesCorrect == null) {
            timesCorrect = 0;
        }
        if (timesIncorrect == null) {
            timesIncorrect = 0;
        }
        if (learnedWordFlag == null) {
            learnedWordFlag = false;
        }
        if (favoriteFlag == null) {
            favoriteFlag = false;
        }
    }

    /**
     * 正解数をインクリメント
     */
    public void incrementCorrect() {
        this.timesCorrect++;
        this.lastReviewedAt = LocalDateTime.now();
    }

    /**
     * 不正解数をインクリメント
     */
    public void incrementIncorrect() {
        this.timesIncorrect++;
        this.lastReviewedAt = LocalDateTime.now();
    }

    /**
     * 習熟度をレベルアップ
     */
    public void levelUp() {
        this.masteryLevel++;
    }

    /**
     * 習熟度をレベルダウン
     */
    public void levelDown() {
        if (this.masteryLevel > 1) {
            this.masteryLevel--;
        }
    }
}
