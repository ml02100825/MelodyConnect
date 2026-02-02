package com.example.api.repository;

import com.example.api.entity.Badge;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.stereotype.Repository;

import java.util.List;
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
        // 全件取得 (有効かつ削除されていない)
        List<Badge> findByIsActiveTrueAndIsDeletedFalse();

    // ★追加: モード(数値)指定での取得用
    List<Badge> findByModeAndIsActiveTrueAndIsDeletedFalse(Integer mode);

}

