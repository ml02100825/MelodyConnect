package com.example.api.client;

/**
 * Text-to-Speech API Client Interface
 * Google Cloud Text-to-Speechを使用して音声を生成
 */
public interface TextToSpeechClient {

    /**
     * テキストから音声を生成してURLを返す
     *
     * @param text       音声に変換するテキスト
     * @param language   言語コード（例: "en-US", "ja-JP", "ko-KR"）
     * @return 生成された音声ファイルのURL（S3などに保存後）、失敗時はnull
     */
    String generateSpeech(String text, String language);
}
