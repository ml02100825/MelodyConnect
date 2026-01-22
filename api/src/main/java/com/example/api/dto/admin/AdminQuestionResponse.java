package com.example.api.dto.admin;

import java.time.LocalDateTime;
import java.util.List;

/**
 * 管理者用問題レスポンスDTO
 */
public class AdminQuestionResponse {

    private Integer questionId;
    private Long songId;
    private String songName;
    private Long artistId;
    private String artistName;
    private String text;
    private String answer;
    private String completeSentence;
    private String questionFormat;
    private Integer difficultyLevel;
    private String language;
    private String translationJa;
    private String audioUrl;
    private Boolean isActive;
    private LocalDateTime addingAt;

    // Getters and Setters
    public Integer getQuestionId() { return questionId; }
    public void setQuestionId(Integer questionId) { this.questionId = questionId; }
    public Long getSongId() { return songId; }
    public void setSongId(Long songId) { this.songId = songId; }
    public String getSongName() { return songName; }
    public void setSongName(String songName) { this.songName = songName; }
    public Long getArtistId() { return artistId; }
    public void setArtistId(Long artistId) { this.artistId = artistId; }
    public String getArtistName() { return artistName; }
    public void setArtistName(String artistName) { this.artistName = artistName; }
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
    public LocalDateTime getAddingAt() { return addingAt; }
    public void setAddingAt(LocalDateTime addingAt) { this.addingAt = addingAt; }

    public static class ListResponse {
        private List<AdminQuestionResponse> questions;
        private int page;
        private int size;
        private long totalElements;
        private int totalPages;

        public ListResponse(List<AdminQuestionResponse> questions, int page, int size, long totalElements, int totalPages) {
            this.questions = questions;
            this.page = page;
            this.size = size;
            this.totalElements = totalElements;
            this.totalPages = totalPages;
        }

        public List<AdminQuestionResponse> getQuestions() { return questions; }
        public int getPage() { return page; }
        public int getSize() { return size; }
        public long getTotalElements() { return totalElements; }
        public int getTotalPages() { return totalPages; }
    }
}
