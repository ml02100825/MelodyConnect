package com.example.api.client;

import com.example.api.dto.ClaudeQuestionResponse;

/**
 * Claude API Client Interface
 * TODO: 実際のAPI統合時に実装を追加
 */
public interface ClaudeApiClient {

    /**
     * 歌詞から問題を生成
     *
     * @param lyrics             歌詞テキスト
     * @param fillInBlankCount   虫食い問題の生成数
     * @param listeningCount     リスニング問題の生成数
     * @return Claude APIからのレスポンス
     */
    ClaudeQuestionResponse generateQuestions(
        String lyrics,
        Integer fillInBlankCount,
        Integer listeningCount
    );
}
