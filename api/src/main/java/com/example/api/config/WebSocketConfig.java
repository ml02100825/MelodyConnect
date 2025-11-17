package com.example.api.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.messaging.simp.config.MessageBrokerRegistry;
import org.springframework.web.socket.config.annotation.EnableWebSocketMessageBroker;
import org.springframework.web.socket.config.annotation.StompEndpointRegistry;
import org.springframework.web.socket.config.annotation.WebSocketMessageBrokerConfigurer;

/**
 * WebSocket設定クラス
 * STOMPプロトコルを使用したWebSocketメッセージングを設定します
 */
@Configuration
@EnableWebSocketMessageBroker
public class WebSocketConfig implements WebSocketMessageBrokerConfigurer {

    /**
     * STOMPエンドポイントの登録
     * クライアントがWebSocketに接続するためのエンドポイントを設定します
     */
    @Override
    public void registerStompEndpoints(StompEndpointRegistry registry) {
        registry.addEndpoint("/ws")
                .setAllowedOriginPatterns("*")
                .setHandshakeHandler(new org.springframework.web.socket.server.standard.DefaultHandshakeHandler());
    }

    /**
     * メッセージブローカーの設定
     * /topic: サーバーからクライアントへのブロードキャスト用
     * /queue: 1対1メッセージング用
     * /app: クライアントからサーバーへのメッセージ送信用プレフィックス
     */
    @Override
    public void configureMessageBroker(MessageBrokerRegistry registry) {
        registry.enableSimpleBroker("/topic", "/queue");
        registry.setApplicationDestinationPrefixes("/app");
        registry.setUserDestinationPrefix("/user");
    }
}
