package com.example.api.controller.admin;

import com.example.api.dto.admin.AdminVocabularyReportResponse;
import com.example.api.dto.admin.VocabularyReportStatusUpdateRequest;
import com.example.api.service.admin.AdminVocabularyReportService;
import jakarta.validation.Valid;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/admin/vocabulary-reports")
public class AdminVocabularyReportController {

    private static final Logger logger = LoggerFactory.getLogger(AdminVocabularyReportController.class);

    @Autowired
    private AdminVocabularyReportService adminVocabularyReportService;

    @GetMapping
    public ResponseEntity<?> getVocabularyReports(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(required = false) String status) {
        try {
            return ResponseEntity.ok(adminVocabularyReportService.getVocabularyReports(page, size, status));
        } catch (Exception e) {
            logger.error("単語報告一覧取得エラー", e);
            return ResponseEntity.internalServerError().body(createErrorResponse("単語報告一覧の取得に失敗しました"));
        }
    }

    @GetMapping("/{id}")
    public ResponseEntity<?> getVocabularyReport(@PathVariable Long id) {
        try {
            return ResponseEntity.ok(adminVocabularyReportService.getVocabularyReport(id));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.notFound().build();
        } catch (Exception e) {
            logger.error("単語報告詳細取得エラー", e);
            return ResponseEntity.internalServerError().body(createErrorResponse("単語報告詳細の取得に失敗しました"));
        }
    }

    @PutMapping("/{id}/status")
    public ResponseEntity<?> updateVocabularyReportStatus(@PathVariable Long id, @Valid @RequestBody VocabularyReportStatusUpdateRequest request) {
        try {
            AdminVocabularyReportResponse response = adminVocabularyReportService.updateVocabularyReportStatus(id, request);
            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.notFound().build();
        } catch (Exception e) {
            logger.error("単語報告ステータス更新エラー", e);
            return ResponseEntity.internalServerError().body(createErrorResponse("単語報告ステータスの更新に失敗しました"));
        }
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteVocabularyReport(@PathVariable Long id) {
        try {
            adminVocabularyReportService.deleteVocabularyReport(id);
            return ResponseEntity.ok(createSuccessResponse("単語報告を削除しました"));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.notFound().build();
        } catch (Exception e) {
            logger.error("単語報告削除エラー", e);
            return ResponseEntity.internalServerError().body(createErrorResponse("単語報告の削除に失敗しました"));
        }
    }

    private Map<String, String> createErrorResponse(String message) {
        Map<String, String> error = new HashMap<>();
        error.put("error", message);
        return error;
    }

    private Map<String, String> createSuccessResponse(String message) {
        Map<String, String> success = new HashMap<>();
        success.put("message", message);
        return success;
    }
}
