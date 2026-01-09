package com.example.api.controller;

import com.example.api.entity.Friend;
import com.example.api.entity.Room;
import com.example.api.entity.User;
import com.example.api.listener.RoomWebSocketEventListener;
import com.example.api.repository.UserRepository;
import com.example.api.service.BattleService;
import com.example.api.service.MatchingQueueService;
import com.example.api.service.RoomService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.web.bind.annotation.*;

import java.util.*;

/**
 * ルームコントローラー
 * ルームマッチのREST API及びWebSocket処理を提供します
 */
@RestController
@RequestMapping("/api/rooms")
public class RoomController {

    private static final Logger logger = LoggerFactory.getLogger(RoomController.class);

    private final RoomService roomService;
    private final BattleService battleService;
    private final UserRepository userRepository;
    private final SimpMessagingTemplate messagingTemplate;
    private final RoomWebSocketEventListener webSocketEventListener;
    private final MatchingQueueService matchingQueueService;

    public RoomController(RoomService roomService,
                         BattleService battleService,
                         UserRepository userRepository,
                         SimpMessagingTemplate messagingTemplate,
                         RoomWebSocketEventListener webSocketEventListener,
                         MatchingQueueService matchingQueueService) {
        this.roomService = roomService;
        this.battleService = battleService;
        this.userRepository = userRepository;
        this.messagingTemplate = messagingTemplate;
        this.webSocketEventListener = webSocketEventListener;
        this.matchingQueueService = matchingQueueService;
    }

    // ========== REST API ==========

    /**
     * 部屋を作成
     */
    @PostMapping
    public ResponseEntity<?> createRoom(@RequestBody CreateRoomRequest request) {
        try {
            Room room = roomService.createRoom(
                    request.hostId,
                    request.matchType,
                    request.language,
                    request.problemType,
                    request.questionFormat
            );
            return ResponseEntity.ok(toRoomResponse(room));
        } catch (IllegalStateException | IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(errorResponse(e.getMessage()));
        } catch (Exception e) {
            logger.error("部屋作成エラー", e);
            return ResponseEntity.status(500).body(errorResponse("部屋の作成に失敗しました"));
        }
    }

    /**
     * 部屋情報を取得
     */
    @GetMapping("/{roomId}")
    public ResponseEntity<?> getRoom(@PathVariable Long roomId) {
        try {
            Room room = roomService.getRoom(roomId)
                    .orElseThrow(() -> new IllegalArgumentException("部屋が存在しません"));
            return ResponseEntity.ok(toRoomResponse(room));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(errorResponse(e.getMessage()));
        } catch (Exception e) {
            logger.error("部屋取得エラー", e);
            return ResponseEntity.status(500).body(errorResponse("部屋の取得に失敗しました"));
        }
    }

    /**
     * フレンドを招待
     */
    @PostMapping("/{roomId}/invite")
    public ResponseEntity<?> inviteFriend(@PathVariable Long roomId,
                                          @RequestBody InviteRequest request) {
        try {
            RoomService.InviteResult result = roomService.inviteFriend(roomId, request.hostId, request.friendId);

            Map<String, Object> response = new HashMap<>();
            response.put("success", result.success());
            response.put("message", result.message());
            response.put("canReceiveNow", result.canReceiveNow());

            // 招待通知をWebSocketで送信（受信可能な場合）
            if (result.success() && result.canReceiveNow()) {
                sendInvitationNotification(roomId, request.hostId, request.friendId);
            }

            return ResponseEntity.ok(response);
        } catch (IllegalStateException | IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(errorResponse(e.getMessage()));
        } catch (Exception e) {
            logger.error("招待エラー", e);
            return ResponseEntity.status(500).body(errorResponse("招待の送信に失敗しました"));
        }
    }

    /**
     * 受信招待一覧を取得
     */
    @GetMapping("/invitations")
    public ResponseEntity<?> getInvitations(@RequestParam Long userId) {
        try {
            List<Friend> invitations = roomService.getPendingInvitations(userId);
            List<Map<String, Object>> result = new ArrayList<>();

            for (Friend f : invitations) {
                Map<String, Object> inv = new HashMap<>();
                inv.put("friendId", f.getId());
                inv.put("roomId", f.getInviteRoomId());
                inv.put("invitedAt", f.getInviteSentAt());

                // 招待者情報
                User inviter = f.getRoomInviter();
                if (inviter != null) {
                    Map<String, Object> inviterInfo = new HashMap<>();
                    inviterInfo.put("userId", inviter.getId());
                    inviterInfo.put("username", inviter.getUsername());
                    inviterInfo.put("imageUrl", inviter.getImageUrl());
                    inv.put("inviter", inviterInfo);
                }

                result.add(inv);
            }

            return ResponseEntity.ok(result);
        } catch (Exception e) {
            logger.error("招待一覧取得エラー", e);
            return ResponseEntity.status(500).body(errorResponse("招待一覧の取得に失敗しました"));
        }
    }

    /**
     * 招待を受理
     */
    @PostMapping("/invitations/{roomId}/accept")
    public ResponseEntity<?> acceptInvitation(@PathVariable Long roomId,
                                              @RequestBody AcceptRequest request) {
        try {
            RoomService.AcceptInvitationResult result = roomService.acceptInvitation(roomId, request.userId);
            Room room = result.room();

            // 新規参加の場合のみホストに通知
            if (!result.alreadyJoined()) {
                notifyRoomUpdate(room, "guest_joined");
            }

            Map<String, Object> response = toRoomResponse(room);
            response.put("alreadyJoined", result.alreadyJoined());
            return ResponseEntity.ok(response);
        } catch (IllegalStateException | IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(errorResponse(e.getMessage()));
        } catch (Exception e) {
            logger.error("招待受理エラー", e);
            return ResponseEntity.status(500).body(errorResponse("招待の受理に失敗しました"));
        }
    }

    /**
     * 招待を拒否
     */
    @PostMapping("/invitations/{roomId}/reject")
    public ResponseEntity<?> rejectInvitation(@PathVariable Long roomId,
                                              @RequestBody AcceptRequest request) {
        try {
            roomService.rejectInvitation(roomId, request.userId);

            // ホストに招待拒否を通知
            Room room = roomService.getRoom(roomId).orElse(null);
            if (room != null) {
                sendRoomNotification(room.getHost_id(), "invitation_rejected",
                        Map.of("roomId", roomId, "userId", request.userId));
            }

            return ResponseEntity.ok(Map.of("success", true));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(errorResponse(e.getMessage()));
        } catch (Exception e) {
            logger.error("招待拒否エラー", e);
            return ResponseEntity.status(500).body(errorResponse("招待の拒否に失敗しました"));
        }
    }

    /**
     * 部屋から退出
     */
    @DeleteMapping("/{roomId}/leave")
    public ResponseEntity<?> leaveRoom(@PathVariable Long roomId,
                                       @RequestParam Long userId) {
        try {
            RoomService.LeaveResult result = roomService.leaveRoom(roomId, userId);

            // 相手に通知
            if (result.roomCanceled() && result.notifyUserId() != null) {
                // ホストが退出 → ゲストに部屋キャンセルを通知
                sendRoomNotification(result.notifyUserId(), "room_canceled",
                        Map.of("roomId", roomId));
            } else {
                // ゲストが退出 → ホストにゲスト退出を通知
                Room room = roomService.getRoom(roomId).orElse(null);
                if (room != null) {
                    notifyRoomUpdate(room, "guest_left");
                }
            }

            return ResponseEntity.ok(Map.of(
                    "success", true,
                    "roomCanceled", result.roomCanceled()
            ));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(errorResponse(e.getMessage()));
        } catch (Exception e) {
            logger.error("退出エラー", e);
            return ResponseEntity.status(500).body(errorResponse("退出に失敗しました"));
        }
    }

    /**
     * 部屋をリセット（再戦用）
     */
    @PostMapping("/{roomId}/reset")
    public ResponseEntity<?> resetRoom(@PathVariable Long roomId,
                                       @RequestBody ResetRequest request) {
        try {
            Room room = roomService.resetRoom(roomId, request.hostId);
            notifyRoomUpdate(room, "room_reset");
            return ResponseEntity.ok(toRoomResponse(room));
        } catch (IllegalStateException | IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(errorResponse(e.getMessage()));
        } catch (Exception e) {
            logger.error("リセットエラー", e);
            return ResponseEntity.status(500).body(errorResponse("リセットに失敗しました"));
        }
    }

    /**
     * 単語帳閲覧状態を更新
     */
    @PostMapping("/{roomId}/vocabulary-status")
    public ResponseEntity<?> updateVocabularyStatus(@PathVariable Long roomId,
                                                    @RequestBody VocabularyStatusRequest request) {
        try {
            roomService.setVocabularyStatus(roomId, request.userId, request.inVocabulary);
            Room room = roomService.getRoom(roomId)
                    .orElseThrow(() -> new IllegalArgumentException("部屋が存在しません"));
            notifyRoomUpdate(room, "vocabulary_status");
            return ResponseEntity.ok(Map.of("success", true));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(errorResponse(e.getMessage()));
        } catch (Exception e) {
            logger.error("単語帳状態更新エラー", e);
            return ResponseEntity.status(500).body(errorResponse("単語帳状態の更新に失敗しました"));
        }
    }

    /**
     * フレンド一覧を取得（招待用）
     * 各フレンドにはオンライン状態を付与：
     * - online: WebSocket接続中でバトルしていない
     * - in_battle: ランクマッチのバトル中
     * - room_match: ルームマッチ参加中
     * - matching: マッチング待機中
     * - offline: WebSocket未接続
     *
     * フィルタリング（除外なし、全員表示）：
     * - offlineユーザーは招待不可として表示
     */
    @GetMapping("/friends")
    public ResponseEntity<?> getFriends(@RequestParam Long userId) {
        try {
            List<Friend> friends = roomService.getFriendsForInvitation(userId);
            List<Map<String, Object>> result = new ArrayList<>();

            for (Friend f : friends) {
                // 自分ではない方のユーザーを取得
                User friendUser = f.getUserLow().getId().equals(userId) ? f.getUserHigh() : f.getUserLow();
                Long friendUserId = friendUser.getId();

                Map<String, Object> friendInfo = new HashMap<>();
                friendInfo.put("friendId", f.getId());
                friendInfo.put("userId", friendUserId);
                friendInfo.put("username", friendUser.getUsername());
                friendInfo.put("imageUrl", friendUser.getImageUrl());

                // ユーザー状態を判定
                String status = getUserStatus(friendUserId);
                friendInfo.put("status", status);

                // 招待可能かどうかを判定
                boolean canInvite = canInviteUser(friendUserId, f);
                friendInfo.put("canInvite", canInvite);

                // 既に招待済みかどうか
                boolean alreadyInvited = f.getInviteFlag() != null && f.getInviteFlag()
                        && f.getInviteRoomId() != null;
                friendInfo.put("alreadyInvited", alreadyInvited);

                result.add(friendInfo);
            }

            return ResponseEntity.ok(result);
        } catch (Exception e) {
            logger.error("フレンド一覧取得エラー", e);
            return ResponseEntity.status(500).body(errorResponse("フレンド一覧の取得に失敗しました"));
        }
    }

    /**
     * ユーザーの状態を判定
     * @param userId ユーザーID
     * @return "room_match", "matching", "in_battle", "online", "offline" のいずれか
     */
    private String getUserStatus(Long userId) {
        // オフラインチェック（WebSocket未接続）
        if (!webSocketEventListener.isUserOnline(userId)) {
            return "offline";
        }

        // ルームマッチ参加中チェック（WAITING/READY/PLAYING）
        Optional<Room> activeRoom = roomService.getActiveRoom(userId);
        if (activeRoom.isPresent()) {
            return "room_match";
        }

        // ランクマッチ待機中または対戦中チェック
        if (matchingQueueService.isInQueue(userId)) {
            return "matching";
        }

        if (battleService.isUserInRankBattle(userId)) {
            return "in_battle";
        }

        return "online";
    }

    /**
     * ユーザーを招待可能かどうかを判定
     * @param friendUserId フレンドのユーザーID
     * @param friendship フレンド関係
     * @return 招待可能な場合true
     */
    private boolean canInviteUser(Long friendUserId, Friend friendship) {
        // オフラインの場合は招待不可
        if (!webSocketEventListener.isUserOnline(friendUserId)) {
            return false;
        }

        // 既に招待済みの場合は招待不可
        if (friendship.getInviteFlag() != null && friendship.getInviteFlag()
                && friendship.getInviteRoomId() != null) {
            return false;
        }

        // アクティブな部屋に参加中の場合は招待不可
        if (roomService.hasActiveRoom(friendUserId)) {
            return false;
        }

        // ランクマッチ待機中は招待不可
        if (matchingQueueService.isInQueue(friendUserId)) {
            return false;
        }

        // ランクマッチ中は招待不可
        if (battleService.isUserInRankBattle(friendUserId)) {
            return false;
        }

        return true;
    }

    /**
     * 招待済みユーザー一覧を取得
     */
    @GetMapping("/{roomId}/invited")
    public ResponseEntity<?> getInvitedUsers(@PathVariable Long roomId) {
        try {
            List<Friend> invitations = roomService.getInvitedUsers(roomId);
            List<Map<String, Object>> result = new ArrayList<>();

            for (Friend f : invitations) {
                // 招待を受けた側のユーザーを特定
                User invitee = f.getRoomInviter().getId().equals(f.getUserLow().getId())
                        ? f.getUserHigh() : f.getUserLow();

                Map<String, Object> inv = new HashMap<>();
                inv.put("userId", invitee.getId());
                inv.put("username", invitee.getUsername());
                inv.put("imageUrl", invitee.getImageUrl());
                inv.put("invitedAt", f.getInviteSentAt());
                result.add(inv);
            }

            return ResponseEntity.ok(result);
        } catch (Exception e) {
            logger.error("招待済みユーザー取得エラー", e);
            return ResponseEntity.status(500).body(errorResponse("招待済みユーザーの取得に失敗しました"));
        }
    }

    // ========== WebSocket Handlers ==========

    /**
     * 準備完了
     */
    @MessageMapping("/room/ready")
    public void setReady(@Payload ReadyRequest request) {
        try {
            Room room = roomService.setReady(request.roomId, request.userId);
            notifyRoomUpdate(room, "player_ready");
        } catch (Exception e) {
            logger.error("準備完了エラー", e);
            sendRoomNotification(request.userId, "error",
                    Map.of("message", e.getMessage()));
        }
    }

    /**
     * 準備解除
     */
    @MessageMapping("/room/cancel-ready")
    public void cancelReady(@Payload ReadyRequest request) {
        try {
            Room room = roomService.cancelReady(request.roomId, request.userId);
            notifyRoomUpdate(room, "player_unready");
        } catch (Exception e) {
            logger.error("準備解除エラー", e);
            sendRoomNotification(request.userId, "error",
                    Map.of("message", e.getMessage()));
        }
    }

    /**
     * 対戦開始（ホストのみ）
     */
    @MessageMapping("/room/start")
    public void startMatch(@Payload StartRequest request) {
        try {
            if (!roomService.canStartMatch(request.roomId, request.userId)) {
                sendRoomNotification(request.userId, "error",
                        Map.of("message", "対戦を開始できません"));
                return;
            }

            Room room = roomService.startMatch(request.roomId, request.userId);

            // マッチIDを生成
            String matchUuid = UUID.randomUUID().toString();

            // 先取数（match_type: 5, 7, 9）
            int winsToVictory = room.getMatch_type();

            // Result レコードを作成（ルームマッチ用）
            battleService.createRoomMatchResult(
                    matchUuid,
                    room.getHost_id(),
                    room.getGuest_id(),
                    room.getSelected_language()
            );

            // 対戦状態を初期化
            battleService.initializeRoomBattle(
                    matchUuid,
                    room.getHost_id(),
                    room.getGuest_id(),
                    room.getSelected_language(),
                    winsToVictory,
                    room.getRoom_id()
            );

            logger.info("ルームマッチ対戦初期化完了: matchUuid={}, roomId={}, winsToVictory={}",
                    matchUuid, room.getRoom_id(), winsToVictory);

            // 両者に対戦開始を通知（matchIdを含める）
            Map<String, Object> startData = new HashMap<>();
            startData.put("type", "match_start");
            startData.put("matchId", matchUuid);
            startData.put("roomId", room.getRoom_id());
            startData.put("matchType", room.getMatch_type());
            startData.put("language", room.getSelected_language());
            startData.put("problemType", room.getProblem_type());
            startData.put("questionFormat", room.getQuestion_format());
            startData.put("hostId", room.getHost_id());
            startData.put("guestId", room.getGuest_id());
            startData.put("winsToVictory", winsToVictory);
            startData.put("isRoomMatch", true);

            sendRoomNotification(room.getHost_id(), "match_start", startData);
            sendRoomNotification(room.getGuest_id(), "match_start", startData);

            logger.info("ルームマッチ開始通知送信: roomId={}, matchId={}", room.getRoom_id(), matchUuid);
        } catch (Exception e) {
            logger.error("対戦開始エラー", e);
            sendRoomNotification(request.userId, "error",
                    Map.of("message", e.getMessage()));
        }
    }

    /**
     * 設定を更新（ホストのみ）
     */
    @MessageMapping("/room/update-settings")
    public void updateSettings(@Payload UpdateSettingsRequest request) {
        try {
            Room room = roomService.updateSettings(
                    request.roomId,
                    request.userId,
                    request.matchType,
                    request.language,
                    request.questionFormat,
                    request.problemType
            );
            notifyRoomUpdate(room, "settings_updated");
        } catch (Exception e) {
            logger.error("設定更新エラー", e);
            sendRoomNotification(request.userId, "error",
                    Map.of("message", e.getMessage()));
        }
    }

    /**
     * 退出（WebSocket版）
     */
    @MessageMapping("/room/leave")
    public void leaveRoomWs(@Payload LeaveRequest request) {
        try {
            RoomService.LeaveResult result = roomService.leaveRoom(request.roomId, request.userId);

            if (result.roomCanceled() && result.notifyUserId() != null) {
                sendRoomNotification(result.notifyUserId(), "room_canceled",
                        Map.of("roomId", request.roomId));
            } else {
                Room room = roomService.getRoom(request.roomId).orElse(null);
                if (room != null) {
                    notifyRoomUpdate(room, "guest_left");
                }
            }
        } catch (Exception e) {
            logger.error("退出エラー（WS）", e);
            sendRoomNotification(request.userId, "error",
                    Map.of("message", e.getMessage()));
        }
    }

    // ========== Helper Methods ==========

    private Map<String, Object> toRoomResponse(Room room) {
        Map<String, Object> response = new HashMap<>();
        response.put("roomId", room.getRoom_id());
        response.put("hostId", room.getHost_id());
        response.put("guestId", room.getGuest_id());
        response.put("status", room.getStatus().name());
        response.put("hostReady", room.isHost_ready());
        response.put("guestReady", room.isGuest_ready());
        response.put("matchType", room.getMatch_type());
        response.put("language", room.getSelected_language());
        response.put("problemType", room.getProblem_type());
        response.put("questionFormat", room.getQuestion_format());
        response.put("createdAt", room.getCreated_at());
        response.put("updatedAt", room.getUpdated_at());
        response.put("hostInVocabulary", roomService.isInVocabulary(room.getRoom_id(), room.getHost_id()));
        response.put("guestInVocabulary", room.getGuest_id() != null
                && roomService.isInVocabulary(room.getRoom_id(), room.getGuest_id()));

        // ホスト情報
        userRepository.findById(room.getHost_id()).ifPresent(host -> {
            Map<String, Object> hostInfo = new HashMap<>();
            hostInfo.put("userId", host.getId());
            hostInfo.put("username", host.getUsername());
            hostInfo.put("imageUrl", host.getImageUrl());
            response.put("host", hostInfo);
        });

        // ゲスト情報
        if (room.getGuest_id() != null) {
            userRepository.findById(room.getGuest_id()).ifPresent(guest -> {
                Map<String, Object> guestInfo = new HashMap<>();
                guestInfo.put("userId", guest.getId());
                guestInfo.put("username", guest.getUsername());
                guestInfo.put("imageUrl", guest.getImageUrl());
                response.put("guest", guestInfo);
            });
        }

        return response;
    }

    private void notifyRoomUpdate(Room room, String eventType) {
        Map<String, Object> data = toRoomResponse(room);
        data.put("type", eventType);

        // ホストに通知
        sendRoomNotification(room.getHost_id(), eventType, data);

        // ゲストに通知（存在する場合）
        if (room.getGuest_id() != null) {
            sendRoomNotification(room.getGuest_id(), eventType, data);
        }
    }

    private void sendRoomNotification(Long userId, String type, Map<String, Object> data) {
        Map<String, Object> message = new HashMap<>(data);
        message.put("type", type);
        messagingTemplate.convertAndSend("/topic/room/" + userId, message);
    }

    private void sendInvitationNotification(Long roomId, Long inviterId, Long inviteeId) {
        Room room = roomService.getRoom(roomId).orElse(null);
        User inviter = userRepository.findById(inviterId).orElse(null);

        if (room == null || inviter == null) return;

        Map<String, Object> notification = new HashMap<>();
        notification.put("type", "room_invitation");
        notification.put("roomId", roomId);
        notification.put("matchType", room.getMatch_type());
        notification.put("language", room.getSelected_language());

        Map<String, Object> inviterInfo = new HashMap<>();
        inviterInfo.put("userId", inviter.getId());
        inviterInfo.put("username", inviter.getUsername());
        inviterInfo.put("imageUrl", inviter.getImageUrl());
        notification.put("inviter", inviterInfo);

        messagingTemplate.convertAndSend("/topic/room-invitation/" + inviteeId, notification);
        logger.info("招待通知送信: roomId={}, inviteeId={}", roomId, inviteeId);
    }

    private Map<String, String> errorResponse(String message) {
        Map<String, String> error = new HashMap<>();
        error.put("error", message);
        return error;
    }

    // ========== Request DTOs ==========

    public static class CreateRoomRequest {
        public Long hostId;
        public Integer matchType;
        public String language;
        public String problemType;
        public String questionFormat;
    }

    public static class InviteRequest {
        public Long hostId;
        public Long friendId;
    }

    public static class AcceptRequest {
        public Long userId;
    }

    public static class ResetRequest {
        public Long hostId;
    }

    public static class ReadyRequest {
        public Long roomId;
        public Long userId;
    }

    public static class StartRequest {
        public Long roomId;
        public Long userId;
    }

    public static class LeaveRequest {
        public Long roomId;
        public Long userId;
    }

    public static class UpdateSettingsRequest {
        public Long roomId;
        public Long userId;
        public Integer matchType;
        public String language;
        public String questionFormat;
        public String problemType;
    }

    public static class VocabularyStatusRequest {
        public Long userId;
        public boolean inVocabulary;
    }
}
