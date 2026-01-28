package com.example.api.dto.admin;

import java.time.LocalDateTime;
import java.util.List;

/**
 * 管理者用単語レスポンスDTO
 */
public class AdminVocabularyResponse {

    private Integer vocabId;
    private String word;
    private String baseForm;
    private String meaningJa;
    private String translationJa;
    private String pronunciation;
    private String partOfSpeech;
    private String exampleSentence;
    private String exampleTranslate;
    private String audioUrl;
    private String language;
    private Boolean isActive;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    public Integer getVocabId() { return vocabId; }
    public void setVocabId(Integer vocabId) { this.vocabId = vocabId; }
    public String getWord() { return word; }
    public void setWord(String word) { this.word = word; }
    public String getBaseForm() { return baseForm; }
    public void setBaseForm(String baseForm) { this.baseForm = baseForm; }
    public String getMeaningJa() { return meaningJa; }
    public void setMeaningJa(String meaningJa) { this.meaningJa = meaningJa; }
    public String getTranslationJa() { return translationJa; }
    public void setTranslationJa(String translationJa) { this.translationJa = translationJa; }
    public String getPronunciation() { return pronunciation; }
    public void setPronunciation(String pronunciation) { this.pronunciation = pronunciation; }
    public String getPartOfSpeech() { return partOfSpeech; }
    public void setPartOfSpeech(String partOfSpeech) { this.partOfSpeech = partOfSpeech; }
    public String getExampleSentence() { return exampleSentence; }
    public void setExampleSentence(String exampleSentence) { this.exampleSentence = exampleSentence; }
    public String getExampleTranslate() { return exampleTranslate; }
    public void setExampleTranslate(String exampleTranslate) { this.exampleTranslate = exampleTranslate; }
    public String getAudioUrl() { return audioUrl; }
    public void setAudioUrl(String audioUrl) { this.audioUrl = audioUrl; }
    public String getLanguage() { return language; }
    public void setLanguage(String language) { this.language = language; }
    public Boolean getIsActive() { return isActive; }
    public void setIsActive(Boolean isActive) { this.isActive = isActive; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }

    /**
     * ページング付きリスト用レスポンス
     */
    public static class ListResponse {
        private List<AdminVocabularyResponse> vocabularies;
        private int page;
        private int size;
        private long totalElements;
        private int totalPages;

        public ListResponse(List<AdminVocabularyResponse> vocabularies, int page, int size, long totalElements, int totalPages) {
            this.vocabularies = vocabularies;
            this.page = page;
            this.size = size;
            this.totalElements = totalElements;
            this.totalPages = totalPages;
        }

        public List<AdminVocabularyResponse> getVocabularies() { return vocabularies; }
        public int getPage() { return page; }
        public int getSize() { return size; }
        public long getTotalElements() { return totalElements; }
        public int getTotalPages() { return totalPages; }
    }
}
