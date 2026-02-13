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
     * @param sourceLanguage 歌詞の原語コード（"ja", "en" 等。null の場合は targetLanguage と同一とみなす）
     * @param targetLanguage ユーザーの学習言語コード（"en", "ko" 等）
     * @param fillInBlankCount 穴埋め問題の数
     * @param listeningCount リスニング問題の数
     * @return 生成された問題
     */
    ClaudeQuestionResponse generateQuestions(
        String lyrics,
        String sourceLanguage,
        String targetLanguage,
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

    /**
     * 単語の原形を取得
     * 例: memories → memory, running → run, bigger → big
     *
     * @param word 変換対象の単語
     * @return 原形（変換できない場合は元の単語）
     */
    String getBaseForm(String word);

    /**
     * 単語の簡潔な日本語訳を取得
     * 例: important → "重要な", beautiful → "美しい"
     *
     * @param word 翻訳対象の単語（原形推奨）
     * @return 簡潔な日本語訳（一言〜数語）
     */
    String getSimpleTranslation(String word);

    /**
     * 単語の原形と簡潔な日本語訳を一度に取得
     * API呼び出し回数を削減するための一括処理
     *
     * @param word 変換対象の単語
     * @return [0]: 原形, [1]: 簡潔な日本語訳
     */
    String[] getBaseFormAndTranslation(String word);
}