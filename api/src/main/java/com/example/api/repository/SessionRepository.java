package com.example.api.repository;

import com.example.api.entity.Session;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

/**
 * セッションリポジトリインターフェース
 * セッションエンティティのデータベース操作を提供します
 */
@Repository
public interface SessionRepository extends JpaRepository<Session, Long> {

    /**
     * ユーザーIDで有効なセッションを検索
     * @param userId ユーザーID
     * @return 有効なセッションのリスト
     */
    @Query("SELECT s FROM Session s WHERE s.userId = :userId AND s.revokedFlag = false AND s.expiresAt > :now")
    List<Session> findValidSessionsByUserId(@Param("userId") Long userId, @Param("now") LocalDateTime now);

    /**
     * リフレッシュトークンハッシュで有効なセッションを検索
     * @param refreshHash リフレッシュトークンハッシュ
     * @return セッション（存在する場合）
     */
    @Query("SELECT s FROM Session s WHERE s.refreshHash = :refreshHash AND s.revokedFlag = false AND s.expiresAt > :now")
    Optional<Session> findValidSessionByRefreshHash(@Param("refreshHash") String refreshHash, @Param("now") LocalDateTime now);

    /**
     * ユーザーIDで全てのセッションを取得
     * @param userId ユーザーID
     * @return セッションのリスト
     */
    List<Session> findByUserId(Long userId);

    /**
     * 期限切れのセッションを削除
     * @param now 現在時刻
     */
    @Modifying
    @Query("DELETE FROM Session s WHERE s.expiresAt < :now")
    void deleteExpiredSessions(@Param("now") LocalDateTime now);

    /**
     * ユーザーの全セッションを無効化
     * @param userId ユーザーID
     */
    @Modifying
    @Query("UPDATE Session s SET s.revokedFlag = true WHERE s.userId = :userId")
    void revokeAllUserSessions(@Param("userId") Long userId);
}
