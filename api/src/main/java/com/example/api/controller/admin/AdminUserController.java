package com.example.api.controller.admin;

import com.example.api.dto.admin.AdminUserDetailResponse;
import com.example.api.dto.admin.AdminUserListResponse;
import com.example.api.dto.admin.BulkUserActionRequest;
import com.example.api.service.admin.AdminUserService;
import jakarta.validation.Valid;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

/**
 * 管理者用ユーザー管理コントローラー
 */
@RestController
@RequestMapping("/api/admin/users")
public class AdminUserController {

    private static final Logger logger = LoggerFactory.getLogger(AdminUserController.class);

    @Autowired
    private AdminUserService adminUserService;

    /**
     * ユーザー一覧取得
     */
    @GetMapping
    public ResponseEntity<?> getUsers(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(required = false) Long id,
            @RequestParam(required = false) String userUuid,
            @RequestParam(required = false) String username,
            @RequestParam(required = false) String email,
            @RequestParam(required = false) Boolean banFlag,
            @RequestParam(required = false) Boolean subscribeFlag,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime createdFrom,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime createdTo,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime offlineFrom,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime offlineTo,
            @RequestParam(defaultValue = "desc") String sortDirection) {

        try {
            AdminUserListResponse response = adminUserService.getUsers(
                    page, size, id, userUuid, username, email,
                    banFlag, subscribeFlag, createdFrom, createdTo, offlineFrom, offlineTo, sortDirection);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            logger.error("ユーザー一覧取得エラー", e);
            return ResponseEntity.internalServerError().body(createErrorResponse("ユーザー一覧の取得に失敗しました"));
        }
    }

    /**
     * ユーザー詳細取得
     */
    @GetMapping("/{id}")
    public ResponseEntity<?> getUserDetail(@PathVariable Long id) {
        try {
            AdminUserDetailResponse response = adminUserService.getUserDetail(id);
            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.notFound().build();
        } catch (Exception e) {
            logger.error("ユーザー詳細取得エラー", e);
            return ResponseEntity.internalServerError().body(createErrorResponse("ユーザー詳細の取得に失敗しました"));
        }
    }

    /**
     * ユーザー一括停止
     */
    @PostMapping("/freeze")
    public ResponseEntity<?> freezeUsers(@Valid @RequestBody BulkUserActionRequest request) {
        try {
            int count = adminUserService.freezeUsers(request.getUserIds());
            Map<String, Object> response = new HashMap<>();
            response.put("message", count + "件のユーザーを停止しました");
            response.put("count", count);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            logger.error("ユーザー一括停止エラー", e);
            return ResponseEntity.internalServerError().body(createErrorResponse("ユーザーの停止に失敗しました"));
        }
    }

    /**
     * ユーザー一括解除
     */
    @PostMapping("/unfreeze")
    public ResponseEntity<?> unfreezeUsers(@Valid @RequestBody BulkUserActionRequest request) {
        try {
            int count = adminUserService.unfreezeUsers(request.getUserIds());
            Map<String, Object> response = new HashMap<>();
            response.put("message", count + "件のユーザーを復旧しました");
            response.put("count", count);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            logger.error("ユーザー一括解除エラー", e);
            return ResponseEntity.internalServerError().body(createErrorResponse("ユーザーの復旧に失敗しました"));
        }
    }

    private Map<String, String> createErrorResponse(String message) {
        Map<String, String> error = new HashMap<>();
        error.put("error", message);
        return error;
    }
}
