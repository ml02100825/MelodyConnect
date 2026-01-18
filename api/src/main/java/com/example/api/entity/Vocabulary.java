package com.example.api.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;
import lombok.*;
import org.hibernate.annotations.Where;

@Entity
@Table(name = "vocabulary")
@Where(clause = "is_active = true AND is_deleted = false")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Vocabulary {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "vocab_id", nullable = false)
    private Integer vocab_id;

    /**
     * 単語（そのままの形: memories, running等）
     */
    @Column(name = "word", nullable = false, length = 50)
    private String word;

    /**
     * 原形（memory, run等）
     * Gemini APIで変換
     */
    @Column(name = "base_form", length = 50)
    private String base_form;

    /**
     * 詳細な日本語の意味（辞書的な説明）
     * 例: "事の成り行きや物事の本質に大きな影響を与えること。重要なこと。"
     */
    @Column(name = "meaning_ja", nullable = false, columnDefinition = "TEXT")
    private String meaning_ja;

    /**
     * 簡潔な日本語訳（一言訳）
     * 例: "重要な"
     * Gemini APIで生成
     */
    @Column(name = "translation_ja", length = 100)
    private String translation_ja;

    @Column(name = "pronunciation", length = 100)
    private String pronunciation;

    @Column(name = "part_of_speech", length = 50)
    private String part_of_speech;

    @Column(name = "example_sentence", columnDefinition = "TEXT")
    private String example_sentence;

    @Column(name = "example_translate", columnDefinition = "TEXT")
    private String example_translate;

    @Column(name = "audio_url", length = 500)
    private String audio_url;

    @Column(name = "language", length = 10)
    private String language;

    @Column(name = "created_at")
    private LocalDateTime created_at;

    @Column(name = "updated_at")
    private LocalDateTime updated_at;

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

    /* ===== lifecycle ===== */

    @PrePersist
    protected void onCreate() {
        if (created_at == null) {
            created_at = LocalDateTime.now();
        if (isActive == null) {
        isActive = true;
             }
        if (isDeleted == null) {
        isDeleted = false;
              }
        }
    }

    @PreUpdate
    protected void onUpdate() {
        updated_at = LocalDateTime.now();
    }
}
