package com.example.api.repository;

import com.example.api.entity.Artist;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

/**
 * Artist Repository
 */
@Repository
public interface ArtistRepository extends JpaRepository<Artist, Integer> {

    /**
     * アーティスト名で検索
     */
    Optional<Artist> findByArtistName(String artistName);

    /**
     * アーティストAPI IDで検索
     */
    Optional<Artist> findByArtistApiId(String artistApiId);
}
