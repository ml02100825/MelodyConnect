package com.example.api.repository;

import com.example.api.entity.Friend;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository; // 追加

import java.util.List;
import java.util.Set; // 追加

@Repository
public interface FriendRepository extends JpaRepository<Friend, Long> {

    // ==========================================
    //  既存のメソッド（そのまま残します）
    // ==========================================
    @Query(value = "SELECT CASE WHEN f.user_id_high = :userId THEN f.user_id_low ELSE f.user_id_high END " +
                   "FROM friend f " +
                   "WHERE (f.user_id_high = :userId OR f.user_id_low = :userId) " +
                   "AND ( (f.friend_flag IS NOT NULL AND f.friend_flag = 1) OR f.accepted_at IS NOT NULL )", nativeQuery = true)
    List<Long> findAcceptedFriendIdsByUserId(@Param("userId") Long userId);

    List<Friend> findByRequesterId(Long requesterId);


    // ==========================================
    //  ★ここから下を追加 (RankingService用)
    // ==========================================

    /**
     * ランキング判定用: 自分のフレンドのUser ID一覧をSetで取得
     * (JPQLを使用し、高速な検索のためにSetで返します)
     */
    @Query("SELECT CASE WHEN f.userLow.id = :myId THEN f.userHigh.id ELSE f.userLow.id END " +
           "FROM Friend f " +
           "WHERE (f.userLow.id = :myId OR f.userHigh.id = :myId) " +
           "AND f.friendFlag = true")
    Set<Long> findFriendUserIds(@Param("myId") Long myId);
}
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
     * 2人のユーザー間のフレンド関係を取得（JOIN版 - Hibernate互換）
     * @param userIdLow 小さい方のユーザーID
     * @param userIdHigh 大きい方のユーザーID
     * @return フレンド関係（存在する場合）
     */
    @Query("SELECT f FROM Friend f " +
           "JOIN f.userLow ul " +
           "JOIN f.userHigh uh " +
           "WHERE ul.id = :userIdLow AND uh.id = :userIdHigh")
    Optional<Friend> findByUserPair(@Param("userIdLow") Long userIdLow, @Param("userIdHigh") Long userIdHigh);

    /**
     * ユーザーのフレンド一覧を取得（friend_flag = true）- エンティティ版
     * @param user ユーザー
     * @return フレンド一覧
     */
    @Query("SELECT f FROM Friend f WHERE (f.userLow = :user OR f.userHigh = :user) AND f.friendFlag = true")
    List<Friend> findFriendsByUser(@Param("user") User user);

    /**
     * ユーザーのフレンド一覧を取得（friend_flag = true）- ID版（招待状態も取得）
     * @param userId ユーザーID
     * @return フレンド一覧
     */
    @Query("SELECT f FROM Friend f " +
           "LEFT JOIN FETCH f.userLow " +
           "LEFT JOIN FETCH f.userHigh " +
           "LEFT JOIN FETCH f.roomInviter " +
           "WHERE (f.userLow.id = :userId OR f.userHigh.id = :userId) AND f.friendFlag = true")
    List<Friend> findFriendsByUserId(@Param("userId") Long userId);

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

    /**
     * ルーム招待一覧を取得（inviteFlag = true かつ inviteRoomId が設定されているもの）
     * @param userId 招待を受けたユーザーID
     * @return ルーム招待のリスト
     */
    @Query("SELECT f FROM Friend f " +
           "LEFT JOIN FETCH f.userLow " +
           "LEFT JOIN FETCH f.userHigh " +
           "LEFT JOIN FETCH f.roomInviter " +
           "WHERE ((f.userLow.id = :userId OR f.userHigh.id = :userId) " +
           "AND f.friendFlag = true AND f.inviteFlag = true AND f.inviteRoomId IS NOT NULL " +
           "AND f.roomInviter.id != :userId)")
    List<Friend> findRoomInvitationsByUserId(@Param("userId") Long userId);

    /**
     * 特定のルームへの招待を取得
     * @param roomId ルームID
     * @param inviteeId 招待を受けたユーザーID
     * @return 招待（存在する場合）
     */
    @Query("SELECT f FROM Friend f " +
           "WHERE ((f.userLow.id = :inviteeId OR f.userHigh.id = :inviteeId) " +
           "AND f.inviteRoomId = :roomId AND f.inviteFlag = true)")
    Optional<Friend> findRoomInvitation(@Param("roomId") Long roomId, @Param("inviteeId") Long inviteeId);

    /**
     * 特定のルームへの全招待を取得
     * @param roomId ルームID
     * @return 招待のリスト
     */
    @Query("SELECT f FROM Friend f " +
           "LEFT JOIN FETCH f.userLow " +
           "LEFT JOIN FETCH f.userHigh " +
           "LEFT JOIN FETCH f.roomInviter " +
           "WHERE f.inviteRoomId = :roomId AND f.inviteFlag = true")
    List<Friend> findAllRoomInvitationsByRoomId(@Param("roomId") Long roomId);

    /**
     * 2人のユーザーがフレンドかどうかを確認
     * @param userId1 ユーザーID1
     * @param userId2 ユーザーID2
     * @return フレンドの場合true
     */
    @Query("SELECT CASE WHEN COUNT(f) > 0 THEN true ELSE false END FROM Friend f " +
           "WHERE ((f.userLow.id = :userId1 AND f.userHigh.id = :userId2) " +
           "OR (f.userLow.id = :userId2 AND f.userHigh.id = :userId1)) AND f.friendFlag = true")
    boolean areFriends(@Param("userId1") Long userId1, @Param("userId2") Long userId2);
}
