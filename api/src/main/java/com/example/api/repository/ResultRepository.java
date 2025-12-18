package com.example.api.repository;

import com.example.api.entity.Result;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

/**
 * バトル結果リポジトリインターフェース
 * Resultエンティティのデータベース操作を提供します
 */
@Repository
public interface ResultRepository extends JpaRepository<Result, Long> {

    /**
     * プレイヤーIDで結果を検索
     * @param playerId プレイヤーID
     * @return 結果のリスト
     */
    @Query("SELECT r FROM Result r WHERE r.player.id = ?1")
    List<Result> findByPlayerId(Long playerId);

    /**
     * 対戦相手IDで結果を検索
     * @param enemyId 対戦相手ID
     * @return 結果のリスト
     */
    @Query("SELECT r FROM Result r WHERE r.enemy.id = ?1")
    List<Result> findByEnemyId(Long enemyId);

    /**
     * マッチUUIDで結果を検索
     * @param matchUuid マッチUUID
     * @return 結果（存在する場合）
     */
    Optional<Result> findByMatchUuid(String matchUuid);

    /**
     * マッチUUIDで両方のプレイヤーの結果を検索
     * @param matchUuid マッチUUID
     * @return 結果のリスト（通常2件）
     */
    List<Result> findAllByMatchUuid(String matchUuid);

    /**
     * マッチUUIDとプレイヤーIDで結果を検索（重複チェック用）
     * @param matchUuid マッチUUID
     * @param playerId プレイヤーID
     * @return 結果（存在する場合）
     */
    @Query("SELECT r FROM Result r WHERE r.matchUuid = ?1 AND r.player.id = ?2")
    Optional<Result> findByMatchUuidAndPlayerId(String matchUuid, Long playerId);

    /**
     * マッチUUIDとプレイヤーIDの組み合わせが存在するかチェック
     * @param matchUuid マッチUUID
     * @param playerId プレイヤーID
     * @return 存在する場合true
     */
    @Query("SELECT CASE WHEN COUNT(r) > 0 THEN true ELSE false END FROM Result r WHERE r.matchUuid = ?1 AND r.player.id = ?2")
    boolean existsByMatchUuidAndPlayerId(String matchUuid, Long playerId);

    /**
     * プレイヤーIDで結果を新しい順に検索
     * @param playerId プレイヤーID
     * @return 結果のリスト（新しい順）
     */
    @Query("SELECT r FROM Result r WHERE r.player.id = ?1 ORDER BY r.endedAt DESC")
    List<Result> findByPlayerIdOrderByEndedAtDesc(Long playerId);

    /**
     * プレイヤーIDとマッチタイプで結果を検索
     * @param playerId プレイヤーID
     * @param matchType マッチタイプ
     * @return 結果のリスト
     */
    @Query("SELECT r FROM Result r WHERE r.player.id = ?1 AND r.matchType = ?2 ORDER BY r.endedAt DESC")
    List<Result> findByPlayerIdAndMatchType(Long playerId, Result.MatchType matchType);
}
