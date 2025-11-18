package com.example.api.repository;

import com.example.api.entity.LHistory;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

/**
 * 学習履歴リポジトリ
 */
@Repository
public interface LHistoryRepository extends JpaRepository<LHistory, Long> {

    /**
     * ユーザーIDで学習履歴を検索
     */
    @Query(value = "SELECT * FROM l_history WHERE user_id = :userId ORDER BY learning_at DESC", nativeQuery = true)
    List<LHistory> findByUserId(@Param("userId") Long userId);

    /**
     * ユーザーIDで最新の学習履歴を取得
     */
    @Query(value = "SELECT * FROM l_history WHERE user_id = :userId ORDER BY learning_at DESC LIMIT 1", nativeQuery = true)
    LHistory findLatestByUserId(@Param("userId") Long userId);
}
