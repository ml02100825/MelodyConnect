package com.example.api.dto.battle;

/**
 * 問題レスポンス（クライアントに送信する問題情報）
 */
public class QuestionResponse {
    private Integer questionId;
    private String text;
    private String questionFormat;
    private String audioUrl;
    private String translationJa;
    private int roundNumber;
    private int totalRounds;
    private long roundTimeLimitMs;

    public QuestionResponse() {}

    public QuestionResponse(Integer questionId, String text, String questionFormat,
                           String audioUrl, String translationJa,
                           int roundNumber, int totalRounds, long roundTimeLimitMs) {
        this.questionId = questionId;
        this.text = text;
        this.questionFormat = questionFormat;
        this.audioUrl = audioUrl;
        this.translationJa = translationJa;
        this.roundNumber = roundNumber;
        this.totalRounds = totalRounds;
        this.roundTimeLimitMs = roundTimeLimitMs;
    }

    // Getters and Setters
    public Integer getQuestionId() { return questionId; }
    public void setQuestionId(Integer questionId) { this.questionId = questionId; }

    public String getText() { return text; }
    public void setText(String text) { this.text = text; }

    public String getQuestionFormat() { return questionFormat; }
    public void setQuestionFormat(String questionFormat) { this.questionFormat = questionFormat; }

    public String getAudioUrl() { return audioUrl; }
    public void setAudioUrl(String audioUrl) { this.audioUrl = audioUrl; }

    public String getTranslationJa() { return translationJa; }
    public void setTranslationJa(String translationJa) { this.translationJa = translationJa; }

    public int getRoundNumber() { return roundNumber; }
    public void setRoundNumber(int roundNumber) { this.roundNumber = roundNumber; }

    public int getTotalRounds() { return totalRounds; }
    public void setTotalRounds(int totalRounds) { this.totalRounds = totalRounds; }

    public long getRoundTimeLimitMs() { return roundTimeLimitMs; }
    public void setRoundTimeLimitMs(long roundTimeLimitMs) { this.roundTimeLimitMs = roundTimeLimitMs; }
}
