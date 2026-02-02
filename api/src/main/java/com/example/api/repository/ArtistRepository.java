package com.example.api.repository;

import com.example.api.entity.Artist;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

/**
 * Artistエンティティへのデータアクセスを行うリポジトリ。
 * <p>
 * 標準的なCRUD操作に加え、Spotify APIとの同期用メソッドや、
 * 管理画面からの検索用メソッド（Specification含む）を提供します。
 * </p>
 */
@Repository
public interface ArtistRepository extends JpaRepository<Artist, Long>, JpaSpecificationExecutor<Artist> {

    /**
     * アーティスト名（完全一致）で検索します。
     *
     * @param artistName 検索するアーティスト名
     * @return 該当するアーティスト（存在しない場合はEmpty）
     */
    Optional<Artist> findByArtistName(String artistName);

    /**
     * SpotifyのAPI ID（Spotify ID）からアーティストを検索します。
     * <p>外部APIとの連携時や、重複登録チェックに使用されます。</p>
     *
     * @param artistApiId Spotify側で採番されたID
     * @return 該当するアーティスト
     */
    Optional<Artist> findByArtistApiId(String artistApiId);

    /**
     * アーティスト名（部分一致）で検索し、該当するアーティストIDのリストを返します。
     * <p>主に管理画面の楽曲管理機能（AdminSongService）において、
     * 特定のアーティストに関連する楽曲を絞り込む際に使用されます。</p>
     *
     * @param artistName 検索キーワード（部分一致）
     * @return アーティストIDのリスト
     */
    @Query("SELECT a.artistId FROM Artist a WHERE a.artistName LIKE %:artistName%")
    List<Long> findArtistIdsByArtistNameContaining(@Param("artistName") String artistName);

    /**
     * 指定した日時より前に同期された（または一度も同期されていない）アーティストを取得します。
     * <p>Spotify APIから最新情報を取得するバッチ処理（同期ジョブ）で使用されます。
     * データの鮮度を保つため、古いデータを持つアーティストを抽出する目的で使用します。</p>
     *
     * @param dateTime この日時以前に更新されたデータを対象とする（閾値）
     * @return 同期対象となるアーティストのリスト
     */
    @Query("SELECT a FROM Artist a WHERE a.lastSyncedAt IS NULL OR a.lastSyncedAt < :dateTime")
    List<Artist> findArtistsNotSyncedSince(@Param("dateTime") LocalDateTime dateTime);

    /**
     * 最も最近同期（更新）されたアーティストを1件取得します。
     * <p>バッチ処理のスケジューリングや、同期状況のモニタリングに使用されます。</p>
     *
     * @return 最後に同期されたアーティスト
     */
    Optional<Artist> findFirstByOrderByLastSyncedAtDesc();

    /**
     * 中間テーブル（artist_genre）へのレコードを物理挿入します。
     * <p>
     * 通常、Artistエンティティの保存は {@link #save(Object)} で行いますが、
     * 中間テーブルへの関連付けのみを明示的にSQLで行う必要がある場合（バッチ処理や特定の手動登録フローなど）に使用します。
     * </p>
     *
     * @param artistId  アーティストID
     * @param genreId   ジャンルID
     * @param createdAt レコード作成日時
     */
    @Modifying
    @Transactional
    @Query(value = "INSERT INTO artist_genre (artist_id, genre_id, created_at) VALUES (:artistId, :genreId, :createdAt)", 
           nativeQuery = true)
    void insertArtistGenre(
            @Param("artistId") Long artistId, 
            @Param("genreId") Long genreId,
            @Param("createdAt") LocalDateTime createdAt
    );
}