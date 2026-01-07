package com.example.api.service;

import com.example.api.entity.Friend;
import com.example.api.entity.Room;
import com.example.api.entity.User;
import com.example.api.repository.FriendRepository;
import com.example.api.repository.RoomRepository;
import com.example.api.repository.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

/**
 * ルーム管理サービス
 * ルームマッチの部屋作成・招待・参加・退出を管理します
 */
@Service
public class RoomService {

    private static final Logger logger = LoggerFactory.getLogger(RoomService.class);

    private final RoomRepository roomRepository;
    private final FriendRepository friendRepository;
    private final UserRepository userRepository;
    private final MatchingQueueService matchingQueueService;
    private final BattleStateService battleStateService;

    public RoomService(RoomRepository roomRepository,
                       FriendRepository friendRepository,
                       UserRepository userRepository,
                       MatchingQueueService matchingQueueService,
                       BattleStateService battleStateService) {
        this.roomRepository = roomRepository;
        this.friendRepository = friendRepository;
        this.userRepository = userRepository;
        this.matchingQueueService = matchingQueueService;
        this.battleStateService = battleStateService;
    }

    /**
     * 部屋を作成（既存のアクティブな部屋がある場合はそれを返す）
     * @param hostId ホストのユーザーID
     * @param matchType 先取数（5/7/9）
     * @param language 言語
     * @param problemType 問題タイプ
     * @param questionFormat 問題形式
     * @return 作成された部屋または既存のアクティブな部屋
     */
    @Transactional
    public Room createRoom(Long hostId, Integer matchType, String language,
                          String problemType, String questionFormat) {
        // 既存のアクティブな部屋があるかチェック
        List<Room> existingRooms = roomRepository.findActiveByUserId(hostId);
        if (!existingRooms.isEmpty()) {
            // 既存の部屋を返す（ホストとして作成した部屋を優先）
            Room existingRoom = existingRooms.stream()
                    .filter(r -> r.getHost_id().equals(hostId))
                    .findFirst()
                    .orElse(existingRooms.get(0));
            logger.info("既存のアクティブな部屋に再接続: roomId={}, hostId={}", existingRoom.getRoom_id(), hostId);
            return existingRoom;
        }

        // ランクマッチ待機中かチェック
        if (matchingQueueService.isInQueue(hostId)) {
            throw new IllegalStateException("ランクマッチ待機中は部屋を作成できません");
        }

        Room room = new Room();
        room.setHost_id(hostId);
        room.setStatus(Room.Status.WAITING);
        room.setMatch_type(matchType);
        room.setSelected_language(language);
        room.setProblem_type(problemType);
        room.setQuestion_format(questionFormat);
        room.setHost_ready(false);
        room.setGuest_ready(false);

        Room savedRoom = roomRepository.save(room);
        logger.info("部屋を作成しました: roomId={}, hostId={}", savedRoom.getRoom_id(), hostId);
        return savedRoom;
    }

    /**
     * ユーザーのアクティブな部屋を取得
     * @param userId ユーザーID
     * @return アクティブな部屋（存在する場合）
     */
    public Optional<Room> getActiveRoom(Long userId) {
        List<Room> rooms = roomRepository.findActiveByUserId(userId);
        if (rooms.isEmpty()) {
            return Optional.empty();
        }
        // ホストとして作成した部屋を優先
        return rooms.stream()
                .filter(r -> r.getHost_id().equals(userId))
                .findFirst()
                .or(() -> Optional.of(rooms.get(0)));
    }

    /**
     * 部屋情報を取得
     * @param roomId ルームID
     * @return 部屋情報
     */
    public Optional<Room> getRoom(Long roomId) {
        return roomRepository.findById(roomId);
    }

    /**
     * フレンドを招待
     * @param roomId ルームID
     * @param hostId ホストのユーザーID（検証用）
     * @param friendId 招待するフレンドのユーザーID
     * @return 招待成功時true
     */
    @Transactional
    public InviteResult inviteFriend(Long roomId, Long hostId, Long friendId) {
        // 部屋の存在確認
        Room room = roomRepository.findById(roomId)
                .orElseThrow(() -> new IllegalArgumentException("部屋が存在しません"));

        // ホストの確認
        if (!room.getHost_id().equals(hostId)) {
            throw new IllegalArgumentException("この部屋のホストではありません");
        }

        // 部屋のステータス確認
        if (room.getStatus() != Room.Status.WAITING) {
            throw new IllegalStateException("この部屋は招待を受け付けていません");
        }

        // 自分自身への招待チェック
        if (hostId.equals(friendId)) {
            throw new IllegalArgumentException("自分自身を招待することはできません");
        }

        // フレンド関係の確認
        if (!friendRepository.areFriends(hostId, friendId)) {
            throw new IllegalArgumentException("フレンドではないユーザーは招待できません");
        }

        // ユーザーの取得
        User host = userRepository.findById(hostId)
                .orElseThrow(() -> new IllegalArgumentException("ホストユーザーが存在しません"));
        User friend = userRepository.findById(friendId)
                .orElseThrow(() -> new IllegalArgumentException("招待先ユーザーが存在しません"));

        // フレンド関係を取得
        Long lowId = Math.min(hostId, friendId);
        Long highId = Math.max(hostId, friendId);
        Friend friendship = friendRepository.findByUserPair(lowId, highId)
                .orElseThrow(() -> new IllegalArgumentException("フレンド関係が存在しません"));

        // 既に招待済みかチェック
        if (friendship.getInviteFlag() && friendship.getInviteRoomId() != null
                && friendship.getInviteRoomId().equals(roomId)) {
            return new InviteResult(true, false, "既に招待済みです");
        }

        // 招待情報を設定
        friendship.setInviteFlag(true);
        friendship.setInviteRoomId(roomId);
        friendship.setInviteSentAt(LocalDateTime.now());
        friendship.setRoomInviter(host);
        friendRepository.save(friendship);

        // 招待対象がランクマッチ中・対戦中かチェック
        boolean canReceiveNow = canReceiveInvitation(friendId);

        logger.info("フレンドを招待しました: roomId={}, hostId={}, friendId={}, canReceiveNow={}",
                roomId, hostId, friendId, canReceiveNow);

        return new InviteResult(true, canReceiveNow, canReceiveNow ? "招待を送信しました" : "招待を送信しました（相手はバトル中です）");
    }

    /**
     * ユーザーが招待を受信できる状態かチェック
     * @param userId ユーザーID
     * @return 受信可能な場合true
     */
    public boolean canReceiveInvitation(Long userId) {
        // ランクマッチ待機中かチェック
        if (matchingQueueService.isInQueue(userId)) {
            return false;
        }
        // 対戦中かチェック
        Optional<Room> playingRoom = roomRepository.findPlayingByUserId(userId);
        return playingRoom.isEmpty();
    }

    /**
     * 招待一覧を取得
     * @param userId ユーザーID
     * @return 招待のリスト
     */
    public List<Friend> getPendingInvitations(Long userId) {
        return friendRepository.findRoomInvitationsByUserId(userId);
    }

    /**
     * 招待を受理して部屋に参加
     * @param roomId ルームID
     * @param guestId ゲストのユーザーID
     * @return 参加した部屋
     */
    @Transactional
    public Room acceptInvitation(Long roomId, Long guestId) {
        // 部屋の存在確認
        Room room = roomRepository.findById(roomId)
                .orElseThrow(() -> new IllegalArgumentException("部屋が存在しません"));

        // 部屋のステータス確認
        if (room.getStatus() != Room.Status.WAITING) {
            throw new IllegalStateException("この部屋には参加できません");
        }

        // 既に他のゲストがいるかチェック
        if (room.getGuest_id() != null) {
            throw new IllegalStateException("既に他のプレイヤーが参加しています");
        }

        // 招待の存在確認
        Long hostId = room.getHost_id();
        Long lowId = Math.min(hostId, guestId);
        Long highId = Math.max(hostId, guestId);
        Friend friendship = friendRepository.findByUserPair(lowId, highId)
                .orElseThrow(() -> new IllegalArgumentException("フレンド関係が存在しません"));

        if (!friendship.getInviteFlag() || !roomId.equals(friendship.getInviteRoomId())) {
            throw new IllegalArgumentException("この部屋への招待が存在しません");
        }

        // ランクマッチ待機中かチェック
        if (matchingQueueService.isInQueue(guestId)) {
            throw new IllegalStateException("ランクマッチ待機中は参加できません");
        }

        // 既に他の部屋に参加中かチェック
        List<Room> existingRooms = roomRepository.findActiveByUserId(guestId);
        if (!existingRooms.isEmpty()) {
            throw new IllegalStateException("既に他の部屋に参加中です");
        }

        // 招待をクリア
        friendship.clearRoomInvitation();
        friendRepository.save(friendship);

        // 部屋に参加
        room.setGuest_id(guestId);
        room.setGuest_ready(false);
        Room updatedRoom = roomRepository.save(room);

        logger.info("部屋に参加しました: roomId={}, guestId={}", roomId, guestId);
        return updatedRoom;
    }

    /**
     * 招待を拒否
     * @param roomId ルームID
     * @param userId ユーザーID
     */
    @Transactional
    public void rejectInvitation(Long roomId, Long userId) {
        // 部屋の存在確認
        Room room = roomRepository.findById(roomId)
                .orElseThrow(() -> new IllegalArgumentException("部屋が存在しません"));

        Long hostId = room.getHost_id();
        Long lowId = Math.min(hostId, userId);
        Long highId = Math.max(hostId, userId);
        Friend friendship = friendRepository.findByUserPair(lowId, highId)
                .orElseThrow(() -> new IllegalArgumentException("フレンド関係が存在しません"));

        if (friendship.getInviteFlag() && roomId.equals(friendship.getInviteRoomId())) {
            friendship.clearRoomInvitation();
            friendRepository.save(friendship);
            logger.info("招待を拒否しました: roomId={}, userId={}", roomId, userId);
        }
    }

    /**
     * 準備完了を設定
     * @param roomId ルームID
     * @param userId ユーザーID
     * @return 更新された部屋
     */
    @Transactional
    public Room setReady(Long roomId, Long userId) {
        Room room = roomRepository.findById(roomId)
                .orElseThrow(() -> new IllegalArgumentException("部屋が存在しません"));

        if (room.getStatus() != Room.Status.WAITING && room.getStatus() != Room.Status.READY) {
            throw new IllegalStateException("この部屋では準備完了できません");
        }

        if (room.getHost_id().equals(userId)) {
            room.setHost_ready(true);
        } else if (userId.equals(room.getGuest_id())) {
            room.setGuest_ready(true);
        } else {
            throw new IllegalArgumentException("この部屋のメンバーではありません");
        }

        // 両者準備完了でステータスをREADYに
        if (room.isHost_ready() && room.isGuest_ready()) {
            room.setStatus(Room.Status.READY);
        }

        Room updatedRoom = roomRepository.save(room);
        logger.info("準備完了: roomId={}, userId={}, hostReady={}, guestReady={}",
                roomId, userId, room.isHost_ready(), room.isGuest_ready());
        return updatedRoom;
    }

    /**
     * 準備完了を解除
     * @param roomId ルームID
     * @param userId ユーザーID
     * @return 更新された部屋
     */
    @Transactional
    public Room cancelReady(Long roomId, Long userId) {
        Room room = roomRepository.findById(roomId)
                .orElseThrow(() -> new IllegalArgumentException("部屋が存在しません"));

        if (room.getStatus() != Room.Status.WAITING && room.getStatus() != Room.Status.READY) {
            throw new IllegalStateException("この部屋では準備解除できません");
        }

        if (room.getHost_id().equals(userId)) {
            room.setHost_ready(false);
        } else if (userId.equals(room.getGuest_id())) {
            room.setGuest_ready(false);
        } else {
            throw new IllegalArgumentException("この部屋のメンバーではありません");
        }

        // ステータスをWAITINGに戻す
        if (room.getStatus() == Room.Status.READY) {
            room.setStatus(Room.Status.WAITING);
        }

        Room updatedRoom = roomRepository.save(room);
        logger.info("準備解除: roomId={}, userId={}", roomId, userId);
        return updatedRoom;
    }

    /**
     * 対戦開始可能かチェック
     * @param roomId ルームID
     * @param hostId ホストのユーザーID
     * @return 開始可能な場合true
     */
    public boolean canStartMatch(Long roomId, Long hostId) {
        Room room = roomRepository.findById(roomId).orElse(null);
        if (room == null) return false;
        if (!room.getHost_id().equals(hostId)) return false;
        if (room.getGuest_id() == null) return false;
        if (!room.isGuest_ready()) return false;
        return room.getStatus() == Room.Status.WAITING || room.getStatus() == Room.Status.READY;
    }

    /**
     * 対戦を開始（ステータスをPLAYINGに変更）
     * @param roomId ルームID
     * @param hostId ホストのユーザーID
     * @return 更新された部屋
     */
    @Transactional
    public Room startMatch(Long roomId, Long hostId) {
        Room room = roomRepository.findById(roomId)
                .orElseThrow(() -> new IllegalArgumentException("部屋が存在しません"));

        if (!room.getHost_id().equals(hostId)) {
            throw new IllegalArgumentException("ホストのみが対戦を開始できます");
        }

        if (room.getGuest_id() == null) {
            throw new IllegalStateException("ゲストが参加していません");
        }

        if (!room.isGuest_ready()) {
            throw new IllegalStateException("ゲストが準備完了していません");
        }

        room.setStatus(Room.Status.PLAYING);
        Room updatedRoom = roomRepository.save(room);

        logger.info("対戦開始: roomId={}, hostId={}, guestId={}",
                roomId, hostId, room.getGuest_id());
        return updatedRoom;
    }

    /**
     * 対戦終了（ステータスをFINISHEDに変更）
     * @param roomId ルームID
     * @return 更新された部屋
     */
    @Transactional
    public Room finishMatch(Long roomId) {
        Room room = roomRepository.findById(roomId)
                .orElseThrow(() -> new IllegalArgumentException("部屋が存在しません"));

        room.setStatus(Room.Status.FINISHED);
        room.setHost_ready(false);
        room.setGuest_ready(false);

        Room updatedRoom = roomRepository.save(room);
        logger.info("対戦終了: roomId={}", roomId);
        return updatedRoom;
    }

    /**
     * 部屋をリセット（対戦終了後に再戦可能にする）
     * @param roomId ルームID
     * @param hostId ホストのユーザーID
     * @return 更新された部屋
     */
    @Transactional
    public Room resetRoom(Long roomId, Long hostId) {
        Room room = roomRepository.findById(roomId)
                .orElseThrow(() -> new IllegalArgumentException("部屋が存在しません"));

        if (!room.getHost_id().equals(hostId)) {
            throw new IllegalArgumentException("ホストのみが部屋をリセットできます");
        }

        if (room.getStatus() != Room.Status.FINISHED) {
            throw new IllegalStateException("対戦終了後のみリセットできます");
        }

        room.setStatus(Room.Status.WAITING);
        room.setHost_ready(false);
        room.setGuest_ready(false);

        Room updatedRoom = roomRepository.save(room);
        logger.info("部屋をリセット: roomId={}", roomId);
        return updatedRoom;
    }

    /**
     * 部屋から退出
     * @param roomId ルームID
     * @param userId ユーザーID
     */
    @Transactional
    public LeaveResult leaveRoom(Long roomId, Long userId) {
        Room room = roomRepository.findById(roomId)
                .orElseThrow(() -> new IllegalArgumentException("部屋が存在しません"));

        if (room.getHost_id().equals(userId)) {
            // ホストが退出 → 部屋を破棄
            room.setStatus(Room.Status.CANCELED);
            roomRepository.save(room);

            // 招待をクリア
            List<Friend> invitations = friendRepository.findAllRoomInvitationsByRoomId(roomId);
            for (Friend f : invitations) {
                f.clearRoomInvitation();
            }
            friendRepository.saveAll(invitations);

            logger.info("ホストが退出、部屋を破棄: roomId={}, hostId={}", roomId, userId);
            return new LeaveResult(true, room.getGuest_id());

        } else if (userId.equals(room.getGuest_id())) {
            // ゲストが退出 → ゲスト情報をクリア
            Long guestId = room.getGuest_id();
            room.setGuest_id(null);
            room.setGuest_ready(false);
            if (room.getStatus() == Room.Status.READY) {
                room.setStatus(Room.Status.WAITING);
            }
            roomRepository.save(room);

            logger.info("ゲストが退出: roomId={}, guestId={}", roomId, guestId);
            return new LeaveResult(false, null);

        } else {
            throw new IllegalArgumentException("この部屋のメンバーではありません");
        }
    }

    /**
     * 部屋の招待済みユーザー一覧を取得
     * @param roomId ルームID
     * @return 招待済みユーザーのリスト
     */
    public List<Friend> getInvitedUsers(Long roomId) {
        return friendRepository.findAllRoomInvitationsByRoomId(roomId);
    }

    /**
     * ユーザーのフレンド一覧を取得（招待用）
     * @param userId ユーザーID
     * @return フレンド一覧
     */
    public List<Friend> getFriendsForInvitation(Long userId) {
        return friendRepository.findFriendsByUserId(userId);
    }

    /**
     * 招待結果
     */
    public record InviteResult(boolean success, boolean canReceiveNow, String message) {}

    /**
     * 退出結果
     */
    public record LeaveResult(boolean roomCanceled, Long notifyUserId) {}
}
