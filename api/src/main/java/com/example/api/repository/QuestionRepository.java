package com.example.api.repository;

import com.example.api.entity.Artist;
import com.example.api.entity.question;
import com.example.api.entity.song;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

/**
 * Question Repository
 */
@Repository
public interface QuestionRepository extends JpaRepository<question, Integer> {

    /**
     * 楽曲で問題を検索
     */
    List<question> findBySong(song song);

    /**
     * アーティストで問題を検索
     */
    List<question> findByArtist(Artist artist);

    /**
     * 問題形式で検索
     */
    List<question> findByQuestionFormat(String questionFormat);

    /**
     * 楽曲と問題形式で検索
     */
    List<question> findBySongAndQuestionFormat(song song, String questionFormat);
}
