package com.example.api.controller.admin;

import com.example.api.dto.admin.AdminQuestionReportResponse;
import com.example.api.dto.admin.QuestionReportStatusUpdateRequest;
import com.example.api.service.admin.AdminQuestionReportService;
import jakarta.validation.Valid;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/admin/question-reports")
public class AdminQuestionReportController {

    private static final Logger logger = LoggerFactory.getLogger(AdminQuestionReportController.class);

    @Autowired
    private AdminQuestionReportService adminQuestionReportService;

    @GetMapping
    public ResponseEntity<?> getQuestionReports(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(required = false) String status) {
        try {
            return ResponseEntity.ok(adminQuestionReportService.getQuestionReports(page, size, status));
        } catch (Exception e) {
            logger.error("問題報告一覧取得エラー", e);
            return ResponseEntity.internalServerError().body(createErrorResponse("問題報告一覧の取得に失敗しました"));
        }
    }

    @GetMapping("/{id}")
    public ResponseEntity<?> getQuestionReport(@PathVariable Long id) {
        try {
            return ResponseEntity.ok(adminQuestionReportService.getQuestionReport(id));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.notFound().build();
        } catch (Exception e) {
            logger.error("問題報告詳細取得エラー", e);
            return ResponseEntity.internalServerError().body(createErrorResponse("問題報告詳細の取得に失敗しました"));
        }
    }

    @PutMapping("/{id}/status")
    public ResponseEntity<?> updateQuestionReportStatus(@PathVariable Long id, @Valid @RequestBody QuestionReportStatusUpdateRequest request) {
        try {
            AdminQuestionReportResponse response = adminQuestionReportService.updateQuestionReportStatus(id, request);
            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.notFound().build();
        } catch (Exception e) {
            logger.error("問題報告ステータス更新エラー", e);
            return ResponseEntity.internalServerError().body(createErrorResponse("問題報告ステータスの更新に失敗しました"));
        }
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteQuestionReport(@PathVariable Long id) {
        try {
            adminQuestionReportService.deleteQuestionReport(id);
            return ResponseEntity.ok(createSuccessResponse("問題報告を削除しました"));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.notFound().build();
        } catch (Exception e) {
            logger.error("問題報告削除エラー", e);
            return ResponseEntity.internalServerError().body(createErrorResponse("問題報告の削除に失敗しました"));
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
