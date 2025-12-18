package com.example.api.dto.battle;

/**
 * 回答リクエスト
 */
public class AnswerRequest {
    private String matchId;
    private Long userId;
    private String answer;

    public String getMatchId() { return matchId; }
    public void setMatchId(String matchId) { this.matchId = matchId; }

    public Long getUserId() { return userId; }
    public void setUserId(Long userId) { this.userId = userId; }

    public String getAnswer() { return answer; }
    public void setAnswer(String answer) { this.answer = answer; }
}
