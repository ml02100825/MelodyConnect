package com.example.api.listener;

import com.example.api.entity.Room;
import com.example.api.service.BattleService;
import com.example.api.service.BattleStateService;
import com.example.api.service.RoomService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.event.EventListener;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.messaging.simp.stomp.StompHeaderAccessor;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.messaging.SessionConnectEvent;
import org.springframework.web.socket.messaging.SessionDisconnectEvent;
import org.springframework.scheduling.annotation.Scheduled;

import java.time.Duration;
import java.time.Instant;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;

/**
 * WebSocket接続・切断イベントリスナー
 * ルームマッチの切断処理を担当します
 */
@Component
public class RoomWebSocketEventListener {

    private static final Logger logger = LoggerFactory.getLogger(RoomWebSocketEventListener.class);
    private static final Duration OFFLINE_TIMEOUT = Duration.ofSeconds(90);

    private final RoomService roomService;
    private final BattleService battleService;
    private final BattleStateService battleStateService;
    private final SimpMessagingTemplate messagingTemplate;

    // セッションID → ユーザーID のマッピング
    private final ConcurrentHashMap<String, Long> sessionUserMap = new ConcurrentHashMap<>();

    // ユーザーID → セッションID のマッピング（逆引き用）
    private final ConcurrentHashMap<Long, String> userSessionMap = new ConcurrentHashMap<>();

    // ユーザーID → 最終アクティブ時刻
    private final ConcurrentHashMap<Long, Instant> userLastSeenMap = new ConcurrentHashMap<>();

    public RoomWebSocketEventListener(RoomService roomService,
                                      BattleService battleService,
                                      BattleStateService battleStateService,
                                      SimpMessagingTemplate messagingTemplate) {
        this.roomService = roomService;
        this.battleService = battleService;
        this.battleStateService = battleStateService;
        this.messagingTemplate = messagingTemplate;
    }

    /**
     * ユーザーをセッションに登録（接続時またはルーム参加時に呼び出す）
     */
    public void registerUser(String sessionId, Long userId) {
        sessionUserMap.put(sessionId, userId);
        userSessionMap.put(userId, sessionId);
        userLastSeenMap.put(userId, Instant.now());
        logger.debug("セッション登録: sessionId={}, userId={}", sessionId, userId);
    }

    /**
     * 最終アクティブ時刻を更新
     */
    public void refreshLastSeen(Long userId) {
        if (userId == null) {
            return;
        }
        userLastSeenMap.put(userId, Instant.now());
    }

    /**
     * セッションIDから最終アクティブ時刻を更新
     */
    public void refreshLastSeenBySessionId(String sessionId) {
        if (sessionId == null) {
            return;
        }
        Long userId = sessionUserMap.get(sessionId);
        if (userId != null) {
            refreshLastSeen(userId);
        }
    }

    /**
     * ユーザーがオンライン（WebSocket接続中）かどうかを確認
     * @param userId ユーザーID
     * @return オンラインの場合true
     */
    public boolean isUserOnline(Long userId) {
        if (userId == null) {
            return false;
        }
        Instant lastSeen = userLastSeenMap.get(userId);
        if (lastSeen == null) {
            return false;
        }
        if (Duration.between(lastSeen, Instant.now()).compareTo(OFFLINE_TIMEOUT) > 0) {
            removeUserSession(userId);
            return false;
        }
        return userSessionMap.containsKey(userId);
    }

    private void removeUserSession(Long userId) {
        String sessionId = userSessionMap.remove(userId);
        if (sessionId != null) {
            sessionUserMap.remove(sessionId);
        }
        userLastSeenMap.remove(userId);
    }

    /**
     * WebSocket接続イベント
     */
    @EventListener
    public void handleWebSocketConnectListener(SessionConnectEvent event) {
        StompHeaderAccessor headerAccessor = StompHeaderAccessor.wrap(event.getMessage());
        String sessionId = headerAccessor.getSessionId();

        // ネイティブヘッダーからuserIdを取得
        String userIdHeader = headerAccessor.getFirstNativeHeader("userId");
        if (userIdHeader != null) {
            try {
                Long userId = Long.parseLong(userIdHeader);
                registerUser(sessionId, userId);
                logger.info("WebSocket接続: sessionId={}, userId={}", sessionId, userId);
            } catch (NumberFormatException e) {
                logger.warn("無効なuserId: {}", userIdHeader);
            }
        }
    }

    /**
     * WebSocket切断イベント
     */
    @EventListener
    public void handleWebSocketDisconnectListener(SessionDisconnectEvent event) {
        StompHeaderAccessor headerAccessor = StompHeaderAccessor.wrap(event.getMessage());
        String sessionId = headerAccessor.getSessionId();

        Long userId = sessionUserMap.remove(sessionId);
        if (userId == null) {
            logger.debug("切断: 登録されていないセッション sessionId={}", sessionId);
            return;
        }

        // 逆引きマップからも削除
        userSessionMap.remove(userId);
        userLastSeenMap.remove(userId);

        logger.info("WebSocket切断検知: sessionId={}, userId={}", sessionId, userId);

        try {
            // ユーザーのアクティブなルームを確認
            Optional<Room> activeRoom = roomService.getActiveRoom(userId);

            if (activeRoom.isEmpty()) {
                logger.debug("切断ユーザーにはアクティブな部屋がありません: userId={}", userId);
                return;
            }

            Room room = activeRoom.get();
            Long roomId = room.getRoom_id();
            Room.Status status = room.getStatus();

            logger.info("切断ユーザーのルーム状態: roomId={}, status={}, hostId={}, guestId={}, disconnectedUserId={}",
                    roomId, status, room.getHost_id(), room.getGuest_id(), userId);

            // 対戦中の場合：切断側を敗北として処理
            if (status == Room.Status.PLAYING) {
                handleBattleDisconnect(room, userId);
            }
            // 対戦中でない場合：ルームからの退出/解散
            else if (status == Room.Status.WAITING || status == Room.Status.READY) {
                handleRoomDisconnect(room, userId);
            }

        } catch (Exception e) {
            logger.error("切断処理中にエラー: userId={}", userId, e);
        }
    }

    /**
     * 一定時間アクティブでないユーザーをオフライン扱いにする
     */
    @Scheduled(fixedRate = 30000)
    public void removeInactiveUsers() {
        Instant now = Instant.now();
        for (Map.Entry<Long, Instant> entry : userLastSeenMap.entrySet()) {
            if (Duration.between(entry.getValue(), now).compareTo(OFFLINE_TIMEOUT) > 0) {
                Long userId = entry.getKey();
                removeUserSession(userId);
                logger.info("タイムアウトによりオフライン判定: userId={}", userId);
            }
        }
    }

    /**
     * 対戦中の切断処理（敗北扱い）
     */
    private void handleBattleDisconnect(Room room, Long disconnectedUserId) {
        Long roomId = room.getRoom_id();
        Long hostId = room.getHost_id();
        Long guestId = room.getGuest_id();

        // 相手を特定
        Long winnerId = disconnectedUserId.equals(hostId) ? guestId : hostId;

        logger.info("対戦中の切断 → 切断者敗北: roomId={}, disconnectedUserId={}, winnerId={}",
                roomId, disconnectedUserId, winnerId);

        try {
            // BattleServiceで対戦終了処理（切断による敗北）
            String matchUuid = battleStateService.getMatchUuidByRoomId(roomId);
            if (matchUuid != null) {
                battleService.handleDisconnection(matchUuid, disconnectedUserId, winnerId);
            }

            // ルームのステータスをFINISHEDに
            roomService.finishMatch(roomId);

            // 相手に通知
            if (winnerId != null) {
                Map<String, Object> notification = Map.of(
                        "type", "opponent_disconnected",
                        "roomId", roomId,
                        "winnerId", winnerId,
                        "disconnectedUserId", disconnectedUserId,
                        "message", "相手が切断しました。あなたの勝利です！"
                );
                messagingTemplate.convertAndSend("/topic/room/" + winnerId, notification);

                // バトル画面にも通知
                messagingTemplate.convertAndSend("/topic/battle/" + winnerId, notification);
            }

        } catch (Exception e) {
            logger.error("対戦中切断処理エラー: roomId={}", roomId, e);
        }
    }

    /**
     * 待機中/準備中の切断処理（退出/解散）
     */
    private void handleRoomDisconnect(Room room, Long disconnectedUserId) {
        Long roomId = room.getRoom_id();
        Long hostId = room.getHost_id();
        Long guestId = room.getGuest_id();

        try {
            if (disconnectedUserId.equals(hostId)) {
                // ホストが切断 → ルーム解散
                logger.info("ホスト切断 → ルーム解散: roomId={}, hostId={}", roomId, hostId);

                RoomService.LeaveResult result = roomService.leaveRoom(roomId, hostId);

                // ゲストに通知
                if (guestId != null) {
                    Map<String, Object> notification = Map.of(
                            "type", "room_canceled",
                            "roomId", roomId,
                            "message", "ホストが切断したため、部屋が解散されました"
                    );
                    messagingTemplate.convertAndSend("/topic/room/" + guestId, notification);
                }

            } else if (disconnectedUserId.equals(guestId)) {
                // ゲストが切断 → 退出
                logger.info("ゲスト切断 → 退出: roomId={}, guestId={}", roomId, guestId);

                roomService.leaveRoom(roomId, guestId);

                // ホストに通知
                Map<String, Object> notification = Map.of(
                        "type", "guest_left",
                        "roomId", roomId,
                        "message", "ゲストが切断しました"
                );
                messagingTemplate.convertAndSend("/topic/room/" + hostId, notification);
            }

        } catch (Exception e) {
            logger.error("ルーム切断処理エラー: roomId={}", roomId, e);
        }
    }
}
