package com.example.api.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * 通報リクエストDTO
 * VocabularyとQuestionの両方に使用
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ReportRequest {

    /**
     * 通報タイプ
     * "VOCABULARY" or "QUESTION"
     */
    private String reportType;

    /**
     * 対象ID
     * vocabularyId または questionId
     */
    private Long targetId;

    /**
     * 通報内容（コメント）
     * 空文字可（必須フィールドだが内容は任意）
     */
    private String reportContent;

    /**
     * 通報者のユーザーID
     */
    private Long userId;
}
