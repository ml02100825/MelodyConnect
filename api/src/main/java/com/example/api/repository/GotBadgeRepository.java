package com.example.api.repository;

import com.example.api.entity.GotBadge;
import com.example.api.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

/**
 * 取得バッジリポジトリインターフェース
 * 取得バッジエンティティのデータベース操作を提供します
 */
@Repository
public interface GotBadgeRepository extends JpaRepository<GotBadge, Long> {

    /**
     * ユーザーの取得バッジ一覧を検索
     * @param user ユーザー
     * @return 取得バッジ一覧
     */
    List<GotBadge> findByUser(User user);
}
