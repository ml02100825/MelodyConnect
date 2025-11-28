package com.example.api.repository;

import com.example.api.entity.LikeArtist;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

/**
 * LikeArtist Repository
 */
@Repository
public interface LikeArtistRepository extends JpaRepository<LikeArtist, Long> {

    /**
     * ユーザーIDでお気に入りアーティストのリストを取得
     */
    @Query("SELECT l FROM LikeArtist l WHERE l.user.id = ?1")
    List<LikeArtist> findByUserId(Long userId);

    /**
     * ユーザーIDとアーティストIDで検索
     */
    @Query("SELECT l FROM LikeArtist l WHERE l.user.id = ?1 AND l.artist.artistId = ?2")
    Optional<LikeArtist> findByUserIdAndArtistId(Long userId, Long artistId);
    @Query("SELECT CASE WHEN COUNT(l) > 0 THEN true ELSE false END " +
       "FROM LikeArtist l WHERE l.user.id = ?1 AND l.artist.artistId = ?2")
    Boolean  existsByUserIdAndArtistId(Long userId, Long artistId);

    /**
     * ユーザーのお気に入りアーティストからランダムに1つ取得
     */
    @Query(value = "SELECT * FROM like_artist WHERE user_id = ?1 ORDER BY RAND() LIMIT 1", nativeQuery = true)
    Optional<LikeArtist> findRandomByUserId(Long userId);
}
