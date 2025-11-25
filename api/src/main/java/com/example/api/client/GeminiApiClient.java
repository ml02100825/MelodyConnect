package com.example.api.client;

import com.example.api.dto.ClaudeQuestionResponse;

/**
 * Gemini API Client Interface
 * 問題生成と翻訳機能を提供
 */
public interface GeminiApiClient {

    /**
     * 歌詞から言語学習問題を生成
     *
     * @param lyrics 歌詞
     * @param language 対象言語
     * @param fillInBlankCount 穴埋め問題の数
     * @param listeningCount リスニング問題の数
     * @return 生成された問題
     */
    ClaudeQuestionResponse generateQuestions(
        String lyrics,
        String language,
        Integer fillInBlankCount,
        Integer listeningCount
    );

    /**
     * テキストを日本語に翻訳
     *
     * @param text 翻訳するテキスト
     * @param sourceLanguage 元の言語（例: "English"）
     * @return 日本語訳
     */
    String translateToJapanese(String text, String sourceLanguage);
}