package com.example.api.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(
    name = "vocabulary_report",
    indexes = {
        @Index(name = "idx_vocabulary_report_vocabulary_id", columnList = "vocabulary_id"),
        @Index(name = "idx_vocabulary_report_user_id", columnList = "user_id")
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

    @PrePersist
    public void prePersist() {
        if (this.addedAt == null) {
            this.addedAt = LocalDateTime.now();
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
}
