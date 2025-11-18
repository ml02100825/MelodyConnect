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
     * ユーザー（外部キー）
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    /**
     * 単語（外部キー）
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "vocab_id", nullable = false)
    private Vocabulary vocabulary;

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
        if (learnedWordFlag == null) {
            learnedWordFlag = false;
        }
        if (favoriteFlag == null) {
            favoriteFlag = false;
        }
    }
}
