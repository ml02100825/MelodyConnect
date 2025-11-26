package com.example.api.repository;

import com.example.api.entity.Song;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

/**
 * Song Repository
 */
@Repository
public interface SongRepository extends JpaRepository<Song, Long> {

    /**
     * Genius Song IDで検索
     */
    @Query("SELECT s FROM Song s WHERE s.genius_song_id = ?1")
    Optional<Song> findByGeniusSongId(Long geniusSongId);

    /**
     * Spotify Track IDで検索
     */
    @Query("SELECT s FROM Song s WHERE s.spotify_track_id = ?1")
    Optional<Song> findBySpotifyTrackId(String spotifyTrackId);

    /**
     * Spotify Track IDで存在チェック
     */
    @Query("SELECT CASE WHEN COUNT(s) > 0 THEN true ELSE false END FROM Song s WHERE s.spotify_track_id = :spotifyTrackId")
    boolean existsBySpotifyTrackId(@Param("spotifyTrackId") String spotifyTrackId);

    /**
     * アーティストIDでランダムな楽曲を1曲取得
     */
    @Query(value = "SELECT * FROM song WHERE aritst_id = ?1 ORDER BY RAND() LIMIT 1", nativeQuery = true)
    Optional<Song> findRandomByArtist(Long artistId);

    /**
     * ★ 新規追加 ★
     * アーティストIDでランダムな楽曲を指定件数取得
     * 
     * @param artistId アーティストID
     * @param limit 取得件数
     * @return ランダムに選ばれた楽曲のリスト
     */
    @Query(value = "SELECT * FROM song WHERE aritst_id = :artistId ORDER BY RAND() LIMIT :limit", 
           nativeQuery = true)
    List<Song> findRandomSongsByArtist(@Param("artistId") Long artistId, @Param("limit") int limit);

    /**
     * ★ 新規追加 ★
     * アーティストIDで楽曲数をカウント
     * 
     * @param artistId アーティストID
     * @return 楽曲数
     */
    @Query("SELECT COUNT(s) FROM Song s WHERE s.aritst_id = :artistId")
    long countByArtistId(@Param("artistId") Long artistId);

    /**
     * ジャンルでランダムな楽曲を取得
     * ※ 注意: Songテーブルにgenreカラムがある場合のみ使用可能
     *         Artist経由でジャンル検索する場合は別のアプローチが必要
     */
    @Query(value = "SELECT * FROM song WHERE genre = ?1 ORDER BY RAND() LIMIT 1", nativeQuery = true)
    Optional<Song> findRandomByGenre(String genre);

    /**
     * 完全ランダムで楽曲を取得
     */
    @Query(value = "SELECT * FROM song ORDER BY RAND() LIMIT 1", nativeQuery = true)
    Optional<Song> findRandom();
}