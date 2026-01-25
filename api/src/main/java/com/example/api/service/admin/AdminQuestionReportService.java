package com.example.api.service.admin;

import com.example.api.dto.admin.AdminQuestionReportResponse;
import com.example.api.dto.admin.QuestionReportStatusUpdateRequest;
import com.example.api.entity.QuestionReport;
import com.example.api.entity.Question;
import com.example.api.entity.User;
import com.example.api.repository.QuestionReportRepository;
import com.example.api.repository.QuestionRepository;
import com.example.api.repository.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import jakarta.persistence.criteria.Predicate;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
public class AdminQuestionReportService {

    private static final Logger logger = LoggerFactory.getLogger(AdminQuestionReportService.class);

    @Autowired
    private QuestionReportRepository questionReportRepository;

    @Autowired
    private QuestionRepository questionRepository;

    @Autowired
    private UserRepository userRepository;

    public AdminQuestionReportResponse.ListResponse getQuestionReports(int page, int size, String status) {
        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "questionReportId"));

        Specification<QuestionReport> spec = (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();

            if (status != null && !status.isEmpty()) {
                predicates.add(cb.equal(root.get("status"), status));
            }

            return cb.and(predicates.toArray(new Predicate[0]));
        };

        Page<QuestionReport> reportPage = questionReportRepository.findAll(spec, pageable);

        List<AdminQuestionReportResponse> reports = reportPage.getContent().stream()
                .map(this::toResponse)
                .collect(Collectors.toList());

        return new AdminQuestionReportResponse.ListResponse(reports, page, size, reportPage.getTotalElements(), reportPage.getTotalPages());
    }

    public AdminQuestionReportResponse getQuestionReport(Long reportId) {
        QuestionReport report = questionReportRepository.findById(reportId)
                .orElseThrow(() -> new IllegalArgumentException("問題報告が見つかりません: " + reportId));
        return toResponse(report);
    }

    @Transactional
    public AdminQuestionReportResponse updateQuestionReportStatus(Long reportId, QuestionReportStatusUpdateRequest request) {
        QuestionReport report = questionReportRepository.findById(reportId)
                .orElseThrow(() -> new IllegalArgumentException("問題報告が見つかりません: " + reportId));

        report.setStatus(request.getStatus());
        if (request.getAdminMemo() != null) {
            report.setAdminMemo(request.getAdminMemo());
        }

        report = questionReportRepository.save(report);
        logger.info("問題報告ステータス更新: {} -> {}", reportId, request.getStatus());
        return toResponse(report);
    }

    @Transactional
    public void deleteQuestionReport(Long reportId) {
        QuestionReport report = questionReportRepository.findById(reportId)
                .orElseThrow(() -> new IllegalArgumentException("問題報告が見つかりません: " + reportId));
        questionReportRepository.delete(report);
        logger.info("問題報告削除: {}", reportId);
    }

    private AdminQuestionReportResponse toResponse(QuestionReport report) {
        AdminQuestionReportResponse response = new AdminQuestionReportResponse();
        response.setQuestionReportId(report.getQuestionReportId());
        response.setQuestionId(report.getQuestionId());
        response.setReportContent(report.getReportContent());
        response.setUserId(report.getUserId());
        response.setStatus(report.getStatus());
        response.setAdminMemo(report.getAdminMemo());
        response.setAddedAt(report.getAddedAt());

        // 問題情報を取得
        Optional<Question> questionOpt = questionRepository.findById(report.getQuestionId().intValue());
        if (questionOpt.isPresent()) {
            Question question = questionOpt.get();
            response.setQuestionText(question.getText());
            response.setAnswer(question.getAnswer());
            if (question.getSong() != null) {
                response.setSongName(question.getSong().getSongname());
            }
            if (question.getArtist() != null) {
                response.setArtistName(question.getArtist().getArtistName());
            }
        } else {
            response.setQuestionText("削除済み");
            response.setAnswer("");
            response.setSongName("");
            response.setArtistName("");
        }

        // ユーザー情報を取得
        Optional<User> userOpt = userRepository.findById(report.getUserId());
        if (userOpt.isPresent()) {
            response.setUserEmail(userOpt.get().getMailaddress());
        } else {
            response.setUserEmail("不明");
        }

        return response;
    }
}
