package com.example.api.controller.admin;

import com.example.api.dto.admin.AdminContactResponse;
import com.example.api.dto.admin.ContactStatusUpdateRequest;
import com.example.api.service.admin.AdminContactService;
import jakarta.validation.Valid;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/admin/contacts")
public class AdminContactController {

    private static final Logger logger = LoggerFactory.getLogger(AdminContactController.class);

    @Autowired
    private AdminContactService adminContactService;

    @GetMapping
    public ResponseEntity<?> getContacts(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(required = false) String status) {
        try {
            return ResponseEntity.ok(adminContactService.getContacts(page, size, status));
        } catch (Exception e) {
            logger.error("お問い合わせ一覧取得エラー", e);
            return ResponseEntity.internalServerError().body(createErrorResponse("お問い合わせ一覧の取得に失敗しました"));
        }
    }

    @GetMapping("/{id}")
    public ResponseEntity<?> getContact(@PathVariable Long id) {
        try {
            return ResponseEntity.ok(adminContactService.getContact(id));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.notFound().build();
        } catch (Exception e) {
            logger.error("お問い合わせ詳細取得エラー", e);
            return ResponseEntity.internalServerError().body(createErrorResponse("お問い合わせ詳細の取得に失敗しました"));
        }
    }

    @PutMapping("/{id}/status")
    public ResponseEntity<?> updateContactStatus(@PathVariable Long id, @Valid @RequestBody ContactStatusUpdateRequest request) {
        try {
            AdminContactResponse response = adminContactService.updateContactStatus(id, request);
            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.notFound().build();
        } catch (Exception e) {
            logger.error("お問い合わせステータス更新エラー", e);
            return ResponseEntity.internalServerError().body(createErrorResponse("お問い合わせステータスの更新に失敗しました"));
        }
    }

    private Map<String, String> createErrorResponse(String message) {
        Map<String, String> error = new HashMap<>();
        error.put("error", message);
        return error;
    }
}
