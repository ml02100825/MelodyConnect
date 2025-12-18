package com.example.api.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.List;

/**
 * ユーザー単語帳レスポンスDTO
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserVocabularyResponse {

    /**
     * 成功フラグ
     */
    private boolean success;

    /**
     * メッセージ
     */
    private String message;

    /**
     * 単語の総数
     */
    private Integer totalCount;

    /**
     * 単語リスト
     */
    private List<VocabularyItem> vocabularies;

    /**
     * 単語アイテムDTO
     */
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class VocabularyItem {
        /**
         * UserVocabularyのID
         */
        private Integer userVocabId;

        /**
         * VocabularyのID
         */
        private Integer vocabId;

        /**
         * 単語（外国語）
         */
        private String word;

        /**
         * 原形（lemma）
         */
        private String baseForm;

        /**
         * 簡潔な日本語訳（一言訳）
         * 例: "重要な"
         */
        private String translationJa;

        /**
         * 詳細な日本語の意味
         */
        private String meaningJa;

        /**
         * 発音記号
         */
        private String pronunciation;

        /**
         * 品詞
         */
        private String partOfSpeech;

        /**
         * 例文
         */
        private String exampleSentence;

        /**
         * 例文の日本語訳
         */
        private String exampleTranslation;

        /**
         * 音声URL
         */
        private String audioUrl;

        /**
         * 言語 (en, ko, etc.)
         */
        private String language;

        /**
         * お気に入りフラグ
         */
        private Boolean isFavorite;

        /**
         * 学習済みフラグ
         */
        private Boolean isLearned;

        /**
         * 初回学習日時
         */
        private LocalDateTime firstLearnedAt;
    }
}