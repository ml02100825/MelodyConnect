package com.example.api.dto;

import lombok.Builder;
import lombok.Data;

/**
 * Wordnik APIから取得した単語情報を保持するDTO
 */
@Data
@Builder
public class WordnikWordInfo {
    
    /**
     * 単語
     */
    private String word;
    
    /**
     * 日本語の意味
     */
    private String meaningJa;
    
    /**
     * 発音記号
     */
    private String pronunciation;
    
    /**
     * 品詞
     */
    private String partOfSpeech;
    
    /**
     * 例文
     */
    private String exampleSentence;
    
    /**
     * 例文の日本語訳
     */
    private String exampleTranslate;
    
    /**
     * 音声URL
     */
    private String audioUrl;
}