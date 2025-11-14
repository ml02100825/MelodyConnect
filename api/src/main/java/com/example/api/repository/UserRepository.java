package com.example.api.repository;

import com.example.api.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;

/**
 * ユーザーリポジトリインターフェース
 * ユーザーエンティティのデータベース操作を提供します
 */
@Repository
public interface UserRepository extends JpaRepository<User, Long> {

    /**
     * メールアドレスでユーザーを検索
     * @param email メールアドレス
     * @return ユーザー（存在する場合）
     */
    Optional<User> findByEmail(String email);

    /**
     * メールアドレスの存在確認
     * @param email メールアドレス
     * @return 存在する場合true
     */
    boolean existsByEmail(String email);
}
