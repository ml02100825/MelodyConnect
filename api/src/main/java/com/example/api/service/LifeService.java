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

@Service
public class LifeService {

    private static final Logger logger = LoggerFactory.getLogger(LifeService.class);

    private static final long RECOVERY_INTERVAL_SECONDS = 600;
    private static final int MAX_LIFE_NORMAL = 5;
    private static final int MAX_LIFE_SUBSCRIBER = 10;

    @Autowired
    private UserRepository userRepository;

    public int getMaxLife(User user) {
        // ▼▼▼ 修正: 1(契約中)または2(解約予約中)なら特典あり ▼▼▼
        return (user.getSubscribeFlag() == 1 || user.getSubscribeFlag() == 2) ? MAX_LIFE_SUBSCRIBER : MAX_LIFE_NORMAL;
    }

    @Transactional
    public LifeStatusResponse getLifeStatus(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("ユーザーが見つかりません: " + userId));

        applyRecovery(user);

        int maxLife = getMaxLife(user);
        long nextRecoveryInSeconds = calculateNextRecoveryInSeconds(user, maxLife);

        // ▼▼▼ 修正: 1または2なら特典あり ▼▼▼
        boolean isPremium = (user.getSubscribeFlag() == 1 || user.getSubscribeFlag() == 2);

        return new LifeStatusResponse(
                user.getLife(),
                maxLife,
                nextRecoveryInSeconds,
                isPremium
        );
    }

    @Transactional
    public boolean consumeLife(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("ユーザーが見つかりません: " + userId));

        applyRecovery(user);
        userRepository.save(user);

        if (user.getLife() <= 0) {
            logger.info("ライフ不足: userId={}, life={}", userId, user.getLife());
            return false;
        }

        int updatedRows = userRepository.consumeLife(userId, user.getLifeLastRecoveredAt());

        if (updatedRows == 0) {
            logger.warn("ライフ消費失敗（同時実行）: userId={}", userId);
            return false;
        }

        logger.info("ライフ消費成功: userId={}, 残りlife={}", userId, user.getLife() - 1);
        return true;
    }

    @Transactional(readOnly = true)
    public LifeStatusResponse getLifeStatusAfterConsume(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("ユーザーが見つかりません: " + userId));

        int maxLife = getMaxLife(user);
        long nextRecoveryInSeconds = calculateNextRecoveryInSeconds(user, maxLife);

        // ▼▼▼ 修正: 1または2なら特典あり ▼▼▼
        boolean isPremium = (user.getSubscribeFlag() == 1 || user.getSubscribeFlag() == 2);

        return new LifeStatusResponse(
                user.getLife(),
                maxLife,
                nextRecoveryInSeconds,
                isPremium
        );
    }

    private void applyRecovery(User user) {
        LocalDateTime now = LocalDateTime.now();
        LocalDateTime lastRecoveredAt = user.getLifeLastRecoveredAt();

        if (lastRecoveredAt == null) {
            user.setLifeLastRecoveredAt(now);
            logger.info("初回ライフ回復時刻設定: userId={}", user.getId());
            return;
        }

        int maxLife = getMaxLife(user);

        if (user.getLife() >= maxLife) {
            user.setLifeLastRecoveredAt(now);
            return;
        }

        long elapsedSeconds = Duration.between(lastRecoveredAt, now).getSeconds();
        int recoveryCount = (int) (elapsedSeconds / RECOVERY_INTERVAL_SECONDS);

        if (recoveryCount > 0) {
            int newLife = Math.min(user.getLife() + recoveryCount, maxLife);
            int actualRecovery = newLife - user.getLife();

            LocalDateTime newRecoveredAt = lastRecoveredAt.plusSeconds(actualRecovery * RECOVERY_INTERVAL_SECONDS);

            user.setLife(newLife);
            user.setLifeLastRecoveredAt(newRecoveredAt);

            logger.info("ライフ回復: userId={}, 回復数={}, 新life={}", user.getId(), actualRecovery, newLife);
        }
    }

    private long calculateNextRecoveryInSeconds(User user, int maxLife) {
        if (user.getLife() >= maxLife) {
            return 0;
        }

        LocalDateTime lastRecoveredAt = user.getLifeLastRecoveredAt();
        if (lastRecoveredAt == null) {
            return RECOVERY_INTERVAL_SECONDS;
        }

        LocalDateTime now = LocalDateTime.now();
        long elapsedSeconds = Duration.between(lastRecoveredAt, now).getSeconds();
        return RECOVERY_INTERVAL_SECONDS - (elapsedSeconds % RECOVERY_INTERVAL_SECONDS);
    }

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