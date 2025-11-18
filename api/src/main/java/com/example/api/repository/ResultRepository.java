package com.example.api.repository;

import com.example.api.entity.Result;
import org.springframework.data.jpa.repository.JpaRepository;
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
    List<Result> findByPlayerId(Long playerId);

    /**
     * 対戦相手IDで結果を検索
     * @param enemyId 対戦相手ID
     * @return 結果のリスト
     */
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
}
