package com.example.api.service;

import com.example.api.dto.BadgeDto;
import com.example.api.entity.Badge;
import com.example.api.entity.GotBadge;
import com.example.api.entity.User;
import com.example.api.repository.BadgeRepository;
import com.example.api.repository.GotBadgeRepository;
import com.example.api.repository.UserRepository;

import lombok.RequiredArgsConstructor;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class BadgeService {

    private final BadgeRepository badgeRepository;
    private final GotBadgeRepository gotBadgeRepository;
    @Autowired
    private UserRepository userRepository;

    @Transactional(readOnly = true)
    // ★修正: 引数に modeStr を追加
    public List<BadgeDto> getUserBadges(Long userId, String modeStr) {
        
        // 1. バッジマスタ取得 (モードによって切り替え)
        List<Badge> activeBadges;

        // 文字列(modeStr) を 数値(modeInt) に変換
        Integer modeInt = convertModeToInt(modeStr);

        if (modeInt == null) {
            // "all" または変換できない場合は全件取得
            activeBadges = badgeRepository.findByIsActiveTrueAndIsDeletedFalse();
        } else {
            // 指定されたモード(数値)でフィルタリング
            activeBadges = badgeRepository.findByModeAndIsActiveTrueAndIsDeletedFalse(modeInt);
        }

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("ユーザーが見つかりません"));
        
        // ユーザーの獲得済みリストを取得
        List<GotBadge> myBadges = gotBadgeRepository.findByUser(user);
        
        // 検索用にMap化 (Key: badgeId)
        Map<Long, GotBadge> myBadgeMap = myBadges.stream()
                .collect(Collectors.toMap(gb -> gb.getBadge().getId(), gb -> gb));

        List<BadgeDto> dtos = new ArrayList<>();

        for (Badge badge : activeBadges) {
            GotBadge acquired = myBadgeMap.get(badge.getId());
            boolean isEarned = (acquired != null);

            // 表示用情報を決定
            BadgeUiInfo ui = determineUiInfo(badge.getBadgeName());

            dtos.add(BadgeDto.builder()
                    .badgeId(badge.getId())
                    .title(badge.getBadgeName())
                    .description(badge.getAcquisitionCondition())
                    .category(ui.category)
                    .iconKey(ui.iconKey)
                    .colorCode(ui.colorCode)
                    .rarity(ui.rarity)
                    .progress(isEarned ? 1.0 : 0.0)
                    .acquiredDate(isEarned && acquired.getAcquired_at() != null
                            ? acquired.getAcquired_at().format(DateTimeFormatter.ISO_DATE) 
                            : null)
                    .build());
        }
        return dtos;
    }

    // ★追加: 文字列 -> DB数値の変換メソッド
    private Integer convertModeToInt(String modeStr) {
        if (modeStr == null) return null;
        switch (modeStr) {
            case "CONTINUE": return 1;
            case "BATTLE":   return 2;
            case "RANKING":  return 3;
            case "COLLECT":  return 4;
            case "SPECIAL":  return 5;
            default: return null; // "all" など
        }
    }

    private record BadgeUiInfo(String category, String iconKey, String colorCode, String rarity) {}

    private BadgeUiInfo determineUiInfo(String name) {
        if (name == null) name = "";
        
        if (name.contains("継続") || name.contains("ログイン") || name.contains("毎日")) {
            return new BadgeUiInfo("継続者", "trending_up", "green", "common");
        } else if (name.contains("バトル") || name.contains("勝") || name.contains("連勝")) {
            return new BadgeUiInfo("バトラー", "sports_esports", "red", "rare");
        } else if (name.contains("ランク") || name.contains("トップ") || name.contains("位") || name.contains("キング") || name.contains("王")) {
            return new BadgeUiInfo("ランカー", "leaderboard", "yellow", "epic");
        } else if (name.contains("アイテム") || name.contains("コレクター") || name.contains("集") || name.contains("ハンター") || name.contains("コンプ") || name.contains("交換") || name.contains("ギフト")) {
            return new BadgeUiInfo("獲得大王", "collections", "purple", "common");
        } else {
            return new BadgeUiInfo("スペシャル", "star", "grey", "common");
        }
    }
}