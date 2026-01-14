package com.example.api.controller;

import com.example.api.listener.RoomWebSocketEventListener;
import org.springframework.messaging.handler.annotation.Header;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.stereotype.Controller;

/**
 * WebSocketのオンライン判定用ハートビートを受信します
 */
@Controller
public class PresenceController {

    private final RoomWebSocketEventListener webSocketEventListener;

    public PresenceController(RoomWebSocketEventListener webSocketEventListener) {
        this.webSocketEventListener = webSocketEventListener;
    }

    @MessageMapping("/presence/heartbeat")
    public void handleHeartbeat(@Payload HeartbeatRequest request,
                                @Header(value = "simpSessionId", required = false) String sessionId) {
        if (request != null && request.getUserId() != null) {
            webSocketEventListener.refreshLastSeen(request.getUserId());
            return;
        }
        webSocketEventListener.refreshLastSeenBySessionId(sessionId);
    }

    public static class HeartbeatRequest {
        private Long userId;

        public Long getUserId() {
            return userId;
        }

        public void setUserId(Long userId) {
            this.userId = userId;
        }
    }
}
