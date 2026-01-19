package com.example.api.service;

import com.example.api.dto.ReportRequest;
import com.example.api.dto.ReportResponse;
import com.example.api.entity.QuestionReport;
import com.example.api.entity.VocabularyReport;
import com.example.api.repository.QuestionReportRepository;
import com.example.api.repository.VocabularyReportRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * 通報サービス
 * Vocabulary/Question の通報を管理
 */
@Service
public class ReportService {

    private static final Logger logger = LoggerFactory.getLogger(ReportService.class);

    @Autowired
    private QuestionReportRepository questionReportRepository;

    @Autowired
    private VocabularyReportRepository vocabularyReportRepository;

    /**
     * 通報を作成
     * 1ユーザー1対象につき1回まで
     */
    @Transactional
    public ReportResponse createReport(ReportRequest request) {
        logger.info("通報作成リクエスト: type={}, targetId={}, userId={}",
            request.getReportType(), request.getTargetId(), request.getUserId());

        // 入力検証
        if (request.getReportType() == null || request.getTargetId() == null || request.getUserId() == null) {
            return ReportResponse.builder()
                .success(false)
                .message("必須パラメータが不足しています")
                .build();
        }

        // reportContentがnullの場合は空文字に変換（DBはnot nullなので）
        String reportContent = request.getReportContent() != null ? request.getReportContent() : "";

        try {
            if ("VOCABULARY".equalsIgnoreCase(request.getReportType())) {
                return createVocabularyReport(request.getUserId(), request.getTargetId(), reportContent);
            } else if ("QUESTION".equalsIgnoreCase(request.getReportType())) {
                return createQuestionReport(request.getUserId(), request.getTargetId(), reportContent);
            } else {
                return ReportResponse.builder()
                    .success(false)
                    .message("不正な通報タイプです: " + request.getReportType())
                    .build();
            }
        } catch (Exception e) {
            logger.error("通報作成中にエラーが発生しました", e);
            return ReportResponse.builder()
                .success(false)
                .message("通報の作成に失敗しました: " + e.getMessage())
                .build();
        }
    }

    /**
     * Vocabulary通報を作成
     */
    private ReportResponse createVocabularyReport(Long userId, Long vocabularyId, String reportContent) {
        // 重複チェック
        if (vocabularyReportRepository.existsByUserIdAndVocabularyId(userId, vocabularyId)) {
            logger.warn("この単語は既に通報済みです: userId={}, vocabularyId={}", userId, vocabularyId);
            return ReportResponse.builder()
                .success(false)
                .message("この単語は既に通報済みです")
                .build();
        }

        // 新規通報を作成
        VocabularyReport report = new VocabularyReport();
        report.setUserId(userId);
        report.setVocabularyId(vocabularyId);
        report.setReportContent(reportContent);

        VocabularyReport savedReport = vocabularyReportRepository.save(report);

        logger.info("Vocabulary通報を作成しました: reportId={}", savedReport.getVocabularyReportId());

        return ReportResponse.builder()
            .success(true)
            .message("通報を受け付けました")
            .reportId(savedReport.getVocabularyReportId())
            .build();
    }

    /**
     * Question通報を作成
     */
    private ReportResponse createQuestionReport(Long userId, Long questionId, String reportContent) {
        // 重複チェック
        if (questionReportRepository.existsByUserIdAndQuestionId(userId, questionId)) {
            logger.warn("この問題は既に通報済みです: userId={}, questionId={}", userId, questionId);
            return ReportResponse.builder()
                .success(false)
                .message("この問題は既に通報済みです")
                .build();
        }

        // 新規通報を作成
        QuestionReport report = new QuestionReport();
        report.setUserId(userId);
        report.setQuestionId(questionId);
        report.setReportContent(reportContent);

        QuestionReport savedReport = questionReportRepository.save(report);

        logger.info("Question通報を作成しました: reportId={}", savedReport.getQuestionReportId());

        return ReportResponse.builder()
            .success(true)
            .message("通報を受け付けました")
            .reportId(savedReport.getQuestionReportId())
            .build();
    }
}
