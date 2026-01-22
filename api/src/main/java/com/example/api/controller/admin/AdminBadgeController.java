package com.example.api.controller.admin;

import com.example.api.dto.admin.AdminBadgeRequest;
import com.example.api.dto.admin.AdminBadgeResponse;
import com.example.api.dto.admin.BulkLongActionRequest;
import com.example.api.service.admin.AdminBadgeService;
import jakarta.validation.Valid;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/admin/badges")
public class AdminBadgeController {

    private static final Logger logger = LoggerFactory.getLogger(AdminBadgeController.class);

    @Autowired
    private AdminBadgeService adminBadgeService;

    @GetMapping
    public ResponseEntity<?> getBadges(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(required = false) String badgeName,
            @RequestParam(required = false) Boolean isActive) {
        try {
            return ResponseEntity.ok(adminBadgeService.getBadges(page, size, badgeName, isActive));
        } catch (Exception e) {
            logger.error("バッジ一覧取得エラー", e);
            return ResponseEntity.internalServerError().body(createErrorResponse("バッジ一覧の取得に失敗しました"));
        }
    }

    @GetMapping("/{id}")
    public ResponseEntity<?> getBadge(@PathVariable Long id) {
        try {
            return ResponseEntity.ok(adminBadgeService.getBadge(id));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.notFound().build();
        } catch (Exception e) {
            logger.error("バッジ詳細取得エラー", e);
            return ResponseEntity.internalServerError().body(createErrorResponse("バッジ詳細の取得に失敗しました"));
        }
    }

    @PostMapping
    public ResponseEntity<?> createBadge(@Valid @RequestBody AdminBadgeRequest request) {
        try {
            AdminBadgeResponse response = adminBadgeService.createBadge(request);
            return ResponseEntity.status(HttpStatus.CREATED).body(response);
        } catch (Exception e) {
            logger.error("バッジ作成エラー", e);
            return ResponseEntity.internalServerError().body(createErrorResponse("バッジの作成に失敗しました"));
        }
    }

    @PutMapping("/{id}")
    public ResponseEntity<?> updateBadge(@PathVariable Long id, @Valid @RequestBody AdminBadgeRequest request) {
        try {
            return ResponseEntity.ok(adminBadgeService.updateBadge(id, request));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.notFound().build();
        } catch (Exception e) {
            logger.error("バッジ更新エラー", e);
            return ResponseEntity.internalServerError().body(createErrorResponse("バッジの更新に失敗しました"));
        }
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteBadge(@PathVariable Long id) {
        try {
            adminBadgeService.deleteBadge(id);
            return ResponseEntity.ok(createSuccessResponse("バッジを削除しました"));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.notFound().build();
        } catch (Exception e) {
            logger.error("バッジ削除エラー", e);
            return ResponseEntity.internalServerError().body(createErrorResponse("バッジの削除に失敗しました"));
        }
    }

    @PostMapping("/enable")
    public ResponseEntity<?> enableBadges(@Valid @RequestBody BulkLongActionRequest request) {
        try {
            int count = adminBadgeService.enableBadges(request.getIds());
            Map<String, Object> response = new HashMap<>();
            response.put("message", count + "件のバッジを有効化しました");
            response.put("count", count);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            logger.error("バッジ一括有効化エラー", e);
            return ResponseEntity.internalServerError().body(createErrorResponse("バッジの有効化に失敗しました"));
        }
    }

    @PostMapping("/disable")
    public ResponseEntity<?> disableBadges(@Valid @RequestBody BulkLongActionRequest request) {
        try {
            int count = adminBadgeService.disableBadges(request.getIds());
            Map<String, Object> response = new HashMap<>();
            response.put("message", count + "件のバッジを無効化しました");
            response.put("count", count);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            logger.error("バッジ一括無効化エラー", e);
            return ResponseEntity.internalServerError().body(createErrorResponse("バッジの無効化に失敗しました"));
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
