package com.example.api.client.impl;

import com.example.api.client.WordnikApiClient;
import com.example.api.dto.WordnikWordInfo;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Primary;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;
import org.springframework.web.reactive.function.client.WebClientResponseException;

/**
 * Wordnik API Client の実装
 * 単語の定義、発音、例文などの情報を取得します
 */
@Component
@Primary
public class WordnikApiClientImpl implements WordnikApiClient {

    private static final Logger logger = LoggerFactory.getLogger(WordnikApiClientImpl.class);
    private static final String WORDNIK_API_BASE_URL = "https://api.wordnik.com/v4";

    private final WebClient webClient;
    private final ObjectMapper objectMapper;

    @Value("${wordnik.api.key:}")
    private String apiKey;

    public WordnikApiClientImpl(ObjectMapper objectMapper) {
        this.objectMapper = objectMapper;
        this.webClient = WebClient.builder()
            .baseUrl(WORDNIK_API_BASE_URL)
            .build();
    }

    @Override
    public WordnikWordInfo getWordInfo(String word) {
        logger.info("=== WORDNIK API REQUEST ===");
        logger.info("Word: {}", word);
        logger.info("API Key configured: {}", (apiKey != null && !apiKey.isEmpty()));
        logger.info("==========================");

        if (apiKey == null || apiKey.isEmpty()) {
            logger.warn("Wordnik APIキーが設定されていません。モックデータを返します。");
            return createMockWordInfo(word);
        }

        try {
            logger.info("Wordnikから単語情報を取得中: word={}", word);

            // 複数のエンドポイントから情報を取得
            String definition = getDefinitions(word);
            String pronunciation = getPronunciation(word);
            String partOfSpeech = getPartOfSpeech(word);
            String[] exampleData = getExamples(word);
            String audioUrl = getAudioUrl(word);

            logger.info("=== WORDNIK API RESPONSE ===");
            logger.info("Definition: {}", definition);
            logger.info("Pronunciation: {}", pronunciation);
            logger.info("Part of Speech: {}", partOfSpeech);
            logger.info("Example: {}", exampleData[0]);
            logger.info("Audio URL: {}", audioUrl);
            logger.info("============================");

            return WordnikWordInfo.builder()
                .word(word)
                .meaningJa(definition)  // TODO: 翻訳APIを使って日本語に変換
                .pronunciation(pronunciation)
                .partOfSpeech(partOfSpeech)
                .exampleSentence(exampleData[0])
                .exampleTranslate(exampleData[1])  // TODO: 翻訳APIを使って日本語に変換
                .audioUrl(audioUrl)
                .build();

        } catch (WebClientResponseException e) {
            logger.error("Wordnik API呼び出しエラー: status={}, word={}, message={}",
                e.getStatusCode(), word, e.getMessage());
            return createMockWordInfo(word);
        } catch (Exception e) {
            logger.error("単語情報の取得中にエラーが発生しました: word={}", word, e);
            return createMockWordInfo(word);
        }
    }

    /**
     * 単語の定義を取得
     */
    private String getDefinitions(String word) {
        try {
            String response = webClient.get()
                .uri(uriBuilder -> uriBuilder
                    .path("/word.json/{word}/definitions")
                    .queryParam("api_key", apiKey)
                    .queryParam("limit", 1)
                    .queryParam("includeRelated", false)
                    .queryParam("useCanonical", true)
                    .build(word))
                .retrieve()
                .bodyToMono(String.class)
                .block();

            JsonNode definitions = objectMapper.readTree(response);
            if (definitions.isArray() && definitions.size() > 0) {
                return definitions.get(0).path("text").asText("No definition available");
            }
            return "No definition available";

        } catch (Exception e) {
            logger.warn("定義の取得に失敗: word={}", word);
            return "Definition not available";
        }
    }

    /**
     * 発音情報を取得
     */
    private String getPronunciation(String word) {
        try {
            String response = webClient.get()
                .uri(uriBuilder -> uriBuilder
                    .path("/word.json/{word}/pronunciations")
                    .queryParam("api_key", apiKey)
                    .queryParam("limit", 1)
                    .build(word))
                .retrieve()
                .bodyToMono(String.class)
                .block();

            JsonNode pronunciations = objectMapper.readTree(response);
            if (pronunciations.isArray() && pronunciations.size() > 0) {
                return pronunciations.get(0).path("raw").asText("");
            }
            return "";

        } catch (Exception e) {
            logger.warn("発音の取得に失敗: word={}", word);
            return "";
        }
    }

    /**
     * 品詞を取得
     */
    private String getPartOfSpeech(String word) {
        try {
            String response = webClient.get()
                .uri(uriBuilder -> uriBuilder
                    .path("/word.json/{word}/definitions")
                    .queryParam("api_key", apiKey)
                    .queryParam("limit", 1)
                    .build(word))
                .retrieve()
                .bodyToMono(String.class)
                .block();

            JsonNode definitions = objectMapper.readTree(response);
            if (definitions.isArray() && definitions.size() > 0) {
                return definitions.get(0).path("partOfSpeech").asText("unknown");
            }
            return "unknown";

        } catch (Exception e) {
            logger.warn("品詞の取得に失敗: word={}", word);
            return "unknown";
        }
    }

    /**
     * 例文を取得
     * @return [例文, 翻訳] の配列
     */
    private String[] getExamples(String word) {
        try {
            String response = webClient.get()
                .uri(uriBuilder -> uriBuilder
                    .path("/word.json/{word}/examples")
                    .queryParam("api_key", apiKey)
                    .queryParam("limit", 1)
                    .build(word))
                .retrieve()
                .bodyToMono(String.class)
                .block();

            JsonNode examplesResponse = objectMapper.readTree(response);
            JsonNode examples = examplesResponse.path("examples");

            if (examples.isArray() && examples.size() > 0) {
                String exampleText = examples.get(0).path("text").asText("");
                // TODO: 翻訳APIを使って日本語に変換
                return new String[]{exampleText, ""};
            }
            return new String[]{"", ""};

        } catch (Exception e) {
            logger.warn("例文の取得に失敗: word={}", word);
            return new String[]{"", ""};
        }
    }

    /**
     * 音声URLを取得
     */
    private String getAudioUrl(String word) {
        try {
            String response = webClient.get()
                .uri(uriBuilder -> uriBuilder
                    .path("/word.json/{word}/audio")
                    .queryParam("api_key", apiKey)
                    .queryParam("limit", 1)
                    .build(word))
                .retrieve()
                .bodyToMono(String.class)
                .block();

            JsonNode audioFiles = objectMapper.readTree(response);
            if (audioFiles.isArray() && audioFiles.size() > 0) {
                return audioFiles.get(0).path("fileUrl").asText("");
            }
            return "";

        } catch (Exception e) {
            logger.warn("音声URLの取得に失敗: word={}", word);
            return "";
        }
    }

    /**
     * モックデータを作成
     */
    private WordnikWordInfo createMockWordInfo(String word) {
        return WordnikWordInfo.builder()
            .word(word)
            .meaningJa("（辞書情報を取得できませんでした）")
            .pronunciation("")
            .partOfSpeech("unknown")
            .exampleSentence("")
            .exampleTranslate("")
            .audioUrl("")
            .build();
    }
}
