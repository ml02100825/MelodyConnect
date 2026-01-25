package com.example.api.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(
    name = "vocabulary_report",
    indexes = {
        @Index(name = "idx_vocabulary_report_vocabulary_id", columnList = "vocabulary_id"),
        @Index(name = "idx_vocabulary_report_user_id", columnList = "user_id"),
        @Index(name = "idx_vocabulary_report_status", columnList = "status")
    },
    uniqueConstraints = {
        @UniqueConstraint(name = "uk_vocabulary_report_user_vocabulary", columnNames = {"user_id", "vocabulary_id"})
    }
)
public class VocabularyReport {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "vocabulary_report_id", nullable = false)
    private Long vocabularyReportId;

    @Column(name = "vocabulary_id", nullable = false)
    private Long vocabularyId;

    @Lob
    @Column(name = "report_content", nullable = false, columnDefinition = "TEXT")
    private String reportContent;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "added_at", nullable = false)
    private LocalDateTime addedAt;

    @Column(name = "status", length = 20)
    private String status = "未対応";

    @Lob
    @Column(name = "admin_memo", columnDefinition = "TEXT")
    private String adminMemo;

    @PrePersist
    public void prePersist() {
        if (this.addedAt == null) {
            this.addedAt = LocalDateTime.now();
        }
        if (this.status == null) {
            this.status = "未対応";
        }
    }

    public Long getVocabularyReportId() {
        return vocabularyReportId;
    }

    public void setVocabularyReportId(Long vocabularyReportId) {
        this.vocabularyReportId = vocabularyReportId;
    }

    public Long getVocabularyId() {
        return vocabularyId;
    }

    public void setVocabularyId(Long vocabularyId) {
        this.vocabularyId = vocabularyId;
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

    public LocalDateTime getAddedAt() {
        return addedAt;
    }

    public void setAddedAt(LocalDateTime addedAt) {
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
