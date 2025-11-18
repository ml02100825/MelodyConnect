package com.example.demo.entity;

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
    private User userId;

    /**
     * 単語ID（外部キー）
     */
    @Column(name = "vocab_id", nullable = false)
    private Vocaublary vocabId;


    /**
     * 始めて学習した日
     */
    @Column(name = "first_learned_at", nullable = false)
    private LocalDateTime firstLearnedAt;



  

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
        if (mastaryLevel == null) {
            mastaryLevel = 1;
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
        this.mastaryLevel++;
    }

    /**
     * 習熟度をレベルダウン
     */
    public void levelDown() {
        if (this.mastaryLevel > 1) {
            this.mastaryLevel--;
        }
    }
}