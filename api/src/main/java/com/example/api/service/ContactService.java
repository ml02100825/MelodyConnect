package com.example.api.service;

import com.example.api.dto.ContactRequest;
import com.example.api.entity.Contact;
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
        // ユーザーの存在確認
        if (!userRepository.existsById(userId)) {
            throw new IllegalArgumentException("User not found");
        }

        Contact contact = new Contact();
        contact.setUserId(userId);
        contact.setTitle(request.getTitle());
        contact.setContactDetail(request.getContactDetail());
        
        // 画像URLをセット（nullの場合はそのままnullが入る）
        // 複数画像に対応する場合、ここでカンマ区切りにするなどの処理が可能ですが、
        // 今回はシンプルにリクエストの値をそのまま保存します。
        contact.setImageUrl(request.getImageUrl()); 

        contactRepository.save(contact);
    }
}