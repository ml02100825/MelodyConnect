package com.example.api.repository;

import com.example.api.entity.Friend;
import com.example.api.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

/**
 * フレンドリポジトリインターフェース
 * フレンドエンティティのデータベース操作を提供します
 */
@Repository
public interface FriendRepository extends JpaRepository<Friend, Long> {

    /**
     * 2人のユーザー間のフレンド関係を検索（ID順序を考慮） - エンティティ版
     * @param userLow ID小のユーザー
     * @param userHigh ID大のユーザー
     * @return フレンド関係（存在する場合）
     */
    Optional<Friend> findByUserLowAndUserHigh(User userLow, User userHigh);

    /**
     * 2人のユーザー間のフレンド関係を検索（ID順序を考慮） - ID版
     * userLow.id / userHigh.id を直接指定して検索したいとき用
     */
    Optional<Friend> findByUserLow_IdAndUserHigh_Id(Long userLowId, Long userHighId);

    /**
     * ユーザーのフレンド一覧を取得（friend_flag = true）
     * @param user ユーザー
     * @return フレンド一覧
     */
    @Query("SELECT f FROM Friend f WHERE (f.userLow = :user OR f.userHigh = :user) AND f.friendFlag = true")
    List<Friend> findFriendsByUser(@Param("user") User user);

    /**
     * ユーザーへのフレンド申請一覧を取得（friend_flag = false, 自分が申請者でない）
     * @param user ユーザー
     * @return フレンド申請一覧
     */
    @Query("SELECT f FROM Friend f WHERE (f.userLow = :user OR f.userHigh = :user) AND f.friendFlag = false AND f.requester != :user")
    List<Friend> findPendingRequestsForUser(@Param("user") User user);

    /**
     * ユーザーが送信したフレンド申請一覧を取得
     * @param user ユーザー
     * @return 送信した申請一覧
     */
    @Query("SELECT f FROM Friend f WHERE f.requester = :user AND f.friendFlag = false")
    List<Friend> findSentRequestsByUser(@Param("user") User user);

    /**
     * 2人のユーザー間に既存のフレンド関係があるか確認（エンティティ版）
     */
    boolean existsByUserLowAndUserHigh(User userLow, User userHigh);

    /**
     * 2人のユーザー間に既存のフレンド関係があるか確認（ID版）
     */
    boolean existsByUserLow_IdAndUserHigh_Id(Long userLowId, Long userHighId);
}
