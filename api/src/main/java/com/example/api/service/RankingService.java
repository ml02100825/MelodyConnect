package com.example.api.service;

import com.example.api.dto.RankingDto;
import com.example.api.entity.Rate;
import com.example.api.entity.User;
import com.example.api.repository.FriendRepository;
import com.example.api.repository.RateRepository;
import com.example.api.repository.WeeklyLessonsRepository;
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

    /**
     * シーズンランキングを取得
     */
    @Transactional(readOnly = true)
    public RankingDto.SeasonResponse getSeasonRanking(String seasonName, int limit, Long currentUserId, boolean friendsOnly) {
        
        Integer seasonInt = parseSeason(seasonName);
        Set<Long> friendIds = friendRepository.findFriendUserIds(currentUserId);
        
        List<Rate> rates;
        Pageable pageable = PageRequest.of(0, limit);

        if (friendsOnly) {
            List<Long> targetIds = new ArrayList<>(friendIds);
            targetIds.add(currentUserId);
            // フレンド限定（自分含む）
            rates = rateRepository.findFriendRankingBySeason(seasonInt, targetIds, pageable);
        } else {
            // 全体
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

        // シーズン3を仮のアクティブシーズンとする
        boolean isActive = (seasonInt == 3); 

        return RankingDto.SeasonResponse.builder()
                .entries(entries)
                .isActive(isActive)
                .lastUpdated(LocalDateTime.now())
                .build();
    }

    /**
     * 週間ランキングを取得
     * (日付範囲ではなく、DB上の weekFlag=true のデータを集計します)
     */
    @Transactional(readOnly = true)
    public RankingDto.WeeklyResponse getWeeklyRanking(LocalDateTime weekStart, int limit, Long currentUserId, boolean friendsOnly) {
        
        Set<Long> friendIds = friendRepository.findFriendUserIds(currentUserId);
        Pageable pageable = PageRequest.of(0, limit);

        List<Object[]> results;

        if (friendsOnly) {
            List<Long> targetIds = new ArrayList<>(friendIds);
            targetIds.add(currentUserId);
            // フレンド + 自分 の weekFlag=true を検索
            results = weeklyLessonsRepository.findCurrentFriendWeeklyRanking(targetIds, pageable);
        } else {
            // 全体の weekFlag=true を検索
            results = weeklyLessonsRepository.findCurrentWeeklyRanking(pageable);
        }

        List<RankingDto.Entry> entries = new ArrayList<>();
        int rank = 1;

        for (Object[] row : results) {
            User user = (User) row[0];
            Long totalLessons = (Long) row[1]; // SUMの結果

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

    // "シーズンX" から数値を抽出するヘルパー
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