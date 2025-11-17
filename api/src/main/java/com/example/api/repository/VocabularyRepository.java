package com.example.api.repository;

import com.example.api.entity.vocabulary;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

/**
 * Vocabulary Repository
 */
@Repository
public interface VocabularyRepository extends JpaRepository<vocabulary, Integer> {

    /**
     * 単語で検索
     */
    Optional<vocabulary> findByWord(String word);

    /**
     * 単語が既に存在するか確認
     */
    boolean existsByWord(String word);
}
