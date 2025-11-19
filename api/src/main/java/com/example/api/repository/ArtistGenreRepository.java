package com.example.api.repository;

import com.example.api.entity.ArtistGenre;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

/**
 * ArtistGenre Repository
 */
@Repository
public interface ArtistGenreRepository extends JpaRepository<ArtistGenre, Long> {

    /**
     * アーティストIDとジャンルIDで検索
     */
    @Query("SELECT ag FROM ArtistGenre ag WHERE ag.artist.artistId = ?1 AND ag.genre.id = ?2")
    Optional<ArtistGenre> findByArtistIdAndGenreId(Integer artistId, Long genreId);

    /**
     * アーティストIDで検索
     */
    @Query("SELECT ag FROM ArtistGenre ag WHERE ag.artist.artistId = ?1")
    List<ArtistGenre> findByArtistId(Integer artistId);
}
