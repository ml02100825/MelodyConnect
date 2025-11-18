package com.example.api.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * クイズ完了レスポンスDTO
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class QuizCompleteResponse {

    /**
     * セッションID
     */
    private Long sessionId;

    /**
     * 正解数
     */
    private Integer correctCount;

    /**
     * 総問題数
     */
    private Integer totalCount;

    /**
     * 正解率
     */
    private Double accuracy;

    /**
     * 問題と回答の詳細リスト
     */
    private List<QuestionResult> questionResults;

    /**
     * 曲情報
     */
    private QuizStartResponse.SongInfo songInfo;

    /**
     * メッセージ
     */
    private String message;

    /**
     * 問題結果DTO
     */
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class QuestionResult {
        private Integer questionId;
        private String questionText;
        private String questionFormat;
        private String correctAnswer;
        private String userAnswer;
        private Boolean isCorrect;
        private Integer difficultyLevel;
    }
}
