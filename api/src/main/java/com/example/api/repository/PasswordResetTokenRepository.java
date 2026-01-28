package com.example.api.repository;

import com.example.api.entity.PasswordResetToken;
import com.example.api.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.Optional;

@Repository
public interface PasswordResetTokenRepository extends JpaRepository<PasswordResetToken, Long> {
    Optional<PasswordResetToken> findByToken(String token);
    
    // 特定ユーザーの古いトークンを削除（再発行時用）
    void deleteByUser(User user);

    // 期限切れを一括削除
    @Modifying
    @Query("delete from PasswordResetToken t where t.expiryDate < ?1")
    void deleteAllExpiredSince(LocalDateTime now);
}
