package com.example.api.client.impl;

import com.example.api.client.TtsApiClient;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;

import java.io.FileOutputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Base64;
import java.util.Map;
import java.util.UUID;

/**
 * Google Cloud Text-to-Speech API Client の実装
 *
 * 推奨理由:
 * - 高品質なWaveNetおよびNeural2音声
 * - 40以上の言語に対応
 * - 簡単な統合
 * - 従量課金制（最初の100万文字/月は無料）
 *
 * 代替オプション:
 * - AWS Polly: 同様の品質、AWSエコシステムとの統合が良い
 * - Azure Speech Service: Microsoftエコシステム向け
 * - ElevenLabs: より自然な音声だが高コスト
 */
@Component
public class GoogleTtsApiClientImpl implements TtsApiClient {

    private static final Logger logger = LoggerFactory.getLogger(GoogleTtsApiClientImpl.class);
    private static final String GOOGLE_TTS_API_URL = "https://texttospeech.googleapis.com/v1/text:synthesize";

    private final WebClient webClient;
    private final ObjectMapper objectMapper;

    @Value("${google.cloud.api.key:}")
    private String apiKey;

    @Value("${tts.audio.output.directory:./audio}")
    private String audioOutputDirectory;

    @Value("${tts.audio.base.url:http://localhost:8080/audio}")
    private String audioBaseUrl;

    public GoogleTtsApiClientImpl(ObjectMapper objectMapper) {
        this.objectMapper = objectMapper;
        this.webClient = WebClient.builder()
            .baseUrl(GOOGLE_TTS_API_URL)
            .build();
    }

    @Override
    public String generateAudio(String text, String language) {
        return generateAudio(text, language, "FEMALE", 1.0);
    }

    @Override
    public String generateAudio(String text, String language, String voiceGender, double speakingRate) {
        if (apiKey == null || apiKey.isEmpty()) {
            logger.warn("Google Cloud APIキーが設定されていません。音声生成をスキップします。");
            return null;
        }

        try {
            logger.info("Google TTSで音声を生成中: text={}, language={}",
                text.substring(0, Math.min(50, text.length())), language);

            // APIリクエストを構築
            Map<String, Object> requestBody = buildRequestBody(text, language, voiceGender, speakingRate);

            // APIを呼び出し
            String response = webClient.post()
                .uri(uriBuilder -> uriBuilder
                    .queryParam("key", apiKey)
                    .build())
                .bodyValue(requestBody)
                .retrieve()
                .bodyToMono(String.class)
                .block();

            // レスポンスから音声データを取得
            JsonNode rootNode = objectMapper.readTree(response);
            String audioContent = rootNode.path("audioContent").asText();

            if (audioContent == null || audioContent.isEmpty()) {
                logger.error("音声コンテンツが空です");
                return null;
            }

            // Base64デコードしてファイルに保存
            String audioUrl = saveAudioFile(audioContent);
            logger.info("音声生成完了: url={}", audioUrl);

            return audioUrl;

        } catch (Exception e) {
            logger.error("音声生成中にエラーが発生しました", e);
            return null;
        }
    }

    /**
     * APIリクエストボディを構築
     */
    private Map<String, Object> buildRequestBody(String text, String language, String voiceGender, double speakingRate) {
        // 言語に応じた音声名を選択
        String voiceName = selectVoiceName(language, voiceGender);

        return Map.of(
            "input", Map.of("text", text),
            "voice", Map.of(
                "languageCode", language,
                "name", voiceName,
                "ssmlGender", voiceGender
            ),
            "audioConfig", Map.of(
                "audioEncoding", "MP3",
                "speakingRate", speakingRate,
                "pitch", 0.0
            )
        );
    }

    /**
     * 言語と性別に応じた音声名を選択
     */
    private String selectVoiceName(String language, String voiceGender) {
        // WaveNet音声を優先（より自然な音声）
        if (language.startsWith("en")) {
            return voiceGender.equals("MALE") ? "en-US-Neural2-D" : "en-US-Neural2-F";
        } else if (language.startsWith("ja")) {
            return voiceGender.equals("MALE") ? "ja-JP-Neural2-C" : "ja-JP-Neural2-B";
        }
        // デフォルト
        return language + "-Standard-A";
    }

    /**
     * 音声データをファイルに保存
     */
    private String saveAudioFile(String base64AudioContent) throws Exception {
        // 出力ディレクトリを作成
        Path outputDir = Paths.get(audioOutputDirectory);
        if (!Files.exists(outputDir)) {
            Files.createDirectories(outputDir);
        }

        // ユニークなファイル名を生成
        String fileName = UUID.randomUUID().toString() + ".mp3";
        Path filePath = outputDir.resolve(fileName);

        // Base64デコードして保存
        byte[] audioBytes = Base64.getDecoder().decode(base64AudioContent);
        try (FileOutputStream fos = new FileOutputStream(filePath.toFile())) {
            fos.write(audioBytes);
        }

        // URLを返す
        return audioBaseUrl + "/" + fileName;
    }
}
