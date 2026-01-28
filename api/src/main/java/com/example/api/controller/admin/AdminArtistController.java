package com.example.api.controller.admin;

import com.example.api.dto.admin.AdminArtistRequest;
import com.example.api.dto.admin.AdminArtistResponse;
import com.example.api.dto.admin.BulkLongActionRequest;
import com.example.api.service.admin.AdminArtistService;
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

@RestController
@RequestMapping("/api/admin/artists")
public class AdminArtistController {

    private static final Logger logger = LoggerFactory.getLogger(AdminArtistController.class);

    @Autowired
    private AdminArtistService adminArtistService;

    @GetMapping
    public ResponseEntity<?> getArtists(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(required = false) String idSearch,
            @RequestParam(required = false) String artistName,
            @RequestParam(required = false) String genreName,
            @RequestParam(required = false) Boolean isActive,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime createdFrom,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime createdTo,
            @RequestParam(defaultValue = "desc") String sortDirection) {
        try {
            return ResponseEntity.ok(
                    adminArtistService.getArtists(
                            page, size, idSearch, artistName, genreName, isActive, createdFrom, createdTo, sortDirection));
        } catch (Exception e) {
            logger.error("アーティスト一覧取得エラー", e);
            return ResponseEntity.internalServerError().body(createErrorResponse("アーティスト一覧の取得に失敗しました"));
        }
    }

    @GetMapping("/{id}")
    public ResponseEntity<?> getArtist(@PathVariable Long id) {
        try {
            return ResponseEntity.ok(adminArtistService.getArtist(id));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.notFound().build();
        } catch (Exception e) {
            logger.error("アーティスト詳細取得エラー", e);
            return ResponseEntity.internalServerError().body(createErrorResponse("アーティスト詳細の取得に失敗しました"));
        }
    }

    @PostMapping
    public ResponseEntity<?> createArtist(@Valid @RequestBody AdminArtistRequest request) {
        try {
            AdminArtistResponse response = adminArtistService.createArtist(request);
            return ResponseEntity.status(HttpStatus.CREATED).body(response);
        } catch (Exception e) {
            logger.error("アーティスト作成エラー", e);
            return ResponseEntity.internalServerError().body(createErrorResponse("アーティストの作成に失敗しました"));
        }
    }

    @PutMapping("/{id}")
    public ResponseEntity<?> updateArtist(@PathVariable Long id, @Valid @RequestBody AdminArtistRequest request) {
        try {
            return ResponseEntity.ok(adminArtistService.updateArtist(id, request));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.notFound().build();
        } catch (Exception e) {
            logger.error("アーティスト更新エラー", e);
            return ResponseEntity.internalServerError().body(createErrorResponse("アーティストの更新に失敗しました"));
        }
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteArtist(@PathVariable Long id) {
        try {
            adminArtistService.deleteArtist(id);
            return ResponseEntity.ok(createSuccessResponse("アーティストを削除しました"));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.notFound().build();
        } catch (Exception e) {
            logger.error("アーティスト削除エラー", e);
            return ResponseEntity.internalServerError().body(createErrorResponse("アーティストの削除に失敗しました"));
        }
    }

    @PostMapping("/enable")
    public ResponseEntity<?> enableArtists(@Valid @RequestBody BulkLongActionRequest request) {
        try {
            int count = adminArtistService.enableArtists(request.getIds());
            Map<String, Object> response = new HashMap<>();
            response.put("message", count + "件のアーティストを有効化しました");
            response.put("count", count);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            logger.error("アーティスト一括有効化エラー", e);
            return ResponseEntity.internalServerError().body(createErrorResponse("アーティストの有効化に失敗しました"));
        }
    }

    @PostMapping("/disable")
    public ResponseEntity<?> disableArtists(@Valid @RequestBody BulkLongActionRequest request) {
        try {
            int count = adminArtistService.disableArtists(request.getIds());
            Map<String, Object> response = new HashMap<>();
            response.put("message", count + "件のアーティストを無効化しました");
            response.put("count", count);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            logger.error("アーティスト一括無効化エラー", e);
            return ResponseEntity.internalServerError().body(createErrorResponse("アーティストの無効化に失敗しました"));
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
