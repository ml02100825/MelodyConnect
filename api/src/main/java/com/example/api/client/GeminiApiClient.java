package com.example.api.client;

import com.example.api.dto.ClaudeQuestionResponse;

/**
 * Gemini API Client Interface
 * Google Gemini APIを使用して問題を生成
 */
public interface GeminiApiClient {

    /**
     * 歌詞から問題を生成
     *
     * @param lyrics             歌詞テキスト
     * @param language           言語コード（en, ko）
     * @param fillInBlankCount   虫食い問題の生成数
     * @param listeningCount     リスニング問題の生成数
     * @return 生成された問題のレスポンス
     */
    ClaudeQuestionResponse generateQuestions(
        String lyrics,
        String language,
        Integer fillInBlankCount,
        Integer listeningCount
    );
}
