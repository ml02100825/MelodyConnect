package com.example.api.repository;

import com.example.api.entity.Badge;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.stereotype.Repository;

import java.util.Optional;

/**
 * Badge Repository
 */
@Repository
public interface BadgeRepository extends JpaRepository<Badge, Long>, JpaSpecificationExecutor<Badge> {

    /**
     * バッジ名で検索
     */
    Optional<Badge> findByBadgeName(String badgeName);

    /**
     * バッジ名で存在チェック
     */
    boolean existsByBadgeName(String badgeName);
}
