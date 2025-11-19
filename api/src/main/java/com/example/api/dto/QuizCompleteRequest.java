package com.example.api.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * クイズ完了リクエストDTO
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class QuizCompleteRequest {

    /**
     * セッションID
     */
    private Long sessionId;

    /**
     * ユーザーID
     */
    private Long userId;

    /**
     * 回答結果リスト
     */
    private List<AnswerResult> answers;

    /**
     * 回答結果DTO
     */
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class AnswerResult {
        private Integer questionId;
        private String userAnswer;
        private Boolean isCorrect;
    }
}
