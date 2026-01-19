package com.example.api.repository;

import com.example.api.entity.WeeklyLessons;
import com.example.api.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.data.domain.Pageable;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface WeeklyLessonsRepository extends JpaRepository<WeeklyLessons, Long> {

    List<WeeklyLessons> findByUser(User user);
    List<WeeklyLessons> findByUserAndWeekFlag(User user, Boolean weekFlag);

    @Query("SELECT w FROM WeeklyLessons w WHERE w.user = :user ORDER BY w.createdAt DESC")
    Optional<WeeklyLessons> findLatestByUser(@Param("user") User user);

    @Query("SELECT MAX(w.weekFlag) FROM WeeklyLessons w")
    Integer findLatestWeekFlag();

    List<WeeklyLessons> findByWeekFlagOrderByLessonsNumDesc(Integer weekFlag, Pageable pageable);
    List<WeeklyLessons> findByWeekFlagTrueOrderByLessonsNumDesc(Pageable pageable);

    // ★バッチ処理用: 古いデータのフラグを下ろす
    @Modifying
    @Transactional
    @Query("UPDATE WeeklyLessons w SET w.weekFlag = false WHERE w.createdAt < :cutoffDate AND w.weekFlag = true")
    void updateWeekFlagForOldRecords(@Param("cutoffDate") LocalDateTime cutoffDate);

    // ★ランキング用: weekFlag=true のレコードのみ集計
    @Query("SELECT u, SUM(w.lessonsNum) as total " +
           "FROM WeeklyLessons w " +
           "JOIN w.user u " + 
           "WHERE w.weekFlag = true " +
           "GROUP BY u " +
           "ORDER BY total DESC")
    List<Object[]> findCurrentWeeklyRanking(Pageable pageable);

    @Query("SELECT u, SUM(w.lessonsNum) as total " +
           "FROM WeeklyLessons w " +
           "JOIN w.user u " + 
           "WHERE w.weekFlag = true " +
           "AND u.id IN :userIds " +
           "GROUP BY u " +
           "ORDER BY total DESC")
    List<Object[]> findCurrentFriendWeeklyRanking(@Param("userIds") List<Long> userIds,
                                                  Pageable pageable);
}