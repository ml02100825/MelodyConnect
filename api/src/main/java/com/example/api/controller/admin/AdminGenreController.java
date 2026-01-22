package com.example.api.controller.admin;

import com.example.api.dto.admin.AdminGenreRequest;
import com.example.api.dto.admin.AdminGenreResponse;
import com.example.api.dto.admin.BulkLongActionRequest;
import com.example.api.service.admin.AdminGenreService;
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
@RequestMapping("/api/admin/genres")
public class AdminGenreController {

    private static final Logger logger = LoggerFactory.getLogger(AdminGenreController.class);

    @Autowired
    private AdminGenreService adminGenreService;

    @GetMapping
    public ResponseEntity<?> getGenres(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(required = false) String name,
            @RequestParam(required = false) Boolean isActive) {
        try {
            return ResponseEntity.ok(adminGenreService.getGenres(page, size, name, isActive));
        } catch (Exception e) {
            logger.error("ジャンル一覧取得エラー", e);
            return ResponseEntity.internalServerError().body(createErrorResponse("ジャンル一覧の取得に失敗しました"));
        }
    }

    @GetMapping("/{id}")
    public ResponseEntity<?> getGenre(@PathVariable Long id) {
        try {
            return ResponseEntity.ok(adminGenreService.getGenre(id));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.notFound().build();
        } catch (Exception e) {
            logger.error("ジャンル詳細取得エラー", e);
            return ResponseEntity.internalServerError().body(createErrorResponse("ジャンル詳細の取得に失敗しました"));
        }
    }

    @PostMapping
    public ResponseEntity<?> createGenre(@Valid @RequestBody AdminGenreRequest request) {
        try {
            AdminGenreResponse response = adminGenreService.createGenre(request);
            return ResponseEntity.status(HttpStatus.CREATED).body(response);
        } catch (Exception e) {
            logger.error("ジャンル作成エラー", e);
            return ResponseEntity.internalServerError().body(createErrorResponse("ジャンルの作成に失敗しました"));
        }
    }

    @PutMapping("/{id}")
    public ResponseEntity<?> updateGenre(@PathVariable Long id, @Valid @RequestBody AdminGenreRequest request) {
        try {
            return ResponseEntity.ok(adminGenreService.updateGenre(id, request));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.notFound().build();
        } catch (Exception e) {
            logger.error("ジャンル更新エラー", e);
            return ResponseEntity.internalServerError().body(createErrorResponse("ジャンルの更新に失敗しました"));
        }
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteGenre(@PathVariable Long id) {
        try {
            adminGenreService.deleteGenre(id);
            return ResponseEntity.ok(createSuccessResponse("ジャンルを削除しました"));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.notFound().build();
        } catch (Exception e) {
            logger.error("ジャンル削除エラー", e);
            return ResponseEntity.internalServerError().body(createErrorResponse("ジャンルの削除に失敗しました"));
        }
    }

    @PostMapping("/enable")
    public ResponseEntity<?> enableGenres(@Valid @RequestBody BulkLongActionRequest request) {
        try {
            int count = adminGenreService.enableGenres(request.getIds());
            Map<String, Object> response = new HashMap<>();
            response.put("message", count + "件のジャンルを有効化しました");
            response.put("count", count);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            logger.error("ジャンル一括有効化エラー", e);
            return ResponseEntity.internalServerError().body(createErrorResponse("ジャンルの有効化に失敗しました"));
        }
    }

    @PostMapping("/disable")
    public ResponseEntity<?> disableGenres(@Valid @RequestBody BulkLongActionRequest request) {
        try {
            int count = adminGenreService.disableGenres(request.getIds());
            Map<String, Object> response = new HashMap<>();
            response.put("message", count + "件のジャンルを無効化しました");
            response.put("count", count);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            logger.error("ジャンル一括無効化エラー", e);
            return ResponseEntity.internalServerError().body(createErrorResponse("ジャンルの無効化に失敗しました"));
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
