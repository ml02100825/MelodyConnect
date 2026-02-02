package com.example.api.repository;

import com.example.api.entity.Artist;
import com.example.api.entity.ArtistGenre;
import com.example.api.entity.Genre;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

/**
 * ArtistGenre Repository
 * アーティストとジャンルの多対多関係を管理
 */
@Repository
public interface ArtistGenreRepository extends JpaRepository<ArtistGenre, Long> {

    /**
     * ジャンルIDに紐づくアーティストをランダムに1件取得
     * 
     * @param genreId ジャンルID
     * @return ランダムに選ばれたArtistGenre
     */
    @Query(value = "SELECT * FROM artist_genre WHERE genre_id = :genreId ORDER BY RAND() LIMIT 1", 
           nativeQuery = true)
    Optional<ArtistGenre> findRandomByGenreId(@Param("genreId") Long genreId);

    /**
     * ジャンルIDに紐づく全アーティストを取得
     * 
     * @param genreId ジャンルID
     * @return ArtistGenreのリスト
     */
    List<ArtistGenre> findByGenreId(Long genreId);

    /**
     * アーティストIDに紐づく全ジャンルを取得
     * 
     * @param artistId アーティストID
     * @return ArtistGenreのリスト
     */
    List<ArtistGenre> findByArtistArtistId(Integer artistId);

    /**
     * アーティストとジャンルの組み合わせが存在するかチェック
     * 
     * @param artist アーティスト
     * @param genre ジャンル
     * @return 存在すればtrue
     */
    boolean existsByArtistAndGenre(Artist artist, Genre genre);

    /**
     * ジャンル名でアーティストをランダムに1件取得（JOIN版）
     * Genreテーブルと結合してジャンル名で直接検索
     * 
     * @param genreName ジャンル名
     * @return ランダムに選ばれたArtistGenre
     */
    @Query(value = "SELECT ag.* FROM artist_genre ag " +
                   "INNER JOIN genre g ON ag.genre_id = g.genre_id " +
                   "WHERE g.name = :genreName " +
                   "ORDER BY RAND() LIMIT 1", 
           nativeQuery = true)
    Optional<ArtistGenre> findRandomByGenreName(@Param("genreName") String genreName);

    /**
     * ジャンル名に部分一致するアーティストをランダムに1件取得
     * Spotifyのジャンル名は細かく分かれているため、部分一致検索も用意
     * 例: "pop" で "j-pop", "k-pop", "synth-pop" なども対象にできる
     * 
     * @param genrePattern ジャンル名のパターン（LIKE検索用）
     * @return ランダムに選ばれたArtistGenre
     */
    @Query(value = "SELECT ag.* FROM artist_genre ag " +
                   "INNER JOIN genre g ON ag.genre_id = g.genre_id " +
                   "WHERE g.name LIKE :genrePattern " +
                   "ORDER BY RAND() LIMIT 1", 
           nativeQuery = true)
    Optional<ArtistGenre> findRandomByGenreNameLike(@Param("genrePattern") String genrePattern);

    /**
     * アーティストIDに紐づくジャンル名を1件取得
     */
    @Query(value = "SELECT g.name FROM artist_genre ag " +
                   "INNER JOIN genre g ON ag.genre_id = g.genre_id " +
                   "WHERE ag.artist_id = :artistId " +
                   "ORDER BY ag.artist_genre_id ASC LIMIT 1",
           nativeQuery = true)
    Optional<String> findFirstGenreNameByArtistId(@Param("artistId") Long artistId);

    /**
     * ジャンル名に紐づくアーティストIDを取得
     */
    @Query(value = "SELECT DISTINCT ag.artist_id FROM artist_genre ag " +
                   "INNER JOIN genre g ON ag.genre_id = g.genre_id " +
                   "WHERE g.name = :genreName",
           nativeQuery = true)
    List<Long> findArtistIdsByGenreName(@Param("genreName") String genreName);
}
