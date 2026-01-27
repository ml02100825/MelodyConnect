package com.example.api.service;

import com.example.api.entity.Badge;
import com.example.api.entity.GotBadge;
import com.example.api.entity.User;
import com.example.api.repository.BadgeRepository;
import com.example.api.repository.GotBadgeRepository;
import com.example.api.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Service
@RequiredArgsConstructor
public class BadgeGrantService {

    private static final Logger logger = LoggerFactory.getLogger(BadgeGrantService.class);

    private final BadgeRepository badgeRepository;
    private final GotBadgeRepository gotBadgeRepository;
    private final UserRepository userRepository;

    /**
     * 指定したユーザーに、指定した名前のバッジを付与するメソッド
     * (すでに持っている場合は何もしない)
     */
    @Transactional
    public void grantBadgeByName(Long userId, String badgeName) {
        User user = userRepository.findById(userId).orElse(null);
        if (user == null) return;

        // 1. バッジマスタからバッジ情報を取得
        Optional<Badge> badgeOpt = badgeRepository.findByBadgeName(badgeName);
        
        if (badgeOpt.isEmpty()) {
            logger.warn("バッジが見つかりません: {}", badgeName);
            return;
        }
        Badge badge = badgeOpt.get();

        // 2. すでに持っているかチェック
        List<GotBadge> myBadges = gotBadgeRepository.findByUser(user);
        boolean alreadyHas = myBadges.stream()
                .anyMatch(gb -> gb.getBadge().getId().equals(badge.getId()));

        if (alreadyHas) return;

        // 3. 持っていなければ付与
        GotBadge newBadge = new GotBadge();
        newBadge.setUser(user);
        newBadge.setBadge(badge);
        newBadge.setAcquired_at(LocalDateTime.now());
        
        gotBadgeRepository.save(newBadge);
        logger.info("バッジ獲得！: {} (User: {})", badgeName, userId);
    }
}