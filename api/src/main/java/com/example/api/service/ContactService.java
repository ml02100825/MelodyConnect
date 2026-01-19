package com.example.api.service;

import com.example.api.dto.ContactRequest;
import com.example.api.entity.Contact;
import com.example.api.entity.User;
import com.example.api.repository.ContactRepository;
import com.example.api.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class ContactService {

    @Autowired
    private ContactRepository contactRepository;

    @Autowired
    private UserRepository userRepository;

    @Transactional
    public void createContact(ContactRequest request) {
        // ユーザーの存在確認
        User user = userRepository.findById(request.getUserId())
                .orElseThrow(() -> new IllegalArgumentException("ユーザーが見つかりません"));

        // Contactエンティティの作成
        Contact contact = new Contact();
        contact.setUser(user);
        contact.setTitle(request.getTitle());
        contact.setContact_detail(request.getContent());
        contact.setImage_url(request.getImageUrl());

        // 保存
        contactRepository.save(contact);
    }
}