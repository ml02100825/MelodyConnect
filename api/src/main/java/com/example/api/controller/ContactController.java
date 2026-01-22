package com.example.api.controller;

import com.example.api.dto.ContactRequest;
import com.example.api.service.ContactService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/contacts")
public class ContactController {

    @Autowired
    private ContactService contactService;

    @PostMapping
    public ResponseEntity<?> createContact(
            @RequestBody ContactRequest request,
            @AuthenticationPrincipal UserDetails userDetails) {
        
        // 認証情報からユーザーIDを取得 (username=userIdとして実装されている前提)
        Long userId = Long.parseLong(userDetails.getUsername());
        
        try {
            contactService.createContact(userId, request);
            return ResponseEntity.ok(Map.of("message", "お問い合わせを送信しました"));
        } catch (Exception e) {
            return ResponseEntity.status(500).body(Map.of("error", "送信に失敗しました: " + e.getMessage()));
        }
    }
}