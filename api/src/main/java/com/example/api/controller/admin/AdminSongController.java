package com.example.api.controller.admin;

import com.example.api.dto.admin.AdminSongRequest;
import com.example.api.dto.admin.AdminSongResponse;
import com.example.api.dto.admin.BulkLongActionRequest;
import com.example.api.service.admin.AdminSongService;
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
@RequestMapping("/api/admin/songs")
public class AdminSongController {

    private static final Logger logger = LoggerFactory.getLogger(AdminSongController.class);

    @Autowired
    private AdminSongService adminSongService;

    @GetMapping
    public ResponseEntity<?> getSongs(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(required = false) String idSearch,
            @RequestParam(required = false) String songname,
            @RequestParam(required = false) String artistName,
            @RequestParam(required = false) Boolean isActive,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime createdFrom,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime createdTo,
            @RequestParam(defaultValue = "desc") String sortDirection) {
        try {
            return ResponseEntity.ok(
                    adminSongService.getSongs(
                            page, size, idSearch, songname, artistName, isActive, createdFrom, createdTo, sortDirection));
        } catch (Exception e) {
            logger.error("楽曲一覧取得エラー", e);
            return ResponseEntity.internalServerError().body(createErrorResponse("楽曲一覧の取得に失敗しました"));
        }
    }

    @GetMapping("/{id}")
    public ResponseEntity<?> getSong(@PathVariable Long id) {
        try {
            return ResponseEntity.ok(adminSongService.getSong(id));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.notFound().build();
        } catch (Exception e) {
            logger.error("楽曲詳細取得エラー", e);
            return ResponseEntity.internalServerError().body(createErrorResponse("楽曲詳細の取得に失敗しました"));
        }
    }

    @PostMapping
    public ResponseEntity<?> createSong(@Valid @RequestBody AdminSongRequest request) {
        try {
            AdminSongResponse response = adminSongService.createSong(request);
            return ResponseEntity.status(HttpStatus.CREATED).body(response);
        } catch (Exception e) {
            logger.error("楽曲作成エラー", e);
            return ResponseEntity.internalServerError().body(createErrorResponse("楽曲の作成に失敗しました"));
        }
    }

    @PutMapping("/{id}")
    public ResponseEntity<?> updateSong(@PathVariable Long id, @Valid @RequestBody AdminSongRequest request) {
        try {
            return ResponseEntity.ok(adminSongService.updateSong(id, request));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.notFound().build();
        } catch (Exception e) {
            logger.error("楽曲更新エラー", e);
            return ResponseEntity.internalServerError().body(createErrorResponse("楽曲の更新に失敗しました"));
        }
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteSong(@PathVariable Long id) {
        try {
            adminSongService.deleteSong(id);
            return ResponseEntity.ok(createSuccessResponse("楽曲を削除しました"));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.notFound().build();
        } catch (Exception e) {
            logger.error("楽曲削除エラー", e);
            return ResponseEntity.internalServerError().body(createErrorResponse("楽曲の削除に失敗しました"));
        }
    }

    @PostMapping("/enable")
    public ResponseEntity<?> enableSongs(@Valid @RequestBody BulkLongActionRequest request) {
        try {
            int count = adminSongService.enableSongs(request.getIds());
            Map<String, Object> response = new HashMap<>();
            response.put("message", count + "件の楽曲を有効化しました");
            response.put("count", count);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            logger.error("楽曲一括有効化エラー", e);
            return ResponseEntity.internalServerError().body(createErrorResponse("楽曲の有効化に失敗しました"));
        }
    }

    @PostMapping("/disable")
    public ResponseEntity<?> disableSongs(@Valid @RequestBody BulkLongActionRequest request) {
        try {
            int count = adminSongService.disableSongs(request.getIds());
            Map<String, Object> response = new HashMap<>();
            response.put("message", count + "件の楽曲を無効化しました");
            response.put("count", count);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            logger.error("楽曲一括無効化エラー", e);
            return ResponseEntity.internalServerError().body(createErrorResponse("楽曲の無効化に失敗しました"));
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
