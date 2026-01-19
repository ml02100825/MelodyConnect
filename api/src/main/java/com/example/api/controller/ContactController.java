package com.example.api.controller;

import com.example.api.dto.ContactRequest;
import com.example.api.service.ContactService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/contacts")
public class ContactController {

    @Autowired
    private ContactService contactService;

    @PostMapping
    public ResponseEntity<?> createContact(@RequestBody ContactRequest request) {
        try {
            contactService.createContact(request);
            
            Map<String, String> response = new HashMap<>();
            response.put("message", "お問い合わせを受け付けました");
            return ResponseEntity.ok(response);
            
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(createError(e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.status(500).body(createError("送信中にエラーが発生しました"));
        }
    }

    private Map<String, String> createError(String message) {
        Map<String, String> error = new HashMap<>();
        error.put("error", message);
        return error;
    }
}