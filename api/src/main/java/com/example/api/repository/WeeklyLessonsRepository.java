package com.example.api.repository;

import com.example.api.entity.WeeklyLessons;
import com.example.api.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

/**
 * 週間学習リポジトリインターフェース
 * WeeklyLessonsエンティティのデータベース操作を提供します
 */
@Repository
public interface WeeklyLessonsRepository extends JpaRepository<WeeklyLessons, Long> {

    /**
     * ユーザーIDで週間学習情報を検索
     * @param user ユーザーエンティティ
     * @return 週間学習のリスト
     */
    List<WeeklyLessons> findByUser(User user);

    /**
     * ユーザーIDで有効な（week_flag=true）週間学習情報を検索
     * @param user ユーザーエンティティ
     * @param weekFlag 週フラグ
     * @return 週間学習のリスト
     */
    List<WeeklyLessons> findByUserAndWeekFlag(User user, Boolean weekFlag);

    /**
     * ユーザーIDで最新の週間学習情報を検索
     * @param user ユーザーエンティティ
     * @return 最新の週間学習情報（存在する場合）
     */
    @Query("SELECT w FROM WeeklyLessons w WHERE w.user = :user ORDER BY w.createdAt DESC")
    Optional<WeeklyLessons> findLatestByUser(@Param("user") User user);

    /**
     * 指定日時より古い週間学習情報のweek_flagを更新
     * @param cutoffDate カットオフ日時
     */
    @Query("UPDATE WeeklyLessons w SET w.weekFlag = false WHERE w.createdAt < :cutoffDate AND w.weekFlag = true")
    void updateWeekFlagForOldRecords(@Param("cutoffDate") LocalDateTime cutoffDate);
}
