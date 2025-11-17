package com.example.api.repository;

import com.example.api.entity.question;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

/**
 * Question Repository
 */
@Repository
public interface QuestionRepository extends JpaRepository<question, Integer> {

    /**
     * 楽曲IDで問題を検索
     */
    List<question> findBySongId(Long songId);

    /**
     * アーティストIDで問題を検索
     */
    List<question> findByArtistId(Integer artistId);

    /**
     * 問題形式で検索
     */
    List<question> findByQuestionFormat(String questionFormat);

    /**
     * 楽曲IDと問題形式で検索
     */
    List<question> findBySongIdAndQuestionFormat(Long songId, String questionFormat);
}
