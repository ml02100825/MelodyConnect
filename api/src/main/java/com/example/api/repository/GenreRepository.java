package com.example.api.repository;

import com.example.api.entity.Genre;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

/**
 * Genre Repository
 */
@Repository
public interface GenreRepository extends JpaRepository<Genre, Long> {

    /**
     * ジャンル名で検索
     */
    Optional<Genre> findByName(String name);
}
