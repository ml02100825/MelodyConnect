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
         * 問題文（空欄含む）
         */
        private String sentence;

        /**
         * 正解（空欄部分の単語）
         */
        private String blankWord;

        /**
         * 難易度 (1-5)
         */
        private Integer difficulty;

        /**
         * 説明
         */
        private String explanation;

        /**
         * 学習焦点 (vocabulary, grammar, collocation, idiom等)
         */
        private String skillFocus;

        /**
         * 和訳
         */
        private String translationJa;

        /**
         * 音声URL（リスニング問題用）
         * TODO: TTS実装後に追加
         */
        private String audioUrl;
    }
}
