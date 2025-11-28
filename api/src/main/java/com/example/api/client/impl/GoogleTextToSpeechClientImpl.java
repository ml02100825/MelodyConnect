package com.example.api.client.impl;

import com.example.api.client.TextToSpeechClient;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;
import org.springframework.web.reactive.function.client.WebClientResponseException;

import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Base64;
import java.util.Map;
import java.util.UUID;

/**
 * Google Cloud Text-to-Speech API実装
 */
@Component
public class GoogleTextToSpeechClientImpl implements TextToSpeechClient {

    private static final Logger logger = LoggerFactory.getLogger(GoogleTextToSpeechClientImpl.class);
    private static final String TTS_API_URL = "https://texttospeech.googleapis.com/v1/text:synthesize";

    private final WebClient webClient;

    @Value("${google.cloud.api.key:}")
    private String apiKey;

    @Value("${tts.audio.output.directory:./audio}")
    private String outputDir;

    public GoogleTextToSpeechClientImpl() {
        this.webClient = WebClient.builder()
            .defaultHeader(HttpHeaders.CONTENT_TYPE, MediaType.APPLICATION_JSON_VALUE)
            .build();
    }

    @Override
    public String generateSpeech(String text, String language) {
        if (apiKey == null || apiKey.isEmpty()) {
            logger.warn("Google Cloud TTS APIキーが設定されていません。");
            return null;
        }

        if (text == null || text.trim().isEmpty()) {
            logger.warn("テキストが空です。");
            return null;
        }

        try {
            logger.info("音声生成開始: language={}, textLength={}", language, text.length());

            // 言語コードとvoiceNameを取得
            String languageCode = getLanguageCode(language);
            String voiceName = getVoiceName(language);

            // Google Cloud TTS APIリクエストボディ
            Map<String, Object> requestBody = Map.of(
                "input", Map.of("text", text),
                "voice", Map.of(
                    "languageCode", languageCode,
                    "name", voiceName
             
                 
                ),
                "audioConfig", Map.of(
                    "audioEncoding", "MP3",
                    "speakingRate", 1.0,
                    "pitch", 0.0
                )
            );

            // Google Cloud TTS APIを呼び出し
            Map<String, Object> response = webClient.post()
                .uri(TTS_API_URL + "?key=" + apiKey)
                .bodyValue(requestBody)
                .retrieve()
                .bodyToMono(Map.class)
                .block();

            if (response == null || !response.containsKey("audioContent")) {
                logger.error("音声生成に失敗しました: レスポンスが不正です");
                return null;
            }

            // Base64エンコードされた音声データを取得
            String audioContentBase64 = (String) response.get("audioContent");
            byte[] audioBytes = Base64.getDecoder().decode(audioContentBase64);

            // 音声ファイルを保存
            String audioUrl = saveAudioFile(audioBytes, languageCode);

            logger.info("音声生成完了: url={}", audioUrl);
            return audioUrl;

        } catch (WebClientResponseException  e) {
                logger.error("TTS API エラー: status={}, body={}", 
                    e.getStatusCode(), 
                    e.getResponseBodyAsString());
                return null;
            }catch (Exception e) {
        logger.error("音声生成中にエラーが発生しました", e);
        return null;
    }
    }

    /**
     * 言語コードからGoogle Cloud TTS用の言語コードを取得
     */
    private String getLanguageCode(String language) {
        if (language == null) {
            return "en-US";
        }

        return switch (language.toLowerCase()) {
            case "en" -> "en-US";
            case "ko" -> "ko-KR";
            case "ja" -> "ja-JP";
            case "zh" -> "zh-CN";
            case "es" -> "es-ES";
            case "fr" -> "fr-FR";
            case "de" -> "de-DE";
            case "pt" -> "pt-BR";
            case "it" -> "it-IT";
            case "ru" -> "ru-RU";
            default -> "en-US";
        };
    }

    /**
     * 言語コードからGoogle Cloud TTSの推奨音声名を取得
     */
    private String getVoiceName(String language) {
        if (language == null) {
            return "en-US-Neural2-C";
        }

        return switch (language.toLowerCase()) {
            case "en" -> "en-US-Neural2-C";
            case "ko" -> "ko-KR-Neural2-C";
            case "ja" -> "ja-JP-Neural2-C";
            case "zh" -> "zh-CN-Neural2-C";
            case "es" -> "es-ES-Neural2-C";
            case "fr" -> "fr-FR-Neural2-C";
            case "de" -> "de-DE-Neural2-C";
            case "pt" -> "pt-BR-Neural2-C";
            case "it" -> "it-IT-Neural2-C";
            case "ru" -> "ru-RU-Neural2-C";
            default -> "en-US-Neural2-C";
        };
    }

    /**
     * 音声ファイルを保存してURLを返す
     * TODO: 本番環境ではS3などのクラウドストレージに保存
     */
    private String saveAudioFile(byte[] audioBytes, String languageCode) throws Exception {
        // 出力ディレクトリを作成
        Path outputPath = Paths.get(outputDir);
        if (!Files.exists(outputPath)) {
            Files.createDirectories(outputPath);
        }

        // ファイル名を生成（UUID + 言語コード）
        String fileName = String.format("%s_%s.mp3", UUID.randomUUID(), languageCode);
        Path filePath = outputPath.resolve(fileName);

        // ファイルに書き込み
        Files.write(filePath, audioBytes);

        // URLを返す（本番環境ではS3などのURLを返す）
        // TODO: S3にアップロードしてそのURLを返す
        return filePath.toString();
    }
}
