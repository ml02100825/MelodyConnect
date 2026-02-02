package com.example.api.repository;

import com.example.api.entity.EmailChangeToken;
import com.example.api.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.Optional;

/**
 * メールアドレス変更トークンリポジトリ
 */
@Repository
public interface EmailChangeTokenRepository extends JpaRepository<EmailChangeToken, Long> {

    /**
     * トークンでメールアドレス変更トークンを検索
     */
    Optional<EmailChangeToken> findByToken(String token);

    /**
     * 特定ユーザーのメールアドレス変更トークンを削除
     */
    void deleteByUser(User user);

    /**
     * 有効期限切れトークンを一括削除
     */
    @Modifying
    @Query("delete from EmailChangeToken t where t.expiryDate < ?1")
    void deleteAllExpiredSince(LocalDateTime now);
}
