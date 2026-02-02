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
 * Artist Repository
 */
@Repository
public interface ArtistRepository extends JpaRepository<Artist, Long>, JpaSpecificationExecutor<Artist> {

    Optional<Artist> findByArtistName(String artistName);

    Optional<Artist> findByArtistApiId(String artistApiId);

    @Query("SELECT a.artistId FROM Artist a WHERE a.artistName LIKE %:artistName%")
    List<Long> findArtistIdsByArtistNameContaining(@Param("artistName") String artistName);

    @Query("SELECT a FROM Artist a WHERE a.lastSyncedAt IS NULL OR a.lastSyncedAt < :dateTime")
    List<Artist> findArtistsNotSyncedSince(@Param("dateTime") LocalDateTime dateTime);

    Optional<Artist> findFirstByOrderByLastSyncedAtDesc();

    // ArtistテーブルへのINSERT (Native Query)
    @Modifying
    @Transactional
    @Query(value = "INSERT INTO artist (artist_name, artist_api_id, image_url, created_at, last_synced_at, is_active, is_deleted, genre_id) " +
                   "VALUES (:artistName, :artistApiId, :imageUrl, :createdAt, :lastSyncedAt, :isActive, :isDeleted, :genreId)", 
           nativeQuery = true)
    void insertArtistWithGenre(
            @Param("artistName") String artistName,
            @Param("artistApiId") String artistApiId,
            @Param("imageUrl") String imageUrl,
            @Param("createdAt") LocalDateTime createdAt,
            @Param("lastSyncedAt") LocalDateTime lastSyncedAt,
            @Param("isActive") boolean isActive,
            @Param("isDeleted") boolean isDeleted,
            @Param("genreId") Long genreId
    );

    // ★修正: artist_genre（中間テーブル）へのINSERTに created_at を追加
    @Modifying
    @Transactional
    @Query(value = "INSERT INTO artist_genre (artist_id, genre_id, created_at) VALUES (:artistId, :genreId, :createdAt)", 
           nativeQuery = true)
    void insertArtistGenre(
            @Param("artistId") Long artistId, 
            @Param("genreId") Long genreId,
            @Param("createdAt") LocalDateTime createdAt // 引数を追加
    );
}