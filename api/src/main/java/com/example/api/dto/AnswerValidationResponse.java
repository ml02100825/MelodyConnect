package com.example.api.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * 回答検証レスポンスDTO
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AnswerValidationResponse {

    /**
     * 正解かどうか
     */
    private boolean correct;

    /**
     * 正解の回答
     */
    private String correctAnswer;

    /**
     * ユーザーの回答
     */
    private String userAnswer;

    /**
     * 間違えた単語リスト（リスニング問題用）
     */
    private List<String> incorrectWords;

    /**
     * 正解率（0.0 - 1.0）
     */
    private double accuracy;

    /**
     * メッセージ
     */
    private String message;
}
