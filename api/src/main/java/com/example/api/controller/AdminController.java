package com.example.api.controller;

import com.example.api.entity.Contact;
import com.example.api.repository.ContactRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/admin")
public class AdminController {

    @Autowired
    private ContactRepository contactRepository;

    // 全お問い合わせ取得
    // セキュリティのため、本来は @PreAuthorize("hasRole('ADMIN')") などが必要です
    @GetMapping("/contacts")
    public List<Contact> getAllContacts() {
        return contactRepository.findAll();
    }
}