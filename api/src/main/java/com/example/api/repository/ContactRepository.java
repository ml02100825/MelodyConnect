package com.example.api.repository;

import com.example.api.entity.Contact;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.stereotype.Repository;

import java.util.List;

/**
 * Contact Repository
 */
@Repository
public interface ContactRepository extends JpaRepository<Contact, Long>, JpaSpecificationExecutor<Contact> {

    /**
     * ステータスで検索
     */
    List<Contact> findByStatus(String status);

    /**
     * ユーザーIDで検索
     */
    List<Contact> findByUserId(Long userId);
}
