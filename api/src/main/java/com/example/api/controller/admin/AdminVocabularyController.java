package com.example.api.controller.admin;

import com.example.api.dto.admin.AdminVocabularyRequest;
import com.example.api.dto.admin.AdminVocabularyResponse;
import com.example.api.dto.admin.BulkActionRequest;
import com.example.api.service.admin.AdminVocabularyService;
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
 * 管理者用単語管理コントローラー
 */
@RestController
@RequestMapping("/api/admin/vocabularies")
public class AdminVocabularyController {

    private static final Logger logger = LoggerFactory.getLogger(AdminVocabularyController.class);

    @Autowired
    private AdminVocabularyService adminVocabularyService;

    @GetMapping
    public ResponseEntity<?> getVocabularies(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(required = false) String idSearch,
            @RequestParam(required = false) String word,
            @RequestParam(required = false) String partOfSpeech,
            @RequestParam(required = false) Boolean isActive,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime createdFrom,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime createdTo,
            @RequestParam(defaultValue = "desc") String sortDirection) {
        try {
            return ResponseEntity.ok(
                    adminVocabularyService.getVocabularies(
                            page, size, idSearch, word, partOfSpeech, isActive, createdFrom, createdTo, sortDirection));
        } catch (Exception e) {
            logger.error("単語一覧取得エラー", e);
            return ResponseEntity.internalServerError().body(createErrorResponse("単語一覧の取得に失敗しました"));
        }
    }

    @GetMapping("/{id}")
    public ResponseEntity<?> getVocabulary(@PathVariable Integer id) {
        try {
            return ResponseEntity.ok(adminVocabularyService.getVocabulary(id));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.notFound().build();
        } catch (Exception e) {
            logger.error("単語詳細取得エラー", e);
            return ResponseEntity.internalServerError().body(createErrorResponse("単語詳細の取得に失敗しました"));
        }
    }

    @PostMapping
    public ResponseEntity<?> createVocabulary(@Valid @RequestBody AdminVocabularyRequest request) {
        try {
            AdminVocabularyResponse response = adminVocabularyService.createVocabulary(request);
            return ResponseEntity.status(HttpStatus.CREATED).body(response);
        } catch (Exception e) {
            logger.error("単語作成エラー", e);
            return ResponseEntity.internalServerError().body(createErrorResponse("単語の作成に失敗しました"));
        }
    }

    @PutMapping("/{id}")
    public ResponseEntity<?> updateVocabulary(@PathVariable Integer id, @Valid @RequestBody AdminVocabularyRequest request) {
        try {
            return ResponseEntity.ok(adminVocabularyService.updateVocabulary(id, request));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.notFound().build();
        } catch (Exception e) {
            logger.error("単語更新エラー", e);
            return ResponseEntity.internalServerError().body(createErrorResponse("単語の更新に失敗しました"));
        }
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteVocabulary(@PathVariable Integer id) {
        try {
            adminVocabularyService.deleteVocabulary(id);
            return ResponseEntity.ok(createSuccessResponse("単語を削除しました"));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.notFound().build();
        } catch (Exception e) {
            logger.error("単語削除エラー", e);
            return ResponseEntity.internalServerError().body(createErrorResponse("単語の削除に失敗しました"));
        }
    }

    @PutMapping("/{id}/restore")
    public ResponseEntity<?> restoreVocabulary(@PathVariable Integer id) {
        try {
            adminVocabularyService.restoreVocabulary(id);
            return ResponseEntity.ok(createSuccessResponse("単語の削除を解除しました"));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.notFound().build();
        } catch (Exception e) {
            logger.error("単語削除解除エラー", e);
            return ResponseEntity.internalServerError().body(createErrorResponse("単語の削除解除に失敗しました"));
        }
    }

    @PostMapping("/enable")
    public ResponseEntity<?> enableVocabularies(@Valid @RequestBody BulkActionRequest request) {
        try {
            int count = adminVocabularyService.enableVocabularies(request.getIds());
            Map<String, Object> response = new HashMap<>();
            response.put("message", count + "件の単語を有効化しました");
            response.put("count", count);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            logger.error("単語一括有効化エラー", e);
            return ResponseEntity.internalServerError().body(createErrorResponse("単語の有効化に失敗しました"));
        }
    }

    @PostMapping("/disable")
    public ResponseEntity<?> disableVocabularies(@Valid @RequestBody BulkActionRequest request) {
        try {
            int count = adminVocabularyService.disableVocabularies(request.getIds());
            Map<String, Object> response = new HashMap<>();
            response.put("message", count + "件の単語を無効化しました");
            response.put("count", count);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            logger.error("単語一括無効化エラー", e);
            return ResponseEntity.internalServerError().body(createErrorResponse("単語の無効化に失敗しました"));
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
