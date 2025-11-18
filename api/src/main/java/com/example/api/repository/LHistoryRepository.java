package com.example.api.repository;

import com.example.api.entity.l_history;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

/**
 * 学習履歴リポジトリ
 */
@Repository
public interface LHistoryRepository extends JpaRepository<l_history, Long> {

    /**
     * ユーザーIDで学習履歴を検索
     */
    @Query(value = "SELECT * FROM l_history WHERE user_id = :userId ORDER BY learning_at DESC", nativeQuery = true)
    List<l_history> findByUserId(@Param("userId") Long userId);

    /**
     * ユーザーIDで最新の学習履歴を取得
     */
    @Query(value = "SELECT * FROM l_history WHERE user_id = :userId ORDER BY learning_at DESC LIMIT 1", nativeQuery = true)
    l_history findLatestByUserId(@Param("userId") Long userId);
}
