package com.example.api.repository;

import com.example.api.entity.Admin;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

/**
 * 管理者リポジトリ
 * 管理者テーブルへのアクセスを提供します
 */
@Repository
public interface AdminRepository extends JpaRepository<Admin, Long> {

    /**
     * 管理者IDで検索
     * @param adminId 管理者ID
     * @return 管理者エンティティ
     */
    Optional<Admin> findByAdmin_id(Long adminId);
}
