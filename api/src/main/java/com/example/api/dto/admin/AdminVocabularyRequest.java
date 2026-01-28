package com.example.api.dto.admin;

import jakarta.validation.constraints.NotBlank;

/**
 * 管理者用単語作成・更新リクエストDTO
 */
public class AdminVocabularyRequest {

    @NotBlank(message = "単語は必須です")
    private String word;

    private String baseForm;

    @NotBlank(message = "日本語意味は必須です")
    private String meaningJa;

    private String translationJa;
    private String pronunciation;
    private String partOfSpeech;
    private String exampleSentence;
    private String exampleTranslate;
    private String audioUrl;
    private String language;
    private Boolean isActive = true;

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
}
