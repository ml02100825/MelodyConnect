package com.example.api.repository;

import com.example.api.entity.Genre;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface GenreRepository extends JpaRepository<Genre, Long>, JpaSpecificationExecutor<Genre> {

    Optional<Genre> findByName(String name);
    
    // ... 他のメソッド ...

    /**
     * ★このSQLが「0件を非表示にする」正体です
     */
    @Query(value = """
        SELECT DISTINCT g.* FROM genre g 
        INNER JOIN artist_genre ag ON g.genre_id = ag.genre_id 
        WHERE g.is_active = 1 
          AND g.is_deleted = 0
    """, nativeQuery = true)
    List<Genre> findGenresWithArtists();
}