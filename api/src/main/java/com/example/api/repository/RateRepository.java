package com.example.api.repository;

import com.example.api.entity.Rate;
import com.example.api.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

/**
 * レートリポジトリインターフェース
 * レートエンティティのデータベース操作を提供します
 */
@Repository
public interface RateRepository extends JpaRepository<Rate, Long> {

    /**
     * ユーザーIDでレート情報を検索
     * @param user ユーザーエンティティ
     * @return レートのリスト
     */
    List<Rate> findByUser(User user);

    /**
     * ユーザーIDとシーズンでレート情報を検索
     * @param user ユーザーエンティティ
     * @param season シーズン番号
     * @return レート情報（存在する場合）
     */
    Optional<Rate> findByUserAndSeason(User user, Integer season);

    /**
     * シーズンでレート情報を検索
     * @param season シーズン番号
     * @return レートのリスト
     */
    List<Rate> findBySeason(Integer season);

    /**
     * ユーザーIDとシーズンの組み合わせが存在するかチェック
     * @param user ユーザーエンティティ
     * @param season シーズン番号
     * @return 存在する場合true
     */
    boolean existsByUserAndSeason(User user, Integer season);
}
