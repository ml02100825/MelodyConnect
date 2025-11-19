package com.example.api.client;

/**
 * TTS (Text-to-Speech) API Client Interface
 * リスニング問題用の音声を生成します
 */
public interface TtsApiClient {

    /**
     * テキストから音声を生成
     *
     * @param text 読み上げるテキスト
     * @param language 言語コード (例: "en-US")
     * @return 音声ファイルのURL
     */
    String generateAudio(String text, String language);

    /**
     * テキストから音声を生成（詳細設定）
     *
     * @param text 読み上げるテキスト
     * @param language 言語コード
     * @param voiceGender 音声の性別 ("MALE", "FEMALE", "NEUTRAL")
     * @param speakingRate 話す速度 (0.25 - 4.0, 1.0が標準)
     * @return 音声ファイルのURL
     */
    String generateAudio(String text, String language, String voiceGender, double speakingRate);
}
