package com.example.api.entity;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(
    name = "question_report",
    indexes = {
        @Index(name = "idx_question_report_question_id", columnList = "question_id"),
        @Index(name = "idx_question_report_user_id", columnList = "user_id"),
        @Index(name = "idx_question_report_status", columnList = "status")
    },
    uniqueConstraints = {
        @UniqueConstraint(name = "uk_question_report_user_question", columnNames = {"user_id", "question_id"})
    }
)
public class QuestionReport {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "question_report_id", nullable = false)
    private Long questionReportId;

    @Column(name = "question_id", nullable = false)
    private Long questionId;

    @Lob
    @Column(name = "report_content", nullable = false, columnDefinition = "TEXT")
    private String reportContent;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "added_at", nullable = false)
    private Instant addedAt;

    @Column(name = "status", length = 20)
    private String status = "未対応";

    @Lob
    @Column(name = "admin_memo", columnDefinition = "TEXT")
    private String adminMemo;

    @PrePersist
    public void prePersist() {
        if (this.addedAt == null) {
            this.addedAt = Instant.now();
        }
        if (this.status == null) {
            this.status = "未対応";
        }
    }

    public Long getQuestionReportId() {
        return questionReportId;
    }

    public void setQuestionReportId(Long questionReportId) {
        this.questionReportId = questionReportId;
    }

    public Long getQuestionId() {
        return questionId;
    }

    public void setQuestionId(Long questionId) {
        this.questionId = questionId;
    }

    public String getReportContent() {
        return reportContent;
    }

    public void setReportContent(String reportContent) {
        this.reportContent = reportContent;
    }

    public Long getUserId() {
        return userId;
    }

    public void setUserId(Long userId) {
        this.userId = userId;
    }

    public Instant getAddedAt() {
        return addedAt;
    }

    public void setAddedAt(Instant addedAt) {
        this.addedAt = addedAt;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public String getAdminMemo() {
        return adminMemo;
    }

    public void setAdminMemo(String adminMemo) {
        this.adminMemo = adminMemo;
    }
}
