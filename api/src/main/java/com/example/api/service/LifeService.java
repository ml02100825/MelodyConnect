package com.example.api.service;

import com.example.api.dto.LifeStatusResponse;
import com.example.api.entity.User;
import com.example.api.repository.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.LocalDateTime;

/**
 * ライフ（スタミナ）サービス
 * ライフの回復計算、消費処理、状態取得を管理します
 */
@Service
public class LifeService {

    private static final Logger logger = LoggerFactory.getLogger(LifeService.class);

    /** 回復間隔（秒） - 10分 */
    private static final long RECOVERY_INTERVAL_SECONDS = 600;

    /** 通常ユーザーのライフ上限 */
    private static final int MAX_LIFE_NORMAL = 5;

    /** サブスクユーザーのライフ上限 */
    private static final int MAX_LIFE_SUBSCRIBER = 10;

    @Autowired
    private UserRepository userRepository;

    /**
     * マッチング用のライフ消費例外
     */
    public static class LifeConsumeException extends RuntimeException {
        private final java.util.Set<Long> insufficientUserIds;

        public LifeConsumeException(java.util.Set<Long> insufficientUserIds) {
            super("ライフ不足により消費できません");
            this.insufficientUserIds = java.util.Collections.unmodifiableSet(new java.util.HashSet<>(insufficientUserIds));
        }

        public java.util.Set<Long> getInsufficientUserIds() {
            return insufficientUserIds;
        }
    }

    /**
     * ユーザーのライフ上限を取得
     * @param user ユーザー
     * @return ライフ上限（通常:5, サブスク:10）
     */
    public int getMaxLife(User user) {
        return user.isSubscribeFlag() ? MAX_LIFE_SUBSCRIBER : MAX_LIFE_NORMAL;
    }

    /**
     * ライフ状態を取得（回復計算込み）
     * @param userId ユーザーID
     * @return ライフ状態レスポンス
     */
    @Transactional
    public LifeStatusResponse getLifeStatus(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("ユーザーが見つかりません: " + userId));

        // 回復計算を実行
        applyRecovery(user);

        int maxLife = getMaxLife(user);
        long nextRecoveryInSeconds = calculateNextRecoveryInSeconds(user, maxLife);

        return new LifeStatusResponse(
                user.getLife(),
                maxLife,
                nextRecoveryInSeconds,
                user.isSubscribeFlag()
        );
    }

    /**
     * ライフを1消費（ランクマッチ開始時に呼び出し）
     * @param userId ユーザーID
     * @return 消費成功時true、ライフ不足時false
     */
    @Transactional
    public boolean consumeLife(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("ユーザーが見つかりません: " + userId));

        // まず回復計算を実行
        applyRecovery(user);

        // 回復後のライフをDBに反映
        userRepository.save(user);

        // ライフが0の場合は消費不可
        if (user.getLife() <= 0) {
            logger.info("ライフ不足: userId={}, life={}", userId, user.getLife());
            return false;
        }

        // 原子的にライフを消費
        LocalDateTime now = LocalDateTime.now();
        int updatedRows = userRepository.consumeLife(userId, user.getLifeLastRecoveredAt());

        if (updatedRows == 0) {
            // 同時実行により消費できなかった場合
            logger.warn("ライフ消費失敗（同時実行）: userId={}", userId);
            return false;
        }

        logger.info("ライフ消費成功: userId={}, 残りlife={}", userId, user.getLife() - 1);
        return true;
    }

    /**
     * マッチ成立時に2人分のライフを同時に消費
     * @param user1Id プレイヤー1のID
     * @param user2Id プレイヤー2のID
     */
    @Transactional
    public void consumeLifeForMatch(Long user1Id, Long user2Id) {
        User user1 = userRepository.findById(user1Id)
                .orElseThrow(() -> new IllegalArgumentException("ユーザーが見つかりません: " + user1Id));
        User user2 = userRepository.findById(user2Id)
                .orElseThrow(() -> new IllegalArgumentException("ユーザーが見つかりません: " + user2Id));

        applyRecovery(user1);
        applyRecovery(user2);

        userRepository.save(user1);
        userRepository.save(user2);

        java.util.Set<Long> insufficientUserIds = new java.util.HashSet<>();
        if (user1.getLife() <= 0) {
            insufficientUserIds.add(user1Id);
        }
        if (user2.getLife() <= 0) {
            insufficientUserIds.add(user2Id);
        }

        if (!insufficientUserIds.isEmpty()) {
            logger.info("ライフ不足によりマッチ消費失敗: userIds={}", insufficientUserIds);
            throw new LifeConsumeException(insufficientUserIds);
        }

        int updatedRowsUser1 = userRepository.consumeLife(user1Id, user1.getLifeLastRecoveredAt());
        int updatedRowsUser2 = userRepository.consumeLife(user2Id, user2.getLifeLastRecoveredAt());

        if (updatedRowsUser1 == 0 || updatedRowsUser2 == 0) {
            if (updatedRowsUser1 == 0) {
                insufficientUserIds.add(user1Id);
            }
            if (updatedRowsUser2 == 0) {
                insufficientUserIds.add(user2Id);
            }
            logger.warn("ライフ消費失敗（同時実行）: userIds={}", insufficientUserIds);
            throw new LifeConsumeException(insufficientUserIds);
        }

        logger.info("マッチ用ライフ消費成功: user1Id={}, user2Id={}", user1Id, user2Id);
    }

    /**
     * 消費後のライフ状態を取得
     * @param userId ユーザーID
     * @return ライフ状態レスポンス
     */
    @Transactional(readOnly = true)
    public LifeStatusResponse getLifeStatusAfterConsume(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("ユーザーが見つかりません: " + userId));

        int maxLife = getMaxLife(user);
        long nextRecoveryInSeconds = calculateNextRecoveryInSeconds(user, maxLife);

        return new LifeStatusResponse(
                user.getLife(),
                maxLife,
                nextRecoveryInSeconds,
                user.isSubscribeFlag()
        );
    }

    /**
     * 回復計算を適用（Lazy回復）
     * @param user ユーザー
     */
    private void applyRecovery(User user) {
        LocalDateTime now = LocalDateTime.now();
        LocalDateTime lastRecoveredAt = user.getLifeLastRecoveredAt();

        // 初回アクセス時（NULLの場合）は現在時刻をセット
        if (lastRecoveredAt == null) {
            user.setLifeLastRecoveredAt(now);
            logger.info("初回ライフ回復時刻設定: userId={}", user.getId());
            return;
        }

        int maxLife = getMaxLife(user);

        // 既に上限の場合は回復不要
        if (user.getLife() >= maxLife) {
            // 上限の場合は回復時刻を現在に更新
            user.setLifeLastRecoveredAt(now);
            return;
        }

        // 経過時間から回復数を計算
        long elapsedSeconds = Duration.between(lastRecoveredAt, now).getSeconds();
        int recoveryCount = (int) (elapsedSeconds / RECOVERY_INTERVAL_SECONDS);

        if (recoveryCount > 0) {
            int newLife = Math.min(user.getLife() + recoveryCount, maxLife);
            int actualRecovery = newLife - user.getLife();

            // 回復時刻を更新（実際に回復した分だけ進める）
            LocalDateTime newRecoveredAt = lastRecoveredAt.plusSeconds(actualRecovery * RECOVERY_INTERVAL_SECONDS);

            user.setLife(newLife);
            user.setLifeLastRecoveredAt(newRecoveredAt);

            logger.info("ライフ回復: userId={}, 回復数={}, 新life={}", user.getId(), actualRecovery, newLife);
        }
    }

    /**
     * 次回回復までの残り秒数を計算
     * @param user ユーザー
     * @param maxLife ライフ上限
     * @return 残り秒数（上限の場合は0）
     */
    private long calculateNextRecoveryInSeconds(User user, int maxLife) {
        // 上限に達している場合は0
        if (user.getLife() >= maxLife) {
            return 0;
        }

        LocalDateTime lastRecoveredAt = user.getLifeLastRecoveredAt();
        if (lastRecoveredAt == null) {
            return RECOVERY_INTERVAL_SECONDS;
        }

        LocalDateTime now = LocalDateTime.now();
        long elapsedSeconds = Duration.between(lastRecoveredAt, now).getSeconds();
        long remainingSeconds = RECOVERY_INTERVAL_SECONDS - (elapsedSeconds % RECOVERY_INTERVAL_SECONDS);

        return remainingSeconds;
    }

    /**
     * サブスク状態変更時のライフ調整
     * サブスク解約時（上限10→5）にlife > 5の場合は5に丸める
     * @param userId ユーザーID
     */
    @Transactional
    public void adjustLifeForSubscriptionChange(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("ユーザーが見つかりません: " + userId));

        int maxLife = getMaxLife(user);

        if (user.getLife() > maxLife) {
            logger.info("ライフ調整（サブスク変更）: userId={}, 旧life={}, 新life={}",
                    userId, user.getLife(), maxLife);
            user.setLife(maxLife);
            userRepository.save(user);
        }
    }
}
