package com.example.api.dto.battle;

/**
 * ラウンド結果レスポンス
 */
public class RoundResultResponse {
    private int roundNumber;
    private Integer questionId;
    private String correctAnswer;
    private Long roundWinnerId;
    private boolean isNoCount;
    private String noCountReason;

    // Player1の情報
    private Long player1Id;
    private String player1Answer;
    private boolean player1Correct;
    private long player1ResponseTimeMs;

    // Player2の情報
    private Long player2Id;
    private String player2Answer;
    private boolean player2Correct;
    private long player2ResponseTimeMs;

    // 現在のスコア
    private int player1Wins;
    private int player2Wins;

    // 試合継続フラグ
    private boolean matchContinues;

    public RoundResultResponse() {}

    // Getters and Setters
    public int getRoundNumber() { return roundNumber; }
    public void setRoundNumber(int roundNumber) { this.roundNumber = roundNumber; }

    public Integer getQuestionId() { return questionId; }
    public void setQuestionId(Integer questionId) { this.questionId = questionId; }

    public String getCorrectAnswer() { return correctAnswer; }
    public void setCorrectAnswer(String correctAnswer) { this.correctAnswer = correctAnswer; }

    public Long getRoundWinnerId() { return roundWinnerId; }
    public void setRoundWinnerId(Long roundWinnerId) { this.roundWinnerId = roundWinnerId; }

    public boolean isNoCount() { return isNoCount; }
    public void setNoCount(boolean noCount) { isNoCount = noCount; }

    public String getNoCountReason() { return noCountReason; }
    public void setNoCountReason(String noCountReason) { this.noCountReason = noCountReason; }

    public Long getPlayer1Id() { return player1Id; }
    public void setPlayer1Id(Long player1Id) { this.player1Id = player1Id; }

    public String getPlayer1Answer() { return player1Answer; }
    public void setPlayer1Answer(String player1Answer) { this.player1Answer = player1Answer; }

    public boolean isPlayer1Correct() { return player1Correct; }
    public void setPlayer1Correct(boolean player1Correct) { this.player1Correct = player1Correct; }

    public long getPlayer1ResponseTimeMs() { return player1ResponseTimeMs; }
    public void setPlayer1ResponseTimeMs(long player1ResponseTimeMs) { this.player1ResponseTimeMs = player1ResponseTimeMs; }

    public Long getPlayer2Id() { return player2Id; }
    public void setPlayer2Id(Long player2Id) { this.player2Id = player2Id; }

    public String getPlayer2Answer() { return player2Answer; }
    public void setPlayer2Answer(String player2Answer) { this.player2Answer = player2Answer; }

    public boolean isPlayer2Correct() { return player2Correct; }
    public void setPlayer2Correct(boolean player2Correct) { this.player2Correct = player2Correct; }

    public long getPlayer2ResponseTimeMs() { return player2ResponseTimeMs; }
    public void setPlayer2ResponseTimeMs(long player2ResponseTimeMs) { this.player2ResponseTimeMs = player2ResponseTimeMs; }

    public int getPlayer1Wins() { return player1Wins; }
    public void setPlayer1Wins(int player1Wins) { this.player1Wins = player1Wins; }

    public int getPlayer2Wins() { return player2Wins; }
    public void setPlayer2Wins(int player2Wins) { this.player2Wins = player2Wins; }

    public boolean isMatchContinues() { return matchContinues; }
    public void setMatchContinues(boolean matchContinues) { this.matchContinues = matchContinues; }
}
