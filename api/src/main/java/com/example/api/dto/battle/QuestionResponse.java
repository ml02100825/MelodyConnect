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
    private String songName;
    private String artistName;
    private int roundNumber;
    private int totalRounds;
    private long roundTimeLimitMs;
    private long roundStartTimestamp;
    private String sourceFragment;

    public QuestionResponse() {}

    public QuestionResponse(Integer questionId, String text, String questionFormat,
                           String audioUrl, String translationJa,
                           String songName, String artistName,
                           int roundNumber, int totalRounds, long roundTimeLimitMs,
                           long roundStartTimestamp, String sourceFragment) {
        this.questionId = questionId;
        this.text = text;
        this.questionFormat = questionFormat;
        this.audioUrl = audioUrl;
        this.translationJa = translationJa;
        this.songName = songName;
        this.artistName = artistName;
        this.roundNumber = roundNumber;
        this.totalRounds = totalRounds;
        this.roundTimeLimitMs = roundTimeLimitMs;
        this.roundStartTimestamp = roundStartTimestamp;
        this.sourceFragment = sourceFragment;
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

    public String getSongName() { return songName; }
    public void setSongName(String songName) { this.songName = songName; }

    public String getArtistName() { return artistName; }
    public void setArtistName(String artistName) { this.artistName = artistName; }

    public int getRoundNumber() { return roundNumber; }
    public void setRoundNumber(int roundNumber) { this.roundNumber = roundNumber; }

    public int getTotalRounds() { return totalRounds; }
    public void setTotalRounds(int totalRounds) { this.totalRounds = totalRounds; }

    public long getRoundTimeLimitMs() { return roundTimeLimitMs; }
    public void setRoundTimeLimitMs(long roundTimeLimitMs) { this.roundTimeLimitMs = roundTimeLimitMs; }

    public long getRoundStartTimestamp() { return roundStartTimestamp; }
    public void setRoundStartTimestamp(long roundStartTimestamp) { this.roundStartTimestamp = roundStartTimestamp; }

    public String getSourceFragment() { return sourceFragment; }
    public void setSourceFragment(String sourceFragment) { this.sourceFragment = sourceFragment; }
}
