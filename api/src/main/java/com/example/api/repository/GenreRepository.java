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
     * 
     * @param name ジャンル名
     * @return Genre（存在しない場合はOptional.empty()）
     */
    Optional<Genre> findByName(String name);

    /**
     * ジャンル名で存在チェック
     * 
     * @param name ジャンル名
     * @return 存在すればtrue
     */
    boolean existsByName(String name);
}