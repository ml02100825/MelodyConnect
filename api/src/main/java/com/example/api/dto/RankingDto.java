package com.example.api.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Builder;
import lombok.Data;
import java.time.LocalDateTime;
import java.util.List;

public class RankingDto {

    @Data
    @Builder
    public static class SeasonResponse {
        private List<Entry> entries;
        @JsonProperty("isActive")
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
        @JsonProperty("isFriend")
        private boolean isFriend;
        @JsonProperty("isMe")
        private boolean isMe;
        private String avatarUrl; // 任意: User entityのimageUrl
    }
}