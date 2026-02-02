package com.example.api.controller;

import com.example.api.dto.ContactRequest;
import com.example.api.service.ContactService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/contacts")
public class ContactController {

    @Autowired
    private ContactService contactService;

    @PostMapping
    public ResponseEntity<?> createContact(@AuthenticationPrincipal Long userId,
                                           @RequestBody ContactRequest request) {
        if (request.getTitle() == null || request.getTitle().isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("error", "タイトルは必須です"));
        }
        if (request.getContactDetail() == null || request.getContactDetail().isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("error", "お問い合わせ内容は必須です"));
        }

        contactService.createContact(userId, request);
        return ResponseEntity.ok(Map.of("message", "お問い合わせを受け付けました"));
    }
}