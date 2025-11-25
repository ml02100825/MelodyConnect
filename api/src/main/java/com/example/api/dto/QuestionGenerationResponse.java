package com.example.api.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * 問題生成レスポンスDTO
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class QuestionGenerationResponse {

    /**
     * 生成された問題リスト
     */
    private List<GeneratedQuestionDto> questions;

    /**
     * 楽曲情報
     */
    private SongInfo songInfo;

    /**
     * 生成された問題数
     */
    private Integer totalCount;

    /**
     * 虫食い問題数
     */
    private Integer fillInBlankCount;

    /**
     * リスニング問題数
     */
    private Integer listeningCount;

    /**
     * メッセージ
     */
    private String message;

    /**
     * 生成された問題DTO
     */
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class GeneratedQuestionDto {
        private Integer questionId;
        private String text;
        private String answer;
        private String completeSentence;
        private String questionFormat;
        private Integer difficultyLevel;
        private String language;
        private String translationJa;
        private String audioUrl;
    }

    /**
     * 楽曲情報DTO
     */
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class SongInfo {
        private Long songId;
        private String songName;
        private String artistName;
        private String genre;
        private String language;
    }
}
