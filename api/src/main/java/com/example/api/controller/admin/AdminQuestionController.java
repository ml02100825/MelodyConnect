package com.example.api.controller.admin;

import com.example.api.dto.admin.AdminQuestionRequest;
import com.example.api.dto.admin.AdminQuestionResponse;
import com.example.api.dto.admin.BulkActionRequest;
import com.example.api.service.admin.AdminQuestionService;
import jakarta.validation.Valid;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

/**
 * 管理者用問題管理コントローラー
 */
@RestController
@RequestMapping("/api/admin/questions")
public class AdminQuestionController {

    private static final Logger logger = LoggerFactory.getLogger(AdminQuestionController.class);

    @Autowired
    private AdminQuestionService adminQuestionService;

    @GetMapping
    public ResponseEntity<?> getQuestions(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(required = false) String idSearch,
            @RequestParam(required = false) Long artistId,
            @RequestParam(required = false) String questionFormat,
            @RequestParam(required = false) String language,
            @RequestParam(required = false) Integer difficultyLevel,
            @RequestParam(required = false) Boolean isActive,
            @RequestParam(required = false) String questionText,
            @RequestParam(required = false) String answer,
            @RequestParam(required = false) String songName,
            @RequestParam(required = false) String artistName,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime addedFrom,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime addedTo,
            @RequestParam(defaultValue = "desc") String sortDirection) {
        try {
            return ResponseEntity.ok(adminQuestionService.getQuestions(
                    page, size, idSearch, artistId, questionFormat, language, difficultyLevel, isActive,
                    questionText, answer, songName, artistName, addedFrom, addedTo, sortDirection));
        } catch (Exception e) {
            logger.error("問題一覧取得エラー", e);
            return ResponseEntity.internalServerError().body(createErrorResponse("問題一覧の取得に失敗しました"));
        }
    }

    @GetMapping("/{id}")
    public ResponseEntity<?> getQuestion(@PathVariable Integer id) {
        try {
            return ResponseEntity.ok(adminQuestionService.getQuestion(id));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.notFound().build();
        } catch (Exception e) {
            logger.error("問題詳細取得エラー", e);
            return ResponseEntity.internalServerError().body(createErrorResponse("問題詳細の取得に失敗しました"));
        }
    }

    @PostMapping
    public ResponseEntity<?> createQuestion(@Valid @RequestBody AdminQuestionRequest request) {
        try {
            AdminQuestionResponse response = adminQuestionService.createQuestion(request);
            return ResponseEntity.status(HttpStatus.CREATED).body(response);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(createErrorResponse(e.getMessage()));
        } catch (Exception e) {
            logger.error("問題作成エラー", e);
            return ResponseEntity.internalServerError().body(createErrorResponse("問題の作成に失敗しました"));
        }
    }

    @PutMapping("/{id}")
    public ResponseEntity<?> updateQuestion(@PathVariable Integer id, @Valid @RequestBody AdminQuestionRequest request) {
        try {
            return ResponseEntity.ok(adminQuestionService.updateQuestion(id, request));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(createErrorResponse(e.getMessage()));
        } catch (Exception e) {
            logger.error("問題更新エラー", e);
            return ResponseEntity.internalServerError().body(createErrorResponse("問題の更新に失敗しました"));
        }
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteQuestion(@PathVariable Integer id) {
        try {
            adminQuestionService.deleteQuestion(id);
            return ResponseEntity.ok(createSuccessResponse("問題を削除しました"));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.notFound().build();
        } catch (Exception e) {
            logger.error("問題削除エラー", e);
            return ResponseEntity.internalServerError().body(createErrorResponse("問題の削除に失敗しました"));
        }
    }

    @PostMapping("/enable")
    public ResponseEntity<?> enableQuestions(@Valid @RequestBody BulkActionRequest request) {
        try {
            int count = adminQuestionService.enableQuestions(request.getIds());
            Map<String, Object> response = new HashMap<>();
            response.put("message", count + "件の問題を有効化しました");
            response.put("count", count);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            logger.error("問題一括有効化エラー", e);
            return ResponseEntity.internalServerError().body(createErrorResponse("問題の有効化に失敗しました"));
        }
    }

    @PostMapping("/disable")
    public ResponseEntity<?> disableQuestions(@Valid @RequestBody BulkActionRequest request) {
        try {
            int count = adminQuestionService.disableQuestions(request.getIds());
            Map<String, Object> response = new HashMap<>();
            response.put("message", count + "件の問題を無効化しました");
            response.put("count", count);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            logger.error("問題一括無効化エラー", e);
            return ResponseEntity.internalServerError().body(createErrorResponse("問題の無効化に失敗しました"));
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
