package com.example.api.dto.admin;

import jakarta.validation.constraints.NotBlank;

public class VocabularyReportStatusUpdateRequest {

    @NotBlank(message = "ステータスは必須です")
    private String status;

    private String adminMemo;

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public String getAdminMemo() { return adminMemo; }
    public void setAdminMemo(String adminMemo) { this.adminMemo = adminMemo; }
}
