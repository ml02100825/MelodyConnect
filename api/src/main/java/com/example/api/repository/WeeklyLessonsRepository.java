package com.example.api.repository;

import com.example.api.entity.WeeklyLessons;
import com.example.api.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import org.springframework.data.domain.Pageable;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

/**
 * 週間学習リポジトリインターフェース
 * WeeklyLessonsエンティティのデータベース操作を提供します
 */
@Repository
public interface WeeklyLessonsRepository extends JpaRepository<WeeklyLessons, Long> {

    List<WeeklyLessons> findByUser(User user);

    List<WeeklyLessons> findByUserAndWeekFlag(User user, Boolean weekFlag);

    @Query("SELECT w FROM WeeklyLessons w WHERE w.user = :user ORDER BY w.createdAt DESC")
    Optional<WeeklyLessons> findLatestByUser(@Param("user") User user);

    @Query("UPDATE WeeklyLessons w SET w.weekFlag = false WHERE w.createdAt < :cutoffDate AND w.weekFlag = true")
    void updateWeekFlagForOldRecords(@Param("cutoffDate") LocalDateTime cutoffDate);

    // ===== ランキング用 =====

    /**
     * 最新のweekFlagを取得
     */
    @Query("SELECT MAX(w.weekFlag) FROM WeeklyLessons w")
    Integer findLatestWeekFlag();

    /**
     * 指定されたweekFlagでレッスン数の多い順に取得
     */
    List<WeeklyLessons> findByWeekFlagOrderByLessonsNumDesc(
            Integer weekFlag,
            Pageable pageable
    );

    /**
     * weekFlagがtrueのレコードをレッスン数の多い順に取得
     */
    List<WeeklyLessons> findByWeekFlagTrueOrderByLessonsNumDesc(Pageable pageable);
}