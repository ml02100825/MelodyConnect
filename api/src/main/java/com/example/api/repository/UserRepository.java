package com.example.api.repository;

import com.example.api.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.time.LocalDateTime;
import java.util.Optional;

/**
 * ユーザーリポジトリインターフェース
 * ユーザーエンティティのデータベース操作を提供します
 */
@Repository
public interface UserRepository extends JpaRepository<User, Long>, JpaSpecificationExecutor<User> {

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

    /**
     * ユーザーUUIDの存在確認
     * @param userUuid ユーザーUUID
     * @return 存在する場合true
     */
    boolean existsByUserUuid(String userUuid);

    /**
     * ライフを1消費（原子的操作）
     * life >= 1 の場合のみ消費し、二重消費やマイナスを防止
     * @param userId ユーザーID
     * @param newRecoveredAt 新しい回復基準時刻
     * @return 更新された行数（1=成功、0=life不足）
     */
    @Modifying
    @Query("UPDATE User u SET u.life = u.life - 1, u.lifeLastRecoveredAt = :newRecoveredAt " +
           "WHERE u.id = :userId AND u.life >= 1 AND u.deleteFlag = false")
    int consumeLife(@Param("userId") Long userId, @Param("newRecoveredAt") LocalDateTime newRecoveredAt);

    /**
     * ライフと回復時刻を更新（回復計算結果の反映用）
     * @param userId ユーザーID
     * @param newLife 新しいライフ値
     * @param newRecoveredAt 新しい回復基準時刻
     * @return 更新された行数
     */
    @Modifying
    @Query("UPDATE User u SET u.life = :newLife, u.lifeLastRecoveredAt = :newRecoveredAt " +
           "WHERE u.id = :userId AND u.deleteFlag = false")
    int updateLifeAndRecoveredAt(@Param("userId") Long userId,
                                  @Param("newLife") int newLife,
                                  @Param("newRecoveredAt") LocalDateTime newRecoveredAt);
}
