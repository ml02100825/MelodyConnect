package com.example.api.entity;

import com.example.api.enums.QuestionFormat;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * Questionエンティティ
 * 問題情報を管理するテーブル
 */
@Entity
@Table(name = "question")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Question {

    /**
     * 問題ID（主キー）
     */
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "question_id", nullable = false)
    private Integer questionId;

    /**
     * 楽曲名ID（外部キー）
     */
    @Column(name = "song_id", nullable = false)
    private Song songId;

    /**
     * アーティストID（外部キー）
     */
    @Column(name = "artist_id", nullable = false)
    private Artist artistnameId;

    /**
     * 問題文
     */
    @Column(name = "text", length = 100, nullable = false)
    private String text;

    /**
     * 答え
     */
    @Column(name = "answer", length = 100, nullable = false)
    private String answer;

    /**
     * 追加日時
     */
    @Column(name = "adding_at", nullable = false)
    private LocalDateTime addingAt;

    /**
     * 問題形式
     * listening等の形式を指定
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "question_format", nullable = false)
    private QuestionFormat questionFormat;

    /**
     * 楽曲ID（外部キー）
     */
    @Column(name = "song_id", nullable = false)
    private Integer songId;

    /**
     * 難易度レベル
     * wordnIkAPIから取得される値
     */
    @Column(name = "difficulty_level")
    private Integer difficultyLevel;

    /**
     * 言語
     */
    @Column(name = "language", length = 20)
    private String language;

    /**
     * エンティティ保存前に自動的に追加日時を設定
     */
    @PrePersist
    protected void onCreate() {
        if (addingAt == null) {
            addingAt = LocalDateTime.now();
        }
    }
}