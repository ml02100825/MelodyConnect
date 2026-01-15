package com.example.api.service;

import com.example.api.dto.RankingEntryDto;
import com.example.api.dto.SeasonRankingResponse;
import com.example.api.dto.WeeklyRankingResponse;
import com.example.api.dto.UserRanking;
import com.example.api.entity.Season;
import com.example.api.entity.WeeklyLessons;
import com.example.api.repository.FriendRepository;
import com.example.api.repository.SeasonRepository;
import com.example.api.repository.UserRankingRepository;
import com.example.api.repository.UserRateRepository;
import com.example.api.repository.WeeklyLessonsRepository;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;

/**
 * RankingService
 * rate（user_rates）テーブルを唯一の正としてランキングを生成
 */
@Service
public class RankingService {

    private final FriendRepository friendRepository;
    private final UserRankingRepository userRankingRepository;
    private final SeasonRepository seasonRepository;
    private final UserRateRepository userRateRepository;
    private final WeeklyLessonsRepository weeklyLessonsRepository;

    public RankingService(
            FriendRepository friendRepository,
            UserRankingRepository userRankingRepository,
            SeasonRepository seasonRepository,
            UserRateRepository userRateRepository,
            WeeklyLessonsRepository weeklyLessonsRepository
    ) {
        this.friendRepository = friendRepository;
        this.userRankingRepository = userRankingRepository;
        this.seasonRepository = seasonRepository;
        this.userRateRepository = userRateRepository;
        this.weeklyLessonsRepository = weeklyLessonsRepository;
    }

    @Transactional(readOnly = true)
    public SeasonRankingResponse getSeasonRanking(
            String seasonName,
            int limit,
            Long currentUserId,
            boolean friendsOnly
    ) {
        Season season = seasonRepository.findByName(seasonName)
                .orElseThrow(() -> new RuntimeException("season not found"));

        // ★ rate テーブルから直接取得
        List<Object[]> rows =
                userRateRepository.findSeasonRanking(season.getId());

        // userId 収集
        Set<Long> userIds = new HashSet<>();
        for (Object[] r : rows) {
            userIds.add(((Number) r[0]).longValue());
        }

        // 名前取得
        Map<Long, String> nameMap = new HashMap<>();
        if (!userIds.isEmpty()) {
            for (UserRanking u : userRankingRepository.findByUserIdIn(userIds)) {
                nameMap.put(u.getUserId(), u.getUsername());
            }
        }

        // フレンド制限
        Set<Long> friendSet = Collections.emptySet();
        if (friendsOnly && currentUserId != null) {
            friendSet = new HashSet<>(
                    friendRepository.findAcceptedFriendIdsByUserId(currentUserId)
            );
            friendSet.add(currentUserId);
        }

        // エントリー生成
        List<RankingEntryDto> entries = new ArrayList<>();
        int rank = 1;

        for (Object[] r : rows) {
            Long userId = ((Number) r[0]).longValue();
            Integer rate = ((Number) r[1]).intValue();

            if (friendsOnly && !friendSet.contains(userId)) continue;

            RankingEntryDto dto = new RankingEntryDto();
            dto.setRank(rank++);
            dto.setUserId(userId);
            dto.setName(nameMap.getOrDefault(userId, "User" + userId));
            dto.setRate(rate); // ★ setRate に変更（RankingEntryDto に合わせる）
            dto.setMe(currentUserId != null && currentUserId.equals(userId));
            dto.setFriend(
                    currentUserId != null &&
                    friendSet.contains(userId) &&
                    !dto.isMe()
            );

            entries.add(dto);
            if (entries.size() >= limit) break;
        }

        SeasonRankingResponse res = new SeasonRankingResponse();
        res.setSeason(seasonName);
        res.setActive(season.isActive());
        res.setEntries(entries);

        // 自分の順位（全体基準）
        if (currentUserId != null) {
            int myRank = -1;
            int r = 1;
            for (Object[] row : rows) {
                if (((Number) row[0]).longValue() == currentUserId.longValue()) {
                    myRank = r;
                    break;
                }
                r++;
            }
            res.setMyRank(myRank);
        }

        return res;
    }

    @Transactional(readOnly = true)
    public WeeklyRankingResponse getWeeklyRanking(
            Integer weekFlag,
            int limit,
            Long currentUserId,
            boolean friendsOnly
    ) {
        // weekFlag が null の場合は最新週を取得
        if (weekFlag == null) {
            weekFlag = weeklyLessonsRepository.findLatestWeekFlag();
            if (weekFlag == null) {
                WeeklyRankingResponse empty = new WeeklyRankingResponse();
                empty.setEntries(List.of());
                empty.setMyRank(-1);
                return empty;
            }
        }

        // 指定された週のレッスンデータを取得
        List<WeeklyLessons> list = weeklyLessonsRepository
                .findByWeekFlagOrderByLessonsNumDesc(weekFlag, PageRequest.of(0, 1000));

        // userId 収集
        Set<Long> userIds = new HashSet<>();
        for (WeeklyLessons wl : list) {
            if (wl.getUser() != null && wl.getUser().getId() != null) {
                userIds.add(wl.getUser().getId());
            }
        }

        // 名前取得
        Map<Long, String> nameMap = new HashMap<>();
        if (!userIds.isEmpty()) {
            for (UserRanking u : userRankingRepository.findByUserIdIn(userIds)) {
                nameMap.put(u.getUserId(), u.getUsername());
            }
        }

        // フレンド制限
        Set<Long> friendSet = Collections.emptySet();
        if (friendsOnly && currentUserId != null) {
            friendSet = new HashSet<>(
                    friendRepository.findAcceptedFriendIdsByUserId(currentUserId)
            );
            friendSet.add(currentUserId);
        }

        // エントリー生成
        List<RankingEntryDto> entries = new ArrayList<>();
        int rank = 1;

        for (WeeklyLessons wl : list) {
            Long userId = wl.getUser() != null ? wl.getUser().getId() : null;
            if (userId == null) continue;

            if (friendsOnly && !friendSet.contains(userId)) continue;

            RankingEntryDto dto = new RankingEntryDto();
            dto.setRank(rank++);
            dto.setUserId(userId);
            dto.setName(nameMap.getOrDefault(userId, "User" + userId));
            dto.setRate(wl.getLessonsNum() != null ? wl.getLessonsNum() : 0);
            dto.setMe(currentUserId != null && currentUserId.equals(userId));
            dto.setFriend(
                    currentUserId != null &&
                    friendSet.contains(userId) &&
                    !dto.isMe()
            );

            entries.add(dto);
            if (entries.size() >= limit) break;
        }

        WeeklyRankingResponse res = new WeeklyRankingResponse();
        res.setEntries(entries);

        // 自分の順位（全体基準）
        if (currentUserId != null) {
            int myRank = -1;
            int r = 1;
            for (WeeklyLessons wl : list) {
                Long userId = wl.getUser() != null ? wl.getUser().getId() : null;
                if (userId != null && userId.equals(currentUserId)) {
                    myRank = r;
                    break;
                }
                r++;
            }
            res.setMyRank(myRank);
        }

        return res;
    }
}