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
     * ユーザー名でユーザーを検索
     * @param username ユーザー名
     * @return ユーザー（存在する場合）
     */
    Optional<User> findByUsername(String username);

    /**
     * メールアドレスでユーザーを検索
     * @param mailaddress メールアドレス
     * @return ユーザー（存在する場合）
     */
    Optional<User> findByMailaddress(String mailaddress);

    /**
     * ユーザーUUIDでユーザーを検索
     * @param userUuid ユーザーUUID
     * @return ユーザー（存在する場合）
     */
    Optional<User> findByUserUuid(String userUuid);

    /**
     * メールアドレスの存在確認
     * @param mailaddress メールアドレス
     * @return 存在する場合true
     */
    boolean existsByMailaddress(String mailaddress);

    /**
     * ユーザー名の存在確認
     * @param username ユーザー名
     * @return 存在する場合true
     */
    boolean existsByUsername(String username);
}
