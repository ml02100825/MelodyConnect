package com.example.api.client.impl;

import com.example.api.client.GeminiApiClient;
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
 * 単語の定義、発音、例文などの情報を取得し、Gemini APIで日本語翻訳します
 */
@Component
@Primary
public class WordnikApiClientImpl implements WordnikApiClient {

    private static final Logger logger = LoggerFactory.getLogger(WordnikApiClientImpl.class);
    private static final String WORDNIK_API_BASE_URL = "https://api.wordnik.com/v4";

    private final WebClient webClient;
    private final ObjectMapper objectMapper;
    private final GeminiApiClient geminiApiClient;

    @Value("${wordnik.api.key:}")
    private String apiKey;

    public WordnikApiClientImpl(
        ObjectMapper objectMapper,
        GeminiApiClient geminiApiClient
    ) {
        this.objectMapper = objectMapper;
        this.geminiApiClient = geminiApiClient;
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

            // 効率化: 定義と品詞を1回のリクエストで取得
            DefinitionInfo defInfo = getDefinitionAndPartOfSpeech(word);
            String pronunciation = getPronunciation(word);
            String[] exampleData = getExamples(word);
            String audioUrl = getAudioUrl(word);

            // Gemini APIで日本語翻訳
            String meaningJa = "";
            String exampleTranslate = "";
            
            if (!defInfo.definition.isEmpty() && !defInfo.definition.equals("No definition available")) {
                meaningJa = geminiApiClient.translateToJapanese(defInfo.definition, "English");
            }
            
            if (!exampleData[0].isEmpty()) {
                exampleTranslate = geminiApiClient.translateToJapanese(exampleData[0], "English");
            }

            logger.info("=== WORDNIK API RESPONSE ===");
            logger.info("Definition: {}", defInfo.definition);
            logger.info("Meaning (JA): {}", meaningJa);
            logger.info("Pronunciation: {}", pronunciation);
            logger.info("Part of Speech: {}", defInfo.partOfSpeech);
            logger.info("Example: {}", exampleData[0]);
            logger.info("Example (JA): {}", exampleTranslate);
            logger.info("Audio URL: {}", audioUrl);
            logger.info("============================");

            return WordnikWordInfo.builder()
                .word(word)
                .meaningJa(meaningJa)
                .pronunciation(pronunciation)
                .partOfSpeech(defInfo.partOfSpeech)
                .exampleSentence(exampleData[0])
                .exampleTranslate(exampleTranslate)
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
     * 定義と品詞を同時に取得（効率化: 1回のAPIコールで両方取得）
     */
    private DefinitionInfo getDefinitionAndPartOfSpeech(String word) {
        try {
            logger.debug("Calling /word.json/{}/definitions", word);
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

            logger.debug("Definitions response: {}", response);
            JsonNode definitions = objectMapper.readTree(response);
            
            if (definitions.isArray() && definitions.size() > 0) {
                JsonNode firstDef = definitions.get(0);
                String definition = firstDef.path("text").asText("No definition available");
                String partOfSpeech = firstDef.path("partOfSpeech").asText("unknown");
                
                logger.debug("Definition extracted: {}", definition);
                logger.debug("Part of speech extracted: {}", partOfSpeech);
                
                return new DefinitionInfo(definition, partOfSpeech);
            }
            
            logger.warn("No definitions found in response for word: {}", word);
            return new DefinitionInfo("No definition available", "unknown");

        } catch (WebClientResponseException e) {
            logger.error("定義と品詞の取得に失敗 (HTTP {}): word={}, message={}",
                e.getStatusCode(), word, e.getMessage());
            return new DefinitionInfo("Definition not available", "unknown");
        } catch (Exception e) {
            logger.error("定義と品詞の取得に失敗: word={}", word, e);
            return new DefinitionInfo("Definition not available", "unknown");
        }
    }

    /**
     * 発音情報を取得
     */
    private String getPronunciation(String word) {
        try {
            logger.debug("Calling /word.json/{}/pronunciations", word);
            String response = webClient.get()
                .uri(uriBuilder -> uriBuilder
                    .path("/word.json/{word}/pronunciations")
                    .queryParam("api_key", apiKey)
                    .queryParam("limit", 1)
                    .build(word))
                .retrieve()
                .bodyToMono(String.class)
                .block();

            logger.debug("Pronunciations response: {}", response);
            JsonNode pronunciations = objectMapper.readTree(response);
            
            if (pronunciations.isArray() && pronunciations.size() > 0) {
                String pronunciation = pronunciations.get(0).path("raw").asText("");
                logger.debug("Pronunciation extracted: {}", pronunciation);
                return pronunciation;
            }
            
            logger.debug("No pronunciations found for word: {}", word);
            return "";

        } catch (WebClientResponseException e) {
            logger.error("発音の取得に失敗 (HTTP {}): word={}, message={}",
                e.getStatusCode(), word, e.getMessage());
            return "";
        } catch (Exception e) {
            logger.error("発音の取得に失敗: word={}", word, e);
            return "";
        }
    }

    /**
     * 例文を取得
     * @return [例文, 翻訳] の配列（翻訳は後でGeminiで実行）
     */
    private String[] getExamples(String word) {
        try {
            logger.debug("Calling /word.json/{}/examples", word);
            String response = webClient.get()
                .uri(uriBuilder -> uriBuilder
                    .path("/word.json/{word}/examples")
                    .queryParam("api_key", apiKey)
                    .queryParam("limit", 1)
                    .build(word))
                .retrieve()
                .bodyToMono(String.class)
                .block();

            logger.debug("Examples response: {}", response);
            JsonNode examplesResponse = objectMapper.readTree(response);
            JsonNode examples = examplesResponse.path("examples");

            if (examples.isArray() && examples.size() > 0) {
                String exampleText = examples.get(0).path("text").asText("");
                logger.debug("Example extracted: {}", exampleText);
                // 翻訳はgetWordInfoで実行
                return new String[]{exampleText, ""};
            }
            
            logger.debug("No examples found for word: {}", word);
            return new String[]{"", ""};

        } catch (WebClientResponseException e) {
            logger.error("例文の取得に失敗 (HTTP {}): word={}, message={}",
                e.getStatusCode(), word, e.getMessage());
            return new String[]{"", ""};
        } catch (Exception e) {
            logger.error("例文の取得に失敗: word={}", word, e);
            return new String[]{"", ""};
        }
    }

    /**
     * 音声URLを取得
     */
    private String getAudioUrl(String word) {
        try {
            logger.debug("Calling /word.json/{}/audio", word);
            String response = webClient.get()
                .uri(uriBuilder -> uriBuilder
                    .path("/word.json/{word}/audio")
                    .queryParam("api_key", apiKey)
                    .queryParam("limit", 1)
                    .build(word))
                .retrieve()
                .bodyToMono(String.class)
                .block();

            logger.debug("Audio response: {}", response);
            JsonNode audioFiles = objectMapper.readTree(response);
            
            if (audioFiles.isArray() && audioFiles.size() > 0) {
                String audioUrl = audioFiles.get(0).path("fileUrl").asText("");
                logger.debug("Audio URL extracted: {}", audioUrl);
                return audioUrl;
            }
            
            logger.debug("No audio files found for word: {}", word);
            return "";

        } catch (WebClientResponseException e) {
            logger.error("音声URLの取得に失敗 (HTTP {}): word={}, message={}",
                e.getStatusCode(), word, e.getMessage());
            return "";
        } catch (Exception e) {
            logger.error("音声URLの取得に失敗: word={}", word, e);
            return "";
        }
    }

    /**
     * モックデータを作成
     */
    private WordnikWordInfo createMockWordInfo(String word) {
        return WordnikWordInfo.builder()
            .word(word)
            .meaningJa("(辞書情報を取得できませんでした)")
            .pronunciation("")
            .partOfSpeech("unknown")
            .exampleSentence("")
            .exampleTranslate("")
            .audioUrl("")
            .build();
    }

    /**
     * 定義と品詞の情報を保持する内部クラス
     */
    private static class DefinitionInfo {
        final String definition;
        final String partOfSpeech;

        DefinitionInfo(String definition, String partOfSpeech) {
            this.definition = definition;
            this.partOfSpeech = partOfSpeech;
        }
    }
}