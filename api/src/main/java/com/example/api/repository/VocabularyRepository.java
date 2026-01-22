package com.example.api.repository;

import com.example.api.entity.Vocabulary;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

/**
 * Vocabulary Repository
 */
@Repository
public interface VocabularyRepository extends JpaRepository<Vocabulary, Integer>, JpaSpecificationExecutor<Vocabulary> {

    /**
     * 単語で検索
     */
    Optional<Vocabulary> findByWord(String word);

    /**
     * 単語が既に存在するか確認
     */
    boolean existsByWord(String word);

    /**
     * base_formまたはtranslation_jaがnullのレコードを取得（バッチ処理用）
     */
    @Query("SELECT v FROM Vocabulary v WHERE v.base_form IS NULL OR v.translation_ja IS NULL ORDER BY v.vocab_id ASC LIMIT :limit")
    List<Vocabulary> findByBaseFormIsNullOrTranslationJaIsNull(@Param("limit") int limit);

    /**
     * base_formまたはtranslation_jaがnullのレコード数をカウント
     */
    @Query("SELECT COUNT(v) FROM Vocabulary v WHERE v.base_form IS NULL OR v.translation_ja IS NULL")
    long countByBaseFormIsNullOrTranslationJaIsNull();

    /**
     * ID順に指定件数を取得（強制更新用）
     */
    @Query("SELECT v FROM Vocabulary v ORDER BY v.vocab_id ASC LIMIT :limit")
    List<Vocabulary> findAllOrderByIdAsc(@Param("limit") int limit);

    /**
     * 原形（base_form）で検索
     */
    @Query("SELECT v FROM Vocabulary v WHERE v.base_form = :baseForm")
    Optional<Vocabulary> findByBaseForm(@Param("baseForm") String baseForm);

    /**
     * 原形（base_form）が存在するか確認
     */
    @Query("SELECT COUNT(v) > 0 FROM Vocabulary v WHERE v.base_form = :baseForm")
    boolean existsByBaseForm(@Param("baseForm") String baseForm);
}