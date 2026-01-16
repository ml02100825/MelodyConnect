package com.example.api.repository;

import com.example.api.entity.Rate;
import com.example.api.entity.User;
import org.springframework.data.domain.Pageable; // 追加
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query; // 追加
import org.springframework.data.repository.query.Param; // 追加
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

/**
 * レートリポジトリインターフェース
 */
@Repository
public interface RateRepository extends JpaRepository<Rate, Long> {

    // ==========================================
    //  既存のメソッド（そのまま残す）
    // ==========================================

    /**
     * ユーザーIDでレート情報を検索
     */
    List<Rate> findByUser(User user);

    /**
     * ユーザーIDとシーズンでレート情報を検索
     */
    Optional<Rate> findByUserAndSeason(User user, Integer season);

    /**
     * シーズンでレート情報を検索 (ランキング用ではない単純検索)
     */
    List<Rate> findBySeason(Integer season);

    /**
     * ユーザーIDとシーズンの組み合わせが存在するかチェック
     */
    boolean existsByUserAndSeason(User user, Integer season);


    // ==========================================
    //  ★ここから下を追加してください (ランキング用)
    // ==========================================

    /**
     * ランキング用: 指定シーズンのレート順に取得
     * JOIN FETCHを使ってUser情報も一度に取得し、高速化しています。
     */
    @Query("SELECT r FROM Rate r JOIN FETCH r.user WHERE r.season = :season ORDER BY r.rate DESC")
    List<Rate> findRankingBySeason(@Param("season") Integer season, Pageable pageable);

    /**
     * ランキング用: 指定したユーザーIDリスト（フレンド）に絞ってレート順に取得
     */
    @Query("SELECT r FROM Rate r JOIN FETCH r.user WHERE r.season = :season AND r.user.id IN :userIds ORDER BY r.rate DESC")
    List<Rate> findFriendRankingBySeason(@Param("season") Integer season, @Param("userIds") List<Long> userIds, Pageable pageable);
}