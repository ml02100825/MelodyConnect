package com.example.api.repository;

import com.example.api.entity.Vocabulary;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

/**
 * Vocabulary Repository
 */
@Repository
public interface VocabularyRepository extends JpaRepository<Vocabulary, Integer> {

    /**
     * 単語で検索
     */
    Optional<Vocabulary> findByWord(String word);

    /**
     * 単語が既に存在するか確認
     */
    boolean existsByWord(String word);
}
