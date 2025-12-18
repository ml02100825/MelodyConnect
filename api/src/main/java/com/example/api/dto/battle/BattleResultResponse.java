package com.example.api.dto.battle;

import java.util.List;

/**
 * 試合結果レスポンス（リザルト画面用）
 */
public class BattleResultResponse {
    private String matchUuid;
    private String result;          // "win", "lose", "draw"
    private String outcomeReason;   // "normal", "surrender", "timeout", "disconnect"

    private Long myId;
    private Long opponentId;
    private int myScore;
    private int opponentScore;
    private int rateChange;
    private int newRate;

    private List<RoundResultResponse> rounds;

    public BattleResultResponse() {}

    // Getters and Setters
    public String getMatchUuid() { return matchUuid; }
    public void setMatchUuid(String matchUuid) { this.matchUuid = matchUuid; }

    public String getResult() { return result; }
    public void setResult(String result) { this.result = result; }

    public String getOutcomeReason() { return outcomeReason; }
    public void setOutcomeReason(String outcomeReason) { this.outcomeReason = outcomeReason; }

    public Long getMyId() { return myId; }
    public void setMyId(Long myId) { this.myId = myId; }

    public Long getOpponentId() { return opponentId; }
    public void setOpponentId(Long opponentId) { this.opponentId = opponentId; }

    public int getMyScore() { return myScore; }
    public void setMyScore(int myScore) { this.myScore = myScore; }

    public int getOpponentScore() { return opponentScore; }
    public void setOpponentScore(int opponentScore) { this.opponentScore = opponentScore; }

    public int getRateChange() { return rateChange; }
    public void setRateChange(int rateChange) { this.rateChange = rateChange; }

    public int getNewRate() { return newRate; }
    public void setNewRate(int newRate) { this.newRate = newRate; }

    public List<RoundResultResponse> getRounds() { return rounds; }
    public void setRounds(List<RoundResultResponse> rounds) { this.rounds = rounds; }
}
