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
    public void createContact(Long userId, ContactRequest request) {
        // ユーザーの取得
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        // 用意されている箱(テーブル)の形に合わせてデータを作成
        Contact contact = new Contact(
                user,
                request.getTitle(),
                request.getContactDetail(),
                request.getImageUrl()
        );

        // 箱に保存
        contactRepository.save(contact);
    }
}