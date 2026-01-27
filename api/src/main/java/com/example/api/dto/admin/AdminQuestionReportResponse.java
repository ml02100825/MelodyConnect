package com.example.api.dto.admin;

import java.time.Instant;
import java.util.List;

public class AdminQuestionReportResponse {

    private Long questionReportId;
    private Long questionId;
    private String questionText;
    private String answer;
    private String songName;
    private String artistName;
    private Long userId;
    private String userEmail;
    private String reportContent;
    private String status;
    private String adminMemo;
    private Instant addedAt;

    public Long getQuestionReportId() { return questionReportId; }
    public void setQuestionReportId(Long questionReportId) { this.questionReportId = questionReportId; }
    public Long getQuestionId() { return questionId; }
    public void setQuestionId(Long questionId) { this.questionId = questionId; }
    public String getQuestionText() { return questionText; }
    public void setQuestionText(String questionText) { this.questionText = questionText; }
    public String getAnswer() { return answer; }
    public void setAnswer(String answer) { this.answer = answer; }
    public String getSongName() { return songName; }
    public void setSongName(String songName) { this.songName = songName; }
    public String getArtistName() { return artistName; }
    public void setArtistName(String artistName) { this.artistName = artistName; }
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
    public Instant getAddedAt() { return addedAt; }
    public void setAddedAt(Instant addedAt) { this.addedAt = addedAt; }

    public static class ListResponse {
        private List<AdminQuestionReportResponse> questionReports;
        private int page;
        private int size;
        private long totalElements;
        private int totalPages;

        public ListResponse(List<AdminQuestionReportResponse> questionReports, int page, int size, long totalElements, int totalPages) {
            this.questionReports = questionReports;
            this.page = page;
            this.size = size;
            this.totalElements = totalElements;
            this.totalPages = totalPages;
        }

        public List<AdminQuestionReportResponse> getQuestionReports() { return questionReports; }
        public int getPage() { return page; }
        public int getSize() { return size; }
        public long getTotalElements() { return totalElements; }
        public int getTotalPages() { return totalPages; }
    }
}
