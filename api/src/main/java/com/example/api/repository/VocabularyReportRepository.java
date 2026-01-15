package com.example.api.repository;

import com.example.api.entity.VocabularyReport;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

/**
 * VocabularyReport Repository
 */
@Repository
public interface VocabularyReportRepository extends JpaRepository<VocabularyReport, Long> {

    /**
     * ユーザーIDと単語IDで通報を検索
     * 1ユーザー1単語につき1回まで制限を確認するために使用
     */
    Optional<VocabularyReport> findByUserIdAndVocabularyId(Long userId, Long vocabularyId);

    /**
     * ユーザーIDと単語IDで通報が存在するかチェック
     */
    boolean existsByUserIdAndVocabularyId(Long userId, Long vocabularyId);
}
