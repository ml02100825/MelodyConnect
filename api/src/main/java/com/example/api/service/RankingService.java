package com.example.api.service;

import com.example.api.dto.RankingDto;
import com.example.api.entity.Rate;
import com.example.api.entity.User;
import com.example.api.repository.FriendRepository;
import com.example.api.repository.RateRepository;
import com.example.api.repository.WeeklyLessonsRepository;
import com.example.api.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@Service
@RequiredArgsConstructor
public class RankingService {

    private final RateRepository rateRepository;
    private final WeeklyLessonsRepository weeklyLessonsRepository;
    private final FriendRepository friendRepository;
    private final UserRepository userRepository;
    private final BadgeGrantService badgeGrantService;

    // Rateテーブルの実データに基づいてシーズンリストを作成
    @Transactional(readOnly = true)
    public List<String> getAvailableSeasons() {
        List<Integer> seasons = rateRepository.findDistinctSeasons();
        if (seasons.isEmpty()) return List.of("シーズン1");
        List<String> formattedSeasons = new ArrayList<>();
        for (Integer s : seasons) formattedSeasons.add("シーズン" + s);
        return formattedSeasons;
    }

    @Transactional(readOnly = true)
    public RankingDto.SeasonResponse getSeasonRanking(String seasonName, int limit, Long currentUserId, boolean friendsOnly) {
        Integer seasonInt = parseSeason(seasonName);
        Set<Long> friendIds = friendRepository.findFriendUserIds(currentUserId);
        
        List<Rate> rates;
        Pageable pageable = PageRequest.of(0, limit);

        if (friendsOnly) {
            List<Long> targetIds = new ArrayList<>(friendIds);
            targetIds.add(currentUserId);
            rates = rateRepository.findFriendRankingBySeason(seasonInt, targetIds, pageable);
        } else {
            rates = rateRepository.findRankingBySeason(seasonInt, pageable);
        }

        List<RankingDto.Entry> entries = new ArrayList<>();
        int rank = 1;
        for (Rate r : rates) {
            entries.add(RankingDto.Entry.builder()
                    .rank(rank++)
                    .name(r.getUser().getUsername())
                    .rate(r.getRate())
                    .isMe(r.getUser().getId().equals(currentUserId))
                    .isFriend(friendIds.contains(r.getUser().getId()))
                    .avatarUrl(r.getUser().getImageUrl())
                    .build());
        }
        return RankingDto.SeasonResponse.builder()
                .entries(entries)
                .isActive(true)
                .lastUpdated(LocalDateTime.now())
                .build();
    }

    // ★修正: weekFlag=true のレコードだけを集計してランキング化
    @Transactional(readOnly = true)
    public RankingDto.WeeklyResponse getWeeklyRanking(LocalDateTime weekStart, int limit, Long currentUserId, boolean friendsOnly) {

        Set<Long> friendIds = friendRepository.findFriendUserIds(currentUserId);
        Pageable pageable = PageRequest.of(0, limit);

        List<Object[]> results;

        if (friendsOnly) {
            List<Long> targetIds = new ArrayList<>(friendIds);
            targetIds.add(currentUserId);
            // weekFlag=true を検索
            results = weeklyLessonsRepository.findCurrentFriendWeeklyRanking(targetIds, pageable);
        } else {
            // weekFlag=true を検索
            results = weeklyLessonsRepository.findCurrentWeeklyRanking(pageable);
        }

        List<RankingDto.Entry> entries = new ArrayList<>();
        int rank = 1;

        for (Object[] row : results) {
            User user = (User) row[0];
            Long totalLessons = (Long) row[1];

            entries.add(RankingDto.Entry.builder()
                    .rank(rank++)
                    .name(user.getUsername())
                    .count(totalLessons != null ? totalLessons : 0)
                    .isMe(user.getId().equals(currentUserId))
                    .isFriend(friendIds.contains(user.getId()))
                    .avatarUrl(user.getImageUrl())
                    .build());
        }

        return RankingDto.WeeklyResponse.builder()
                .entries(entries)
                .build();
    }

    /**
     * ランキング画面が開かれたときのバッジ一括チェック処理
     */
    @Transactional
    public void processRankingAccess(Long userId) {
        User user = userRepository.findById(userId).orElse(null);
        if (user == null) return;

        // 1. 【テスト用】ランキング画面を見ただけで即ゲット
        badgeGrantService.grantBadgeByName(userId, "【テスト】ランク確認");
        badgeGrantService.grantBadgeByName(userId, "ランク入り"); // サンプルとして付与

        // 2. ログイン回数による判定 (Userエンティティの値を使用)
        int loginCount = user.getLoginCount() != null ? user.getLoginCount() : 0;
        
        badgeGrantService.grantBadgeByName(userId, "【テスト】継続ログイン"); // テスト用
        
        if (loginCount >= 10) badgeGrantService.grantBadgeByName(userId, "継続者Ⅰ");
        if (loginCount >= 30) badgeGrantService.grantBadgeByName(userId, "継続者Ⅱ");
        if (loginCount >= 30) badgeGrantService.grantBadgeByName(userId, "毎日コツコツ"); // 簡易判定

        // 3. プレイ回数による判定
        int totalPlay = user.getTotalPlay();
        if (totalPlay >= 1) {
            badgeGrantService.grantBadgeByName(userId, "【テスト】バトル参加");
            badgeGrantService.grantBadgeByName(userId, "バトル初心者");
        }
        if (totalPlay >= 100) badgeGrantService.grantBadgeByName(userId, "バトルマスター");
    }

    private Integer parseSeason(String seasonName) {
        if (seasonName == null) return 3;
        Matcher m = Pattern.compile(".*?(\\d+)").matcher(seasonName);
        if (m.find()) {
            try {
                return Integer.parseInt(m.group(1));
            } catch (NumberFormatException e) {
                return 3;
            }
        }
        return 3;
    }
}