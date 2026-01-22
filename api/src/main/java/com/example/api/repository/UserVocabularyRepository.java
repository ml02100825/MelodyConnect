package com.example.api.repository;

import com.example.api.entity.User;
import com.example.api.entity.UserVocabulary;
import com.example.api.entity.Vocabulary;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

/**
 * UserVocabulary Repository
 * ユーザーの学習済み単語を管理
 */
@Repository
public interface UserVocabularyRepository extends JpaRepository<UserVocabulary, Integer> {

    /**
     * ユーザーIDで学習済み単語を取得（Vocabularyも一緒にフェッチ）
     */
    @Query("SELECT uv FROM UserVocabulary uv JOIN FETCH uv.vocabulary WHERE uv.user.id = :userId")
    List<UserVocabulary> findByUserIdWithVocabulary(@Param("userId") Long userId);

    /**
     * ユーザーIDで学習済み単語を取得
     */
    @Query("SELECT uv FROM UserVocabulary uv WHERE uv.user.id = :userId")
    List<UserVocabulary> findByUserId(@Param("userId") Long userId);

    /**
     * ユーザーIDとVocabulary IDで検索
     */
    @Query("SELECT uv FROM UserVocabulary uv WHERE uv.user.id = :userId AND uv.vocabulary.vocabId = :vocabId")
    Optional<UserVocabulary> findByUserIdAndVocabId(@Param("userId") Long userId, @Param("vocabId") Integer vocabId);

    /**
     * ユーザーとVocabularyで検索
     */
    Optional<UserVocabulary> findByUserAndVocabulary(User user, Vocabulary vocabulary);

    /**
     * ユーザーIDとVocabulary IDの組み合わせが存在するかチェック
     */
    @Query("SELECT CASE WHEN COUNT(uv) > 0 THEN true ELSE false END FROM UserVocabulary uv WHERE uv.user.id = :userId AND uv.vocabulary.vocabId = :vocabId")
    boolean existsByUserIdAndVocabId(@Param("userId") Long userId, @Param("vocabId") Integer vocabId);

    /**
     * ユーザーのお気に入り単語を取得（Vocabularyも一緒にフェッチ）
     */
    @Query("SELECT uv FROM UserVocabulary uv JOIN FETCH uv.vocabulary WHERE uv.user.id = :userId AND uv.favoriteFlag = true")
    List<UserVocabulary> findFavoritesByUserId(@Param("userId") Long userId);

    /**
     * ユーザーの学習済み単語を取得（Vocabularyも一緒にフェッチ）
     */
    @Query("SELECT uv FROM UserVocabulary uv JOIN FETCH uv.vocabulary WHERE uv.user.id = :userId AND uv.learnedWordFlag = true")
    List<UserVocabulary> findLearnedByUserId(@Param("userId") Long userId);

    /**
     * ユーザーの単語数をカウント
     */
    @Query("SELECT COUNT(uv) FROM UserVocabulary uv WHERE uv.user.id = :userId")
    long countByUserId(@Param("userId") Long userId);
}
