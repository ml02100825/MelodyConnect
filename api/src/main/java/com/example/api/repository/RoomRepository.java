package com.example.api.repository;

import com.example.api.entity.Room;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

/**
 * ルームリポジトリインターフェース
 * Roomエンティティのデータベース操作を提供します
 */
@Repository
public interface RoomRepository extends JpaRepository<Room, Long> {

    /**
     * ホストIDで部屋を検索（アクティブな部屋のみ）
     * @param hostId ホストのユーザーID
     * @return アクティブな部屋のリスト
     */
    @Query("SELECT r FROM Room r WHERE r.host_id = :hostId AND r.status NOT IN ('CANCELED', 'FINISHED')")
    List<Room> findActiveByHostId(@Param("hostId") Long hostId);

    /**
     * ゲストIDで部屋を検索（アクティブな部屋のみ）
     * @param guestId ゲストのユーザーID
     * @return アクティブな部屋のリスト
     */
    @Query("SELECT r FROM Room r WHERE r.guest_id = :guestId AND r.status NOT IN ('CANCELED', 'FINISHED')")
    List<Room> findActiveByGuestId(@Param("guestId") Long guestId);

    /**
     * ホストIDで待機中の部屋を検索
     * @param hostId ホストのユーザーID
     * @return 待機中の部屋（存在する場合）
     */
    @Query("SELECT r FROM Room r WHERE r.host_id = :hostId AND r.status = 'WAITING'")
    Optional<Room> findWaitingByHostId(@Param("hostId") Long hostId);

    /**
     * ユーザーが現在参加中の部屋を検索（ホストまたはゲストとして）
     * @param userId ユーザーID
     * @return 参加中の部屋のリスト
     */
    @Query("SELECT r FROM Room r WHERE (r.host_id = :userId OR r.guest_id = :userId) AND r.status IN ('WAITING', 'READY', 'PLAYING')")
    List<Room> findActiveByUserId(@Param("userId") Long userId);

    /**
     * ユーザーが現在対戦中の部屋を検索
     * @param userId ユーザーID
     * @return 対戦中の部屋（存在する場合）
     */
    @Query("SELECT r FROM Room r WHERE (r.host_id = :userId OR r.guest_id = :userId) AND r.status = 'PLAYING'")
    Optional<Room> findPlayingByUserId(@Param("userId") Long userId);

    /**
     * ステータスで部屋を検索
     * @param status ルームステータス
     * @return 該当する部屋のリスト
     */
    List<Room> findByStatus(Room.Status status);

    /**
     * ユーザーがホストまたはゲストとして存在するかチェック
     * @param userId ユーザーID
     * @return 存在する場合true
     */
    @Query("SELECT CASE WHEN COUNT(r) > 0 THEN true ELSE false END FROM Room r WHERE (r.host_id = :userId OR r.guest_id = :userId) AND r.status IN ('WAITING', 'READY', 'PLAYING')")
    boolean existsActiveRoomByUserId(@Param("userId") Long userId);
}
