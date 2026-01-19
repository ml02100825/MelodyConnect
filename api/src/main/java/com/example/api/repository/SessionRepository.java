package com.example.api.repository;

import com.example.api.entity.Session;
import com.example.api.entity.User;
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
     * ユーザーで有効なセッションを検索
     * @param user ユーザーエンティティ
     * @param now 現在時刻
     * @return 有効なセッションのリスト
     */
    @Query("SELECT s FROM Session s WHERE s.user = :user AND s.revokedFlag = false AND s.expiresAt > :now")
    List<Session> findValidSessionsByUser(@Param("user") User user, @Param("now") LocalDateTime now);


    /**
     * リフレッシュトークンハッシュで有効なセッションを検索
     * @param refreshHash リフレッシュトークンハッシュ
     * @param now 現在時刻
     * @return セッション（存在する場合）
     */
    @Query("SELECT s FROM Session s WHERE s.refreshHash = :refreshHash AND s.revokedFlag = false AND s.expiresAt > :now")
    Optional<Session> findValidSessionByRefreshHash(@Param("refreshHash") String refreshHash, @Param("now") LocalDateTime now);

    /**
     * ユーザーで全てのセッションを取得
     * @param user ユーザーエンティティ
     * @return セッションのリスト
     */
    List<Session> findByUser(User user);



    /**
     * ユーザーIDで最新のセッションを取得
     * @param user
     * @return 最新セッション
     */
    Optional<Session> findTopByUserOrderByCreatedAtDesc(User user);

    /**
     * clientTypeでセッションを検索
     * @param clientType クライアント種別
     * @return セッションのリスト
     */
    List<Session> findByClientType(String clientType);

    /**
     * 期限切れのセッションを削除
     * @param now 現在時刻
     */
    @Modifying
    @Query("DELETE FROM Session s WHERE s.expiresAt < :now")
    void deleteExpiredSessions(@Param("now") LocalDateTime now);

    /**
     * ユーザーの全セッションを無効化
     * @param user ユーザーエンティティ
     */
    @Modifying
    @Query("UPDATE Session s SET s.revokedFlag = true WHERE s.user = :user")
    void revokeAllUserSessions(@Param("user") User user);
}


