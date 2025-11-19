package com.example.api.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * クイズ回答提出リクエストDTO
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class QuizSubmitRequest {

    /**
     * セッションID
     */
    private Long sessionId;

    /**
     * 問題ID
     */
    private Integer questionId;

    /**
     * ユーザーの回答
     */
    private String userAnswer;

    /**
     * ユーザーID
     */
    private Long userId;
}
