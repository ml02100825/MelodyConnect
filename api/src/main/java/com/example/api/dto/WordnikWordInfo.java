package com.example.api.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * Wordnik APIからの単語情報DTO
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class WordnikWordInfo {

    /**
     * 単語
     */
    private String word;

    /**
     * 意味（日本語訳）
     * ※Wordnik APIは英語のみなので、翻訳APIとの組み合わせが必要
     */
    private String meaningJa;

    /**
     * 発音
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
     * 例文の翻訳
     */
    private String exampleTranslate;

    /**
     * 音声URL
     */
    private String audioUrl;

    /**
     * 定義リスト
     */
    private List<Definition> definitions;

    /**
     * 定義情報
     */
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class Definition {
        private String text;
        private String partOfSpeech;
        private String source;
    }
}
