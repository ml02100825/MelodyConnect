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
     * 単語（そのままの形）
     */
    private String word;
    
    /**
     * 原形（lemma）
     * 例: memories → memory, running → run
     */
    private String baseForm;
    
    /**
     * 詳細な日本語の意味（辞書的な説明）
     */
    private String meaningJa;
    
    /**
     * 簡潔な日本語訳（一言訳）
     * 例: important → "重要な"
     */
    private String translationJa;
    
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
