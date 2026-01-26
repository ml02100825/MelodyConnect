package com.example.api.repository;

import com.example.api.entity.Artist;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

/**
 * Artist Repository
 */
@Repository
public interface ArtistRepository extends JpaRepository<Artist, Long>, JpaSpecificationExecutor<Artist> {

    /**
     * アーティスト名で検索
     */
    Optional<Artist> findByArtistName(String artistName);

    /**
     * アーティストAPI IDで検索
     */
    Optional<Artist> findByArtistApiId(String artistApiId);

    /**
     * アーティスト名の部分一致でID一覧を取得
     */
    @Query("SELECT a.artistId FROM Artist a WHERE a.artistName LIKE %:artistName%")
    List<Long> findArtistIdsByArtistNameContaining(@Param("artistName") String artistName);
    /**
     * 指定日時以降に同期されていないアーティストを取得
     * lastSyncedAtがnullまたは指定日時より前のアーティストを返す
     *
     * @param dateTime 基準日時
     * @return 同期が必要なアーティストのリスト
     */
    @Query("SELECT a FROM Artist a WHERE a.lastSyncedAt IS NULL OR a.lastSyncedAt < :dateTime")
    List<Artist> findArtistsNotSyncedSince(@Param("dateTime") LocalDateTime dateTime);

    /**
     * 最後に同期されたアーティストを取得（デバッグ用）
     */
    Optional<Artist> findFirstByOrderByLastSyncedAtDesc();

}
