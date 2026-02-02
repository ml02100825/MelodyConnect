package com.example.api.repository;

import com.example.api.dto.UserRanking;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

/**
 * ユーザーランキング情報を取得するリポジトリ
 * UserエンティティではなくUserRankingプロジェクションを返す
 */
@Repository
public interface UserRankingRepository extends JpaRepository<com.example.api.entity.User, Long> {
    
    /**
     * 複数のユーザーIDに対応するユーザー名を取得
     * @param userIds ユーザーIDのリスト
     * @return UserRankingプロジェクションのリスト
     */
    @Query("SELECT new com.example.api.dto.UserRanking(u.id, u.username) " +
           "FROM User u WHERE u.id IN :userIds")
    List<UserRanking> findByUserIdIn(@Param("userIds") java.util.Collection<Long> userIds);
}