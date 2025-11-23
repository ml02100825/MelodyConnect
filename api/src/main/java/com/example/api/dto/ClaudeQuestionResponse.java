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
         * ターゲット言語での完全な文
         */
        private String targetSentenceFull;

        /**
         * 空欄を含む文（fill_in_blankの場合のみ）
         */
        private String sentenceWithBlank;

        /**
         * 正解（空欄部分の単語）
         */
        private String blankWord;

        /**
         * 難易度 (1-5)
         */
        private Integer difficulty;

        /**
         * 日本語訳
         */
        private String translationJa;

        /**
         * 説明（日本語）
         */
        private String explanation;

        /**
         * 音声URL（リスニング問題用）
         */
        private String audioUrl;

        // 後方互換性のため、sentenceプロパティを提供
        @Deprecated
        public String getSentence() {
            return sentenceWithBlank != null ? sentenceWithBlank : targetSentenceFull;
        }

        /**
         * 学習焦点 (vocabulary, grammar, collocation, idiom等) - 旧フォーマット用
         * @deprecated 新しいフォーマットでは使用されません
         */
        @Deprecated
        private String skillFocus;
    }
}
