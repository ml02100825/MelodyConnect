package com.example.api.repository;

import com.example.api.entity.Artist;
import com.example.api.entity.Question;
import com.example.api.entity.Song;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;

/**
 * Question Repository
 */
@Repository
public interface QuestionRepository extends JpaRepository<Question, Integer> {

    /**
     * 楽曲で問題を検索
     */
    List<Question> findBySong(Song song);

    /**
     * アーティストで問題を検索
     */
    List<Question> findByArtist(Artist artist);

    /**
     * 問題形式で検索
     */
    List<Question> findByQuestionFormat(com.example.api.enums.QuestionFormat questionFormat);

    /**
     * 楽曲と問題形式で検索
     */
    List<Question> findBySongAndQuestionFormat(Song song, com.example.api.enums.QuestionFormat questionFormat);

    /**
     * 楽曲IDで問題数をカウント
     */
    @Query("SELECT COUNT(q) FROM Question q WHERE q.song.song_id = ?1")
    long countBySongId(Long songId);

    /**
     * 楽曲IDで問題を検索
     */
    @Query("SELECT q FROM Question q WHERE q.song.song_id = ?1")
    List<Question> findBySongId(Long songId);

    /**
     * 楽曲IDと問題形式で検索
     */
    @Query("SELECT q FROM Question q WHERE q.song.song_id = ?1 AND q.questionFormat = ?2")
    List<Question> findBySongIdAndQuestionFormat(Long songId, com.example.api.enums.QuestionFormat questionFormat);

    /**
     * 言語で問題を検索
     */
    List<Question> findByLanguage(String language);

    /**
     * 言語と問題形式で検索
     */
    List<Question> findByLanguageAndQuestionFormat(String language, com.example.api.enums.QuestionFormat questionFormat);
}
