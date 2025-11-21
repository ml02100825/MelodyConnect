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
     * 楽曲（外部キー）
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "song_id", nullable = false)
    private Song song;

    /**
     * アーティスト（外部キー）
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "artist_id", nullable = false)
    private Artist artist;

    /**
     * 問題文（穴埋めの場合は空欄「_____」を含む）
     */
    @Column(name = "text", length = 100, nullable = false)
    private String text;

    /**
     * 答え（空欄に入る単語）
     */
    @Column(name = "answer", length = 100, nullable = false)
    private String answer;

    /**
     * 完全な文（穴埋め問題の場合、空欄が埋まった状態の文）
     */
    @Column(name = "complete_sentence", length = 200)
    private String completeSentence;

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
     * 難易度レベル
     * wordnikAPIから取得される値
     */
    @Column(name = "difficulty_level")
    private Integer difficultyLevel;

    /**
     * 学習焦点
     * vocabulary, grammar, collocation, idiom等
     */
    @Column(name = "skill_focus", length = 50)
    private String skillFocus;

    /**
     * 言語
     */
    @Column(name = "language", length = 20)
    private String language;

    /**
     * 和訳
     */
    @Column(name = "translation_ja", length = 500)
    private String translationJa;

    /**
     * 音声URL (S3想定)
     */
    @Column(name = "audio_url", length = 500)
    private String audioUrl;

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
     * エンティティ保存前に自動的に追加日時を設定
     */
    @PrePersist
    protected void onCreate() {
        if (addingAt == null) {
            addingAt = LocalDateTime.now();
        }
        if (isActive == null) {
            isActive = true;
        }
        if (isDeleted == null) {
            isDeleted = false;
        }
    }
}
