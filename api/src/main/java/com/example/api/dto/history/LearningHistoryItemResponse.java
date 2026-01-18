package com.example.api.dto.history;

import lombok.Builder;
import lombok.Data;

/**
 * 学習履歴一覧アイテム
 */
@Data
@Builder
public class LearningHistoryItemResponse {
    private Long historyId;
    private String learningAt;
    private int correctCount;
    private int totalCount;
    private String learningLang;
}
