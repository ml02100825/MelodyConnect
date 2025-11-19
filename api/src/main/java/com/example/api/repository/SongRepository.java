package com.example.api.repository;

import com.example.api.entity.Song;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

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
     * アーティストIDでランダムな楽曲を取得
     */
    @Query(value = "SELECT * FROM song WHERE aritst_id = ?1 ORDER BY RAND() LIMIT 1", nativeQuery = true)
    Optional<Song> findRandomByArtist(Long artistId);

    /**
     * ジャンルでランダムな楽曲を取得
     */
    @Query(value = "SELECT * FROM song WHERE genre = ?1 ORDER BY RAND() LIMIT 1", nativeQuery = true)
    Optional<Song> findRandomByGenre(String genre);

    /**
     * 完全ランダムで楽曲を取得
     */
    @Query(value = "SELECT * FROM song ORDER BY RAND() LIMIT 1", nativeQuery = true)
    Optional<Song> findRandom();
}
