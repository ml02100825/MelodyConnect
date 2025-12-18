package com.example.api.dto.battle;

/**
 * 降参リクエスト
 */
public class SurrenderRequest {
    private String matchId;
    private Long userId;

    public String getMatchId() { return matchId; }
    public void setMatchId(String matchId) { this.matchId = matchId; }

    public Long getUserId() { return userId; }
    public void setUserId(Long userId) { this.userId = userId; }
}
