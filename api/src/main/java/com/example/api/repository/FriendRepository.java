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