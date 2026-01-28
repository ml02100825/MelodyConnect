package com.example.api.service.admin;

import com.example.api.dto.admin.AdminVocabularyReportResponse;
import com.example.api.dto.admin.VocabularyReportStatusUpdateRequest;
import com.example.api.entity.VocabularyReport;
import com.example.api.entity.Vocabulary;
import com.example.api.entity.User;
import com.example.api.repository.VocabularyReportRepository;
import com.example.api.repository.VocabularyRepository;
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
public class AdminVocabularyReportService {

    private static final Logger logger = LoggerFactory.getLogger(AdminVocabularyReportService.class);

    @Autowired
    private VocabularyReportRepository vocabularyReportRepository;

    @Autowired
    private VocabularyRepository vocabularyRepository;

    @Autowired
    private UserRepository userRepository;

    public AdminVocabularyReportResponse.ListResponse getVocabularyReports(int page, int size, String status) {
        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "vocabularyReportId"));

        Specification<VocabularyReport> spec = (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();

            if (status != null && !status.isEmpty()) {
                predicates.add(cb.equal(root.get("status"), status));
            }

            return cb.and(predicates.toArray(new Predicate[0]));
        };

        Page<VocabularyReport> reportPage = vocabularyReportRepository.findAll(spec, pageable);

        List<AdminVocabularyReportResponse> reports = reportPage.getContent().stream()
                .map(this::toResponse)
                .collect(Collectors.toList());

        return new AdminVocabularyReportResponse.ListResponse(reports, page, size, reportPage.getTotalElements(), reportPage.getTotalPages());
    }

    public AdminVocabularyReportResponse getVocabularyReport(Long reportId) {
        VocabularyReport report = vocabularyReportRepository.findById(reportId)
                .orElseThrow(() -> new IllegalArgumentException("単語報告が見つかりません: " + reportId));
        return toResponse(report);
    }

    @Transactional
    public AdminVocabularyReportResponse updateVocabularyReportStatus(Long reportId, VocabularyReportStatusUpdateRequest request) {
        VocabularyReport report = vocabularyReportRepository.findById(reportId)
                .orElseThrow(() -> new IllegalArgumentException("単語報告が見つかりません: " + reportId));

        report.setStatus(request.getStatus());
        if (request.getAdminMemo() != null) {
            report.setAdminMemo(request.getAdminMemo());
        }

        report = vocabularyReportRepository.save(report);
        logger.info("単語報告ステータス更新: {} -> {}", reportId, request.getStatus());
        return toResponse(report);
    }

    @Transactional
    public void deleteVocabularyReport(Long reportId) {
        VocabularyReport report = vocabularyReportRepository.findById(reportId)
                .orElseThrow(() -> new IllegalArgumentException("単語報告が見つかりません: " + reportId));
        vocabularyReportRepository.delete(report);
        logger.info("単語報告削除: {}", reportId);
    }

    private AdminVocabularyReportResponse toResponse(VocabularyReport report) {
        AdminVocabularyReportResponse response = new AdminVocabularyReportResponse();
        response.setVocabularyReportId(report.getVocabularyReportId());
        response.setVocabularyId(report.getVocabularyId());
        response.setReportContent(report.getReportContent());
        response.setUserId(report.getUserId());
        response.setStatus(report.getStatus());
        response.setAdminMemo(report.getAdminMemo());
        response.setAddedAt(report.getAddedAt());

        // 単語情報を取得
        Optional<Vocabulary> vocabularyOpt = vocabularyRepository.findById(report.getVocabularyId().intValue());
        if (vocabularyOpt.isPresent()) {
            Vocabulary vocabulary = vocabularyOpt.get();
            response.setWord(vocabulary.getWord());
            response.setMeaningJa(vocabulary.getMeaning_ja());
        } else {
            response.setWord("削除済み");
            response.setMeaningJa("");
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
