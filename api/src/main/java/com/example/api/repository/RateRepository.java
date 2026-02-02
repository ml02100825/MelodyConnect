package com.example.api.repository;

import com.example.api.entity.Rate;
import com.example.api.entity.User;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface RateRepository extends JpaRepository<Rate, Long> {

    List<Rate> findByUser(User user);
    Optional<Rate> findByUserAndSeason(User user, Integer season);
    List<Rate> findBySeason(Integer season);
    boolean existsByUserAndSeason(User user, Integer season);

    // ランキング用
    @Query("SELECT r FROM Rate r JOIN FETCH r.user WHERE r.season = :season ORDER BY r.rate DESC")
    List<Rate> findRankingBySeason(@Param("season") Integer season, Pageable pageable);

    @Query("SELECT r FROM Rate r JOIN FETCH r.user WHERE r.season = :season AND r.user.id IN :userIds ORDER BY r.rate DESC")
    List<Rate> findFriendRankingBySeason(@Param("season") Integer season, @Param("userIds") List<Long> userIds, Pageable pageable);

    // ★追加: 存在するシーズン番号リスト
    @Query("SELECT DISTINCT r.season FROM Rate r ORDER BY r.season ASC")
    List<Integer> findDistinctSeasons();
}