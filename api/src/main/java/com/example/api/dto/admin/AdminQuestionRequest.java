package com.example.api.dto.admin;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

/**
 * 管理者用問題作成・更新リクエストDTO
 */
public class AdminQuestionRequest {

    @NotNull(message = "楽曲IDは必須です")
    private Long songId;

    @NotNull(message = "アーティストIDは必須です")
    private Long artistId;

    @NotBlank(message = "問題文は必須です")
    private String text;

    @NotBlank(message = "答えは必須です")
    private String answer;

    private String completeSentence;

    @NotBlank(message = "問題形式は必須です")
    private String questionFormat;

    private Integer difficultyLevel;
    private String language;
    private String translationJa;
    private String audioUrl;
    private Boolean isActive = true;

    public Long getSongId() { return songId; }
    public void setSongId(Long songId) { this.songId = songId; }
    public Long getArtistId() { return artistId; }
    public void setArtistId(Long artistId) { this.artistId = artistId; }
    public String getText() { return text; }
    public void setText(String text) { this.text = text; }
    public String getAnswer() { return answer; }
    public void setAnswer(String answer) { this.answer = answer; }
    public String getCompleteSentence() { return completeSentence; }
    public void setCompleteSentence(String completeSentence) { this.completeSentence = completeSentence; }
    public String getQuestionFormat() { return questionFormat; }
    public void setQuestionFormat(String questionFormat) { this.questionFormat = questionFormat; }
    public Integer getDifficultyLevel() { return difficultyLevel; }
    public void setDifficultyLevel(Integer difficultyLevel) { this.difficultyLevel = difficultyLevel; }
    public String getLanguage() { return language; }
    public void setLanguage(String language) { this.language = language; }
    public String getTranslationJa() { return translationJa; }
    public void setTranslationJa(String translationJa) { this.translationJa = translationJa; }
    public String getAudioUrl() { return audioUrl; }
    public void setAudioUrl(String audioUrl) { this.audioUrl = audioUrl; }
    public Boolean getIsActive() { return isActive; }
    public void setIsActive(Boolean isActive) { this.isActive = isActive; }
}
