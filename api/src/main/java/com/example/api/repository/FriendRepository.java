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
 * Friendエンティティのデータベース操作を提供します
 */
@Repository
public interface FriendRepository extends JpaRepository<Friend, Long> {

    /**
     * ユーザーの確定済みフレンド一覧を取得
     * @param userId ユーザーID
     * @return フレンド関係のリスト
     */
    @Query("SELECT f FROM Friend f " +
           "LEFT JOIN FETCH f.userLow " +
           "LEFT JOIN FETCH f.userHigh " +
           "WHERE (f.userLow.id = :userId OR f.userHigh.id = :userId) AND f.friendFlag = true")
    List<Friend> findFriendsByUserId(@Param("userId") Long userId);

    /**
     * 2人のユーザー間のフレンド関係を取得
     * @param userIdLow 小さい方のユーザーID
     * @param userIdHigh 大きい方のユーザーID
     * @return フレンド関係（存在する場合）
     */
    @Query("SELECT f FROM Friend f WHERE f.userLow.id = :userIdLow AND f.userHigh.id = :userIdHigh")
    Optional<Friend> findByUserPair(@Param("userIdLow") Long userIdLow, @Param("userIdHigh") Long userIdHigh);

    /**
     * ユーザーへのフレンド申請を取得（未承認）
     * @param userId ユーザーID
     * @return フレンド申請のリスト
     */
    @Query("SELECT f FROM Friend f " +
           "LEFT JOIN FETCH f.userLow " +
           "LEFT JOIN FETCH f.userHigh " +
           "LEFT JOIN FETCH f.requester " +
           "WHERE ((f.userLow.id = :userId OR f.userHigh.id = :userId) " +
           "AND f.friendFlag = false AND f.requester.id != :userId)")
    List<Friend> findPendingRequestsToUser(@Param("userId") Long userId);

    /**
     * ユーザーからのフレンド申請を取得（未承認）
     * @param userId ユーザーID
     * @return フレンド申請のリスト
     */
    @Query("SELECT f FROM Friend f " +
           "LEFT JOIN FETCH f.userLow " +
           "LEFT JOIN FETCH f.userHigh " +
           "WHERE f.requester.id = :userId AND f.friendFlag = false")
    List<Friend> findPendingRequestsFromUser(@Param("userId") Long userId);

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
