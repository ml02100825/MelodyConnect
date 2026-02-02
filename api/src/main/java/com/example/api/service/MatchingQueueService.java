package com.example.api.service;

import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;

/**
 * マッチングキュー管理サービス
 * ランクマッチ待機中のプレイヤーをメモリ内で管理します
 */
@Service
public class MatchingQueueService {

    /**
     * マッチング待機プレイヤー情報
     */
    public static class QueuedPlayer {
        private final Long userId;
        private final Integer rating;
        private final String language;
        private final LocalDateTime joinedAt;

        public QueuedPlayer(Long userId, Integer rating, String language) {
            this.userId = userId;
            this.rating = rating;
            this.language = language;
            this.joinedAt = LocalDateTime.now();
        }

        public QueuedPlayer(Long userId, Integer rating, String language, LocalDateTime joinedAt) {
            this.userId = userId;
            this.rating = rating;
            this.language = language;
            this.joinedAt = joinedAt;
        }

        public Long getUserId() {
            return userId;
        }

        public Integer getRating() {
            return rating;
        }

        public String getLanguage() {
            return language;
        }

        public LocalDateTime getJoinedAt() {
            return joinedAt;
        }

        /**
         * 待機時間（秒）を取得
         */
        public long getWaitTimeSeconds() {
            return java.time.Duration.between(joinedAt, LocalDateTime.now()).getSeconds();
        }
    }

    // 言語別マッチングキュー（Key: 言語、Value: プレイヤーリスト）
    private final Map<String, List<QueuedPlayer>> languageQueues = new ConcurrentHashMap<>();

    // ユーザーIDからQueuedPlayerへのマッピング（重複チェック用）
    private final Map<Long, QueuedPlayer> activeUsers = new ConcurrentHashMap<>();

    /**
     * プレイヤーをキューに追加
     * @param userId ユーザーID
     * @param rating レーティング
     * @param language 言語
     * @return 追加成功時true、既にキューに入っている場合false
     */
    public synchronized boolean addToQueue(Long userId, Integer rating, String language) {
        // 既にキューに入っているかチェック
        if (activeUsers.containsKey(userId)) {
            return false;
        }

        QueuedPlayer player = new QueuedPlayer(userId, rating, language);
        activeUsers.put(userId, player);

        // 言語別キューに追加
        languageQueues.computeIfAbsent(language, k -> new ArrayList<>()).add(player);

        return true;
    }

    /**
     * プレイヤーをキューから削除
     * @param userId ユーザーID
     * @return 削除成功時true、キューに存在しない場合false
     */
    public synchronized boolean removeFromQueue(Long userId) {
        QueuedPlayer player = activeUsers.remove(userId);
        if (player == null) {
            return false;
        }

        // 言語別キューから削除
        List<QueuedPlayer> queue = languageQueues.get(player.getLanguage());
        if (queue != null) {
            queue.remove(player);
            if (queue.isEmpty()) {
                languageQueues.remove(player.getLanguage());
            }
        }

        return true;
    }

    /**
     * プレイヤーのキュー情報を更新
     * @param userId ユーザーID
     * @param rating レーティング
     * @param language 言語
     * @return 更新成功時true、キューに存在しない場合false
     */
    public synchronized boolean updateQueue(Long userId, Integer rating, String language) {
        QueuedPlayer existingPlayer = activeUsers.get(userId);
        if (existingPlayer == null) {
            return false;
        }

        // 既存キューから削除
        List<QueuedPlayer> existingQueue = languageQueues.get(existingPlayer.getLanguage());
        if (existingQueue != null) {
            existingQueue.remove(existingPlayer);
            if (existingQueue.isEmpty()) {
                languageQueues.remove(existingPlayer.getLanguage());
            }
        }

        QueuedPlayer updatedPlayer = new QueuedPlayer(
                userId,
                rating,
                language,
                existingPlayer.getJoinedAt()
        );
        activeUsers.put(userId, updatedPlayer);
        languageQueues.computeIfAbsent(language, k -> new ArrayList<>()).add(updatedPlayer);

        return true;
    }

    /**
     * 指定言語のキューを取得
     * @param language 言語
     * @return プレイヤーリスト（コピー）
     */
    public synchronized List<QueuedPlayer> getQueueByLanguage(String language) {
        List<QueuedPlayer> queue = languageQueues.get(language);
        return queue == null ? new ArrayList<>() : new ArrayList<>(queue);
    }

    /**
     * ユーザーがキューに入っているかチェック
     * @param userId ユーザーID
     * @return キューに入っている場合true
     */
    public boolean isInQueue(Long userId) {
        return activeUsers.containsKey(userId);
    }

    /**
     * キュー内のプレイヤー情報を取得
     * @param userId ユーザーID
     * @return プレイヤー情報（キューに存在しない場合null）
     */
    public QueuedPlayer getPlayer(Long userId) {
        return activeUsers.get(userId);
    }

    /**
     * 15分以上待機しているプレイヤーを削除（タイムアウト処理）
     * @return 削除されたプレイヤーのユーザーIDリスト
     */
    public synchronized List<Long> removeTimedOutPlayers() {
        List<Long> timedOutUsers = new ArrayList<>();
        LocalDateTime timeoutThreshold = LocalDateTime.now().minusMinutes(15);

        activeUsers.entrySet().removeIf(entry -> {
            QueuedPlayer player = entry.getValue();
            if (player.getJoinedAt().isBefore(timeoutThreshold)) {
                // 言語別キューからも削除
                List<QueuedPlayer> queue = languageQueues.get(player.getLanguage());
                if (queue != null) {
                    queue.remove(player);
                    if (queue.isEmpty()) {
                        languageQueues.remove(player.getLanguage());
                    }
                }
                timedOutUsers.add(entry.getKey());
                return true;
            }
            return false;
        });

        return timedOutUsers;
    }

    /**
     * 全体のキュー統計情報を取得（デバッグ用）
     */
    public Map<String, Object> getQueueStats() {
        Map<String, Object> stats = new HashMap<>();
        stats.put("totalPlayers", activeUsers.size());

        Map<String, Integer> languageStats = new HashMap<>();
        languageQueues.forEach((lang, players) -> {
            languageStats.put(lang, players.size());
        });
        stats.put("byLanguage", languageStats);

        return stats;
    }
}
