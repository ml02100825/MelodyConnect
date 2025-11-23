package com.example.api.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * Claude APIからの問題生成レスポンスDTO
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ClaudeQuestionResponse {

    /**
     * 虫食い問題リスト
     */
    private List<Question> fillInBlank;

    /**
     * リスニング問題リスト
     */
    private List<Question> listening;

    /**
     * 問題DTO
     */
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class Question {
        /**
         * 元の歌詞フラグメント（任意の言語）
         */
        private String sourceFragment;

        /**
         * 問題文（fill_in_blankの場合は空欄入り、listeningの場合は完全な文）
         * Questionエンティティのtextフィールドに対応
         */
        private String text;

        /**
         * 正解（空欄部分の単語）
         * Questionエンティティのanswerフィールドに対応
         */
        private String answer;

        /**
         * 完全な文（空欄がない状態の文）
         * QuestionエンティティのcompleteSentenceフィールドに対応
         */
        private String completeSentence;

        /**
         * 難易度 (1-5)
         * QuestionエンティティのdifficultyLevelフィールドに対応
         */
        private Integer difficultyLevel;

        /**
         * 日本語訳
         * QuestionエンティティのtranslationJaフィールドに対応
         */
        private String translationJa;

        /**
         * 説明（日本語）
         */
        private String explanation;

        /**
         * 音声URL（リスニング問題用）
         * QuestionエンティティのaudioUrlフィールドに対応
         */
        private String audioUrl;

        // === 後方互換性のためのDeprecatedフィールド ===

        /**
         * @deprecated textフィールドを使用してください
         */
        @Deprecated
        public String getSentence() {
            return text;
        }

        /**
         * @deprecated textフィールドを使用してください
         */
        @Deprecated
        public String getSentenceWithBlank() {
            return text;
        }

        /**
         * @deprecated completeSentenceフィールドを使用してください
         */
        @Deprecated
        public String getTargetSentenceFull() {
            return completeSentence;
        }

        /**
         * @deprecated answerフィールドを使用してください
         */
        @Deprecated
        public String getBlankWord() {
            return answer;
        }

        /**
         * @deprecated difficultyLevelフィールドを使用してください
         */
        @Deprecated
        public Integer getDifficulty() {
            return difficultyLevel;
        }

        /**
         * 学習焦点 (vocabulary, grammar, collocation, idiom等) - 旧フォーマット用
         * @deprecated 新しいフォーマットでは使用されません
         */
        @Deprecated
        private String skillFocus;
    }
}
