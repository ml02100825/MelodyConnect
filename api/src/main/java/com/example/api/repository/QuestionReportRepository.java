package com.example.api.repository;

import com.example.api.entity.QuestionReport;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

/**
 * QuestionReport Repository
 */
@Repository
public interface QuestionReportRepository extends JpaRepository<QuestionReport, Long> {

    /**
     * ユーザーIDと問題IDで通報を検索
     * 1ユーザー1問題につき1回まで制限を確認するために使用
     */
    Optional<QuestionReport> findByUserIdAndQuestionId(Long userId, Long questionId);

    /**
     * ユーザーIDと問題IDで通報が存在するかチェック
     */
    boolean existsByUserIdAndQuestionId(Long userId, Long questionId);
}
