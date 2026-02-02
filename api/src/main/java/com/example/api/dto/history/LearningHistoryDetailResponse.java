package com.example.api.dto.history;

import lombok.Builder;
import lombok.Data;

import java.util.List;

/**
 * 学習履歴詳細
 */
@Data
@Builder
public class LearningHistoryDetailResponse {
    private Long historyId;
    private String learningAt;
    private int correctCount;
    private int totalCount;
    private String learningLang;
    private List<QuestionDetail> questions;

    @Data
    @Builder
    public static class QuestionDetail {
        private Integer questionId;
        private String questionText;
        private String correctAnswer;
        private String userAnswer;
        private boolean isCorrect;
        private String questionFormat;
    }
}
