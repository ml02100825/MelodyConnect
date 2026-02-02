package com.example.api.repository;

import com.example.api.entity.Rate;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface UserRateRepository extends JpaRepository<Rate, Long> {
    
    /**
     * 指定されたシーズンのレートを降順で取得
     * @param seasonId シーズンID
     * @return [userId, rate] の配列のリスト
     */
    @Query(value = "SELECT ur.user_id, ur.rate " +
                   "FROM rate ur " +
                   "WHERE ur.season = :seasonId " +
                   "ORDER BY ur.rate DESC", 
           nativeQuery = true)
    List<Object[]> findRatesBySeasonIdOrderByRate(@Param("seasonId") Long seasonId);
    
    /**
     * シーズンランキングを取得（RankingServiceで使用）
     * @param seasonId シーズンID
     * @return [userId, rate] の配列のリスト
     */
    @Query(value = "SELECT ur.user_id, ur.rate " +
                   "FROM user_rates ur " +
                   "WHERE ur.season = :seasonId " +
                   "ORDER BY ur.rate DESC", 
           nativeQuery = true)
    List<Object[]> findSeasonRanking(@Param("seasonId") Long seasonId);
    
    /**
     * 特定のユーザーとシーズンのレートを取得
     * @param userId ユーザーID
     * @param season シーズンID
     * @return Rate
     */
    Optional<Rate> findByUserIdAndSeason(Long userId, Long season);
    
    /**
     * 特定のユーザーの全シーズンのレートを取得
     * @param userId ユーザーID
     * @return Rateのリスト
     */
    List<Rate> findByUserId(Long userId);
}