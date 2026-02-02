package com.example.api.dto.admin;

import java.time.LocalDateTime;
import java.util.List;

public class AdminVocabularyReportResponse {

    private Long vocabularyReportId;
    private Long vocabularyId;
    private String word;
    private String meaningJa;
    private Long userId;
    private String userEmail;
    private String reportContent;
    private String status;
    private String adminMemo;
    private LocalDateTime addedAt;

    public Long getVocabularyReportId() { return vocabularyReportId; }
    public void setVocabularyReportId(Long vocabularyReportId) { this.vocabularyReportId = vocabularyReportId; }
    public Long getVocabularyId() { return vocabularyId; }
    public void setVocabularyId(Long vocabularyId) { this.vocabularyId = vocabularyId; }
    public String getWord() { return word; }
    public void setWord(String word) { this.word = word; }
    public String getMeaningJa() { return meaningJa; }
    public void setMeaningJa(String meaningJa) { this.meaningJa = meaningJa; }
    public Long getUserId() { return userId; }
    public void setUserId(Long userId) { this.userId = userId; }
    public String getUserEmail() { return userEmail; }
    public void setUserEmail(String userEmail) { this.userEmail = userEmail; }
    public String getReportContent() { return reportContent; }
    public void setReportContent(String reportContent) { this.reportContent = reportContent; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public String getAdminMemo() { return adminMemo; }
    public void setAdminMemo(String adminMemo) { this.adminMemo = adminMemo; }
    public LocalDateTime getAddedAt() { return addedAt; }
    public void setAddedAt(LocalDateTime addedAt) { this.addedAt = addedAt; }

    public static class ListResponse {
        private List<AdminVocabularyReportResponse> vocabularyReports;
        private int page;
        private int size;
        private long totalElements;
        private int totalPages;

        public ListResponse(List<AdminVocabularyReportResponse> vocabularyReports, int page, int size, long totalElements, int totalPages) {
            this.vocabularyReports = vocabularyReports;
            this.page = page;
            this.size = size;
            this.totalElements = totalElements;
            this.totalPages = totalPages;
        }

        public List<AdminVocabularyReportResponse> getVocabularyReports() { return vocabularyReports; }
        public int getPage() { return page; }
        public int getSize() { return size; }
        public long getTotalElements() { return totalElements; }
        public int getTotalPages() { return totalPages; }
    }
}
