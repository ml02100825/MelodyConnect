package com.example.api.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * 通報レスポンスDTO
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ReportResponse {

    /**
     * 成功フラグ
     */
    private Boolean success;

    /**
     * メッセージ
     */
    private String message;

    /**
     * 作成された通報ID（成功時のみ）
     */
    private Long reportId;
}
