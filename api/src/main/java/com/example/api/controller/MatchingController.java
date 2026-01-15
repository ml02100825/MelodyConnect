package com.example.api.controller;

import com.example.api.service.MatchingService;
import com.example.api.service.LifeService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Controller;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * マッチングコントローラー
 * WebSocketを使用したランクマッチのマッチング処理を提供します
 */
@Controller
@EnableScheduling
public class MatchingController {

    private static final Logger logger = LoggerFactory.getLogger(MatchingController.class);

    @Autowired
    private MatchingService matchingService;

    @Autowired
    private LifeService lifeService;

    @Autowired
    private SimpMessagingTemplate messagingTemplate;

    /**
     * マッチングリクエスト
     */
    public static class MatchRequest {
        private Long userId;
        private String language;

        public Long getUserId() {
            return userId;
        }

        public void setUserId(Long userId) {
            this.userId = userId;
        }

        public String getLanguage() {
            return language;
        }

        public void setLanguage(String language) {
            this.language = language;
        }
    }

    /**
     * キャンセルリクエスト
     */
    public static class CancelRequest {
        private Long userId;

        public Long getUserId() {
            return userId;
        }

        public void setUserId(Long userId) {
            this.userId = userId;
        }
    }

    /**
     * マッチングキューに参加
     * クライアントから /app/matching/join にメッセージを送信
     */
    @MessageMapping("/matching/join")
    public void joinMatching(@Payload MatchRequest request) {
        try {
            logger.info("マッチングキュー参加リクエスト: userId={}, language={}", request.getUserId(), request.getLanguage());
            MatchingService.JoinQueueResult result = matchingService.joinQueue(request.getUserId(), request.getLanguage());

            Map<String, Object> response = new HashMap<>();
            if (result.isSuccess()) {
                response.put("status", "joined");
                response.put("message", "マッチングキューに参加しました");
                logger.info("マッチングキュー参加成功: userId={}", request.getUserId());
            } else if ("INSUFFICIENT_LIFE".equals(result.getErrorCode())) {
                // ライフ不足エラー
                response.put("status", "error");
                response.put("code", "INSUFFICIENT_LIFE");
                response.put("message", result.getMessage());
                if (result.getLifeStatus() != null) {
                    response.put("currentLife", result.getLifeStatus().getCurrentLife());
                    response.put("nextRecoveryInSeconds", result.getLifeStatus().getNextRecoveryInSeconds());
                }
                logger.info("ライフ不足によりマッチング拒否: userId={}", request.getUserId());
            } else if ("ALREADY_IN_QUEUE".equals(result.getErrorCode())) {
                response.put("status", "error");
                response.put("code", "ALREADY_IN_QUEUE");
                response.put("message", result.getMessage());
                logger.warn("マッチングキュー参加失敗（既に参加中）: userId={}", request.getUserId());
            } else {
                response.put("status", "error");
                response.put("code", result.getErrorCode());
                response.put("message", result.getMessage());
                logger.warn("マッチングキュー参加失敗: userId={}, code={}", request.getUserId(), result.getErrorCode());
            }

            // 個別のユーザーに送信
            messagingTemplate.convertAndSend(
                    "/topic/matching/" + request.getUserId(),
                    response
            );
        } catch (Exception e) {
            logger.error("マッチングキュー参加エラー: userId={}, error={}", request.getUserId(), e.getMessage(), e);
            Map<String, Object> error = new HashMap<>();
            error.put("status", "error");
            error.put("code", "ERROR");
            error.put("message", e.getMessage());

            messagingTemplate.convertAndSend(
                    "/topic/matching/" + request.getUserId(),
                    error
            );
        }
    }

    /**
     * マッチングキュー情報を更新
     * クライアントから /app/matching/update にメッセージを送信
     */
    @MessageMapping("/matching/update")
    public void updateMatching(@Payload MatchRequest request) {
        try {
            logger.info("マッチングキュー更新リクエスト: userId={}, language={}", request.getUserId(), request.getLanguage());
            MatchingService.JoinQueueResult result = matchingService.updateQueue(request.getUserId(), request.getLanguage());

            Map<String, Object> response = new HashMap<>();
            if (result.isSuccess()) {
                response.put("status", "updated");
                response.put("message", "マッチング条件を更新しました");
                logger.info("マッチングキュー更新成功: userId={}", request.getUserId());
            } else if ("INSUFFICIENT_LIFE".equals(result.getErrorCode())) {
                response.put("status", "error");
                response.put("code", "INSUFFICIENT_LIFE");
                response.put("message", result.getMessage());
                if (result.getLifeStatus() != null) {
                    response.put("currentLife", result.getLifeStatus().getCurrentLife());
                    response.put("nextRecoveryInSeconds", result.getLifeStatus().getNextRecoveryInSeconds());
                }
                logger.info("ライフ不足によりマッチング更新拒否: userId={}", request.getUserId());
            } else {
                response.put("status", "error");
                response.put("code", result.getErrorCode());
                response.put("message", result.getMessage());
                logger.warn("マッチングキュー更新失敗: userId={}, code={}", request.getUserId(), result.getErrorCode());
            }

            messagingTemplate.convertAndSend(
                    "/topic/matching/" + request.getUserId(),
                    response
            );
        } catch (Exception e) {
            logger.error("マッチングキュー更新エラー: userId={}, error={}", request.getUserId(), e.getMessage(), e);
            Map<String, Object> error = new HashMap<>();
            error.put("status", "error");
            error.put("code", "ERROR");
            error.put("message", e.getMessage());

            messagingTemplate.convertAndSend(
                    "/topic/matching/" + request.getUserId(),
                    error
            );
        }
    }

    /**
     * マッチングキューから離脱
     * クライアントから /app/matching/cancel にメッセージを送信
     */
    @MessageMapping("/matching/cancel")
    public void cancelMatching(@Payload CancelRequest request) {
        boolean success = matchingService.leaveQueue(request.getUserId());

        Map<String, Object> response = new HashMap<>();
        if (success) {
            response.put("status", "cancelled");
            response.put("message", "マッチングをキャンセルしました");
        } else {
            response.put("status", "error");
            response.put("message", "キューに参加していません");
        }

        messagingTemplate.convertAndSend(
                "/topic/matching/" + request.getUserId(),
                response
        );
    }

    /**
     * 定期的にマッチングを試行（1秒ごと）
     */
    @Scheduled(fixedRate = 1000)
    public void performMatching() {
        // logger.debug("定期マッチング処理開始");

        // 英語キューでマッチング試行
        tryMatchForLanguage("english");

        // 韓国語キューでマッチング試行
        tryMatchForLanguage("korean");
    }

    /**
     * 指定言語でマッチングを試行
     */
    private void tryMatchForLanguage(String language) {
        // logger.debug("マッチング試行: language={}", language);
        MatchingService.MatchResult match = matchingService.tryMatch(language);

        if (match != null) {
            logger.info("マッチング成立！ matchId={}, user1={}, user2={}, language={}",
                    match.getMatchId(), match.getUser1Id(), match.getUser2Id(), match.getLanguage());

            try {
                lifeService.consumeLifeForMatch(match.getUser1Id(), match.getUser2Id());
            } catch (LifeService.LifeConsumeException e) {
                handleInsufficientLife(match, e.getInsufficientUserIds());
                requeueEligiblePlayers(match, e.getInsufficientUserIds());
                return;
            }

            // Resultレコードを作成
            matchingService.createInitialResult(
                    match.getMatchId(),
                    match.getUser1Id(),
                    match.getUser2Id(),
                    match.getLanguage()
            );
            logger.info("Resultレコード作成完了: matchId={}", match.getMatchId());

            // マッチング成立メッセージを両プレイヤーに送信
            Map<String, Object> matchData = new HashMap<>();
            matchData.put("status", "matched");
            matchData.put("matchId", match.getMatchId());
            matchData.put("language", match.getLanguage());

            // プレイヤー1に送信
            Map<String, Object> player1Data = new HashMap<>(matchData);
            player1Data.put("userId", match.getUser1Id());
            player1Data.put("opponentId", match.getUser2Id());
            messagingTemplate.convertAndSend(
                    "/topic/matching/" + match.getUser1Id(),
                    player1Data
            );
            logger.info("マッチング通知送信完了: user1={}", match.getUser1Id());

            // プレイヤー2に送信
            Map<String, Object> player2Data = new HashMap<>(matchData);
            player2Data.put("userId", match.getUser2Id());
            player2Data.put("opponentId", match.getUser1Id());
            messagingTemplate.convertAndSend(
                    "/topic/matching/" + match.getUser2Id(),
                    player2Data
            );
            logger.info("マッチング通知送信完了: user2={}", match.getUser2Id());
        } else {
            // logger.debug("マッチング不成立: language={}", language);
        }
    }

    private void handleInsufficientLife(MatchingService.MatchResult match, java.util.Set<Long> insufficientUserIds) {
        for (Long userId : insufficientUserIds) {
            Map<String, Object> response = new HashMap<>();
            response.put("status", "error");
            response.put("code", "INSUFFICIENT_LIFE");
            response.put("message", "ライフが不足しています");

            try {
                com.example.api.dto.LifeStatusResponse lifeStatus = lifeService.getLifeStatus(userId);
                response.put("currentLife", lifeStatus.getCurrentLife());
                response.put("nextRecoveryInSeconds", lifeStatus.getNextRecoveryInSeconds());
            } catch (Exception e) {
                logger.warn("ライフ状態取得失敗: userId={}, error={}", userId, e.getMessage(), e);
            }

            messagingTemplate.convertAndSend(
                    "/topic/matching/" + userId,
                    response
            );
            logger.info("ライフ不足通知送信: userId={}", userId);
        }
    }

    private void requeueEligiblePlayers(MatchingService.MatchResult match, java.util.Set<Long> insufficientUserIds) {
        if (!insufficientUserIds.contains(match.getUser1Id())) {
            matchingService.joinQueue(match.getUser1Id(), match.getLanguage());
        }
        if (!insufficientUserIds.contains(match.getUser2Id())) {
            matchingService.joinQueue(match.getUser2Id(), match.getLanguage());
        }
    }

    /**
     * 定期的にタイムアウトしたプレイヤーを削除（1分ごと）
     */
    @Scheduled(fixedRate = 60000)
    public void removeTimedOutPlayers() {
        List<Long> timedOutUsers = matchingService.removeTimedOutPlayers();

        for (Long userId : timedOutUsers) {
            Map<String, Object> timeoutMessage = new HashMap<>();
            timeoutMessage.put("status", "timeout");
            timeoutMessage.put("message", "マッチングがタイムアウトしました（15分経過）");

            messagingTemplate.convertAndSend(
                    "/topic/matching/" + userId,
                    timeoutMessage
            );
        }
    }
}
