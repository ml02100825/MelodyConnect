package com.example.api.dto;

import lombok.Builder;
import lombok.Data;
import java.time.LocalDateTime;
import java.util.List;

public class RankingDto {

    @Data
    @Builder
    public static class SeasonResponse {
        private List<Entry> entries;
        private boolean isActive;
        private LocalDateTime lastUpdated;
    }

    @Data
    @Builder
    public static class WeeklyResponse {
        private List<Entry> entries;
    }

    @Data
    @Builder
    public static class Entry {
        private int rank;
        private String name;
        private long rate;     // シーズンの場合はレート
        private long count;    // 週間の場合は回数
        private boolean isFriend;
        private boolean isMe;
        private String avatarUrl; // 任意: User entityのimageUrl
    }
}