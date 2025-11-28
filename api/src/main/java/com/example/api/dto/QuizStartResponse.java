package com.example.api.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * クイズ開始レスポンスDTO
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class QuizStartResponse {

    /**
     * クイズセッションID（l_history_id）
     */
    private Long sessionId;

    /**
     * 問題リスト
     */
    private List<QuizQuestion> questions;

    /**
     * 曲情報
     */
    private SongInfo songInfo;

    /**
     * 問題数
     */
    private Integer totalCount;

    /**
     * メッセージ
     */
    private String message;
       
     /**
     * 正解答案
     */
    private String answer;

    /**
     * 問題DTO
     */
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class QuizQuestion {
        private Integer questionId;
        private String text;
        private String questionFormat; // "fill_in_blank" or "listening"
        private Integer difficultyLevel;
        private String audioUrl; // リスニング問題用
        private String language;
        private String answer;
    }

    /**
     * 曲情報DTO
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
    }
}
