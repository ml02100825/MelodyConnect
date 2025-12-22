package com.example.api.dto.battle;

/**
 * バトル開始レスポンスDTO
 * Controller層でLazy Entityを直接参照しないようにするためのDTO
 */
public class BattleStartResponseDto {
    private String matchId;
    private Long user1Id;
    private Long user2Id;
    private String language;
    private int questionCount;
    private int roundTimeLimitSeconds;
    private int winsRequired;
    private int maxRounds;
    private String status;
    private String message;
    private PlayerInfoDto user1Info;
    private PlayerInfoDto user2Info;

    public BattleStartResponseDto() {
    }

    // Builder pattern for convenience
    public static Builder builder() {
        return new Builder();
    }

    public static class Builder {
        private final BattleStartResponseDto dto = new BattleStartResponseDto();

        public Builder matchId(String matchId) {
            dto.matchId = matchId;
            return this;
        }

        public Builder user1Id(Long user1Id) {
            dto.user1Id = user1Id;
            return this;
        }

        public Builder user2Id(Long user2Id) {
            dto.user2Id = user2Id;
            return this;
        }

        public Builder language(String language) {
            dto.language = language;
            return this;
        }

        public Builder questionCount(int questionCount) {
            dto.questionCount = questionCount;
            return this;
        }

        public Builder roundTimeLimitSeconds(int roundTimeLimitSeconds) {
            dto.roundTimeLimitSeconds = roundTimeLimitSeconds;
            return this;
        }

        public Builder winsRequired(int winsRequired) {
            dto.winsRequired = winsRequired;
            return this;
        }

        public Builder maxRounds(int maxRounds) {
            dto.maxRounds = maxRounds;
            return this;
        }

        public Builder status(String status) {
            dto.status = status;
            return this;
        }

        public Builder message(String message) {
            dto.message = message;
            return this;
        }

        public Builder user1Info(PlayerInfoDto user1Info) {
            dto.user1Info = user1Info;
            return this;
        }

        public Builder user2Info(PlayerInfoDto user2Info) {
            dto.user2Info = user2Info;
            return this;
        }

        public BattleStartResponseDto build() {
            return dto;
        }
    }

    // Getters and Setters
    public String getMatchId() {
        return matchId;
    }

    public void setMatchId(String matchId) {
        this.matchId = matchId;
    }

    public Long getUser1Id() {
        return user1Id;
    }

    public void setUser1Id(Long user1Id) {
        this.user1Id = user1Id;
    }

    public Long getUser2Id() {
        return user2Id;
    }

    public void setUser2Id(Long user2Id) {
        this.user2Id = user2Id;
    }

    public String getLanguage() {
        return language;
    }

    public void setLanguage(String language) {
        this.language = language;
    }

    public int getQuestionCount() {
        return questionCount;
    }

    public void setQuestionCount(int questionCount) {
        this.questionCount = questionCount;
    }

    public int getRoundTimeLimitSeconds() {
        return roundTimeLimitSeconds;
    }

    public void setRoundTimeLimitSeconds(int roundTimeLimitSeconds) {
        this.roundTimeLimitSeconds = roundTimeLimitSeconds;
    }

    public int getWinsRequired() {
        return winsRequired;
    }

    public void setWinsRequired(int winsRequired) {
        this.winsRequired = winsRequired;
    }

    public int getMaxRounds() {
        return maxRounds;
    }

    public void setMaxRounds(int maxRounds) {
        this.maxRounds = maxRounds;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public PlayerInfoDto getUser1Info() {
        return user1Info;
    }

    public void setUser1Info(PlayerInfoDto user1Info) {
        this.user1Info = user1Info;
    }

    public PlayerInfoDto getUser2Info() {
        return user2Info;
    }

    public void setUser2Info(PlayerInfoDto user2Info) {
        this.user2Info = user2Info;
    }
}
