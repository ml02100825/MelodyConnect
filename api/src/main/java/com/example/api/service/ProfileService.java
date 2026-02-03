package com.example.api.service;

import com.example.api.dto.BadgeResponse;
import com.example.api.dto.ProfileUpdateRequest;
import com.example.api.entity.*;
import com.example.api.repository.*;
import com.example.api.util.SeasonCalculator;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
import java.util.stream.Collectors;

@Service
public class ProfileService {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private RateRepository rateRepository;

    @Autowired
    private GotBadgeRepository gotBadgeRepository;

    @Autowired
    private SeasonCalculator seasonCalculator;

    /**
     * プロフィール更新（ステップ2: ユーザー名、アイコン、ユーザーID設定）
     * @param userId ユーザーID
     * @param request プロフィール更新リクエスト
     * @return 更新されたユーザー
     * @throws IllegalArgumentException ユーザーが見つからない場合、またはユーザーIDが重複している場合
     */
    @Transactional
    public User updateProfile(Long userId, ProfileUpdateRequest request) {
        User user = getUserOrThrow(userId);

        if (request.getUserUuid() != null && !request.getUserUuid().equals(user.getUserUuid())) {
            Optional<User> existing = userRepository.findByUserUuid(request.getUserUuid());
            if (existing.isPresent()) {
                throw new IllegalArgumentException("このIDは既に使用されています");
            }
            user.setUserUuid(request.getUserUuid());
        }

        user.setUsername(request.getUsername());
        if (request.getImageUrl() != null && !request.getImageUrl().isEmpty()) {
            user.setImageUrl(request.getImageUrl());
        }

    return userRepository.save(user);
}

    // 音量更新メソッドは削除しました

    @Transactional
    public void updatePrivacy(Long userId, int privacy) {
        User user = getUserOrThrow(userId);
        user.setPrivacy(privacy);
        userRepository.save(user);
    }

    public User getUserProfile(Long userId) {
        return getUserOrThrow(userId);
    }

    /**
     * プロフィールのレート・バッジ情報を取得
     * @param user ユーザー
     * @return rate と badges を含むMap
     */
    @Transactional(readOnly = true)
    public Map<String, Object> getProfileExtras(User user) {
        Integer currentSeason = seasonCalculator.getCurrentSeason();
        Integer rate = rateRepository.findByUserAndSeason(user, currentSeason)
                .map(Rate::getRate)
                .orElse(null);

        List<GotBadge> gotBadges = gotBadgeRepository.findByUser(user);
        List<BadgeResponse> badges = gotBadges.stream().map(gotBadge -> {
            Badge badge = gotBadge.getBadge();
            return new BadgeResponse(
                    badge.getId(),
                    badge.getBadgeName(),
                    badge.getAcquisitionCondition(),
                    badge.getImageUrl(),
                    gotBadge.getAcquired_at()
            );
        }).collect(Collectors.toList());

        Map<String, Object> extras = new HashMap<>();
        extras.put("rate", rate);
        extras.put("badges", badges);
        return extras;
    }

    private User getUserOrThrow(Long userId) {
        return userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("ユーザーが見つかりません: ID=" + userId));
    }
}