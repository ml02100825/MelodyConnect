package com.example.api.repository;

import com.example.api.entity.Contact;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ContactRepository extends JpaRepository<Contact, Long> {
    // 特定のユーザーのお問い合わせ履歴を取得する場合に使用
    List<Contact> findByUserId(Long userId);
}