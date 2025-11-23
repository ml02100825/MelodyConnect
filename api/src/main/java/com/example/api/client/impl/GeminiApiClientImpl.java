package com.example.api.client.impl;

import com.example.api.client.GeminiApiClient;
import com.example.api.dto.ClaudeQuestionResponse;
import com.example.api.dto.ClaudeQuestionResponse.Question;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Primary;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/**
 * Gemini API Client の実装
 * Google Gemini APIを使用して歌詞から問題を生成します
 */
@Component
@Primary
public class GeminiApiClientImpl implements GeminiApiClient {

    private static final Logger logger = LoggerFactory.getLogger(GeminiApiClientImpl.class);
    private static final String GEMINI_API_URL = "https://generativelanguage.googleapis.com/v1beta/models";

    private final WebClient webClient;
    private final ObjectMapper objectMapper;

    @Value("${gemini.api.key:}")
    private String apiKey;

    @Value("${gemini.api.model:gemini-2.0-flash}")
    private String model;

    public GeminiApiClientImpl(ObjectMapper objectMapper) {
        this.objectMapper = objectMapper;
        this.webClient = WebClient.builder()
            .baseUrl(GEMINI_API_URL)
            .defaultHeader(HttpHeaders.CONTENT_TYPE, MediaType.APPLICATION_JSON_VALUE)
            .build();
    }

    @Override
    public ClaudeQuestionResponse generateQuestions(
        String lyrics,
        String language,
        Integer fillInBlankCount,
        Integer listeningCount
    ) {
        if (apiKey == null || apiKey.isEmpty()) {
            logger.warn("Gemini APIキーが設定されていません。モックデータを返します。");
            return createMockResponse(fillInBlankCount, listeningCount);
        }

        try {
            logger.info("Gemini APIで問題を生成中: language={}, fillInBlank={}, listening={}",
                language, fillInBlankCount, listeningCount);

            String prompt = buildPrompt(lyrics, language, fillInBlankCount, listeningCount);
            String responseText = callGeminiApi(prompt);

            return parseResponse(responseText);

        } catch (Exception e) {
            logger.error("Gemini API呼び出し中にエラーが発生しました", e);
            throw new RuntimeException("問題生成に失敗しました: " + e.getMessage(), e);
        }
    }

    /**
     * プロンプトを構築
     */
    private String buildPrompt(String lyrics, String language, int fillInBlankCount, int listeningCount) {
        String languageName = "en".equals(language) ? "English" : "Korean";

        return String.format("""
            You are an expert language learning content creator. Generate high-quality %s learning questions from the following song lyrics.

            **LYRICS:**
            %s

            **REQUIREMENTS:**

            1. Generate %d fill-in-the-blank questions:
               - Select meaningful words (verbs, nouns, adjectives, adverbs) that are pedagogically valuable
               - Avoid articles (a, an, the) and simple pronouns
               - Ensure each blank tests different language skills (vocabulary, grammar, collocations)
               - Vary difficulty levels from 1 (beginner) to 5 (advanced)
               - Consider word frequency and complexity for difficulty assignment

            2. Generate %d listening comprehension questions:
               - Choose complete, meaningful sentences from the lyrics
               - Select sentences with clear grammatical structures
               - Include sentences with idioms, phrasal verbs, or interesting expressions when possible
               - Vary difficulty based on sentence complexity, length, and vocabulary

            **DIFFICULTY LEVEL GUIDELINES:**
            - Level 1: Common words (top 1000), simple grammar
            - Level 2: Intermediate words (top 3000), basic tenses
            - Level 3: Advanced vocabulary, complex tenses
            - Level 4: Idioms, phrasal verbs, nuanced meanings
            - Level 5: Literary expressions, rare vocabulary, complex structures

            **OUTPUT FORMAT (JSON):**
            {
              "fillInBlank": [
                {
                  "sentence": "The sentence with _____ replacing the word",
                  "blankWord": "the word that was removed",
                  "difficulty": 1-5,
                  "explanation": "Brief explanation of why this word/grammar point is important",
                  "skillFocus": "vocabulary|grammar|collocation|idiom",
                  "translationJa": "Japanese translation of the complete sentence"
                }
              ],
              "listening": [
                {
                  "sentence": "The complete sentence from lyrics",
                  "blankWord": "key word or phrase to focus on",
                  "difficulty": 1-5,
                  "explanation": "What makes this sentence valuable for listening practice",
                  "skillFocus": "vocabulary|grammar|collocation|idiom",
                  "translationJa": "Japanese translation of the sentence"
                }
              ]
            }

            **IMPORTANT:**
            - Return ONLY valid JSON, no additional text or markdown formatting
            - Do not wrap the JSON in code blocks
            - Ensure all questions are directly from the provided lyrics
            - Each question should be unique and test different language aspects
            - Provide clear, pedagogically sound explanations
            """, languageName, lyrics, fillInBlankCount, listeningCount);
    }

    /**
     * Gemini APIを呼び出し
     */
    private String callGeminiApi(String prompt) {
        Map<String, Object> requestBody = Map.of(
            "contents", List.of(
                Map.of(
                    "parts", List.of(
                        Map.of("text", prompt)
                    )
                )
            ),
            "generationConfig", Map.of(
                "temperature", 0.7,
                "topK", 40,
                "topP", 0.95,
                "maxOutputTokens", 8192
            )
        );

        String response = webClient.post()
            .uri("/{model}:generateContent?key={apiKey}", model, apiKey)
            .bodyValue(requestBody)
            .retrieve()
            .bodyToMono(String.class)
            .block();

        logger.debug("Gemini APIレスポンス受信完了");
        return response;
    }

    /**
     * Gemini APIのレスポンスをパース
     */
    private ClaudeQuestionResponse parseResponse(String responseText) {
        try {
            JsonNode rootNode = objectMapper.readTree(responseText);

            // Gemini APIのレスポンス形式: candidates[0].content.parts[0].text
            String contentText = rootNode
                .path("candidates").get(0)
                .path("content")
                .path("parts").get(0)
                .path("text").asText();

            // JSON部分を抽出（マークダウンコードブロックを除去）
            contentText = extractJson(contentText);

            // JSON文字列をパース
            JsonNode questionsNode = objectMapper.readTree(contentText);

            List<Question> fillInBlankQuestions = new ArrayList<>();
            List<Question> listeningQuestions = new ArrayList<>();

            // fill-in-blank問題をパース
            JsonNode fillInBlankArray = questionsNode.path("fillInBlank");
            if (fillInBlankArray.isArray()) {
                for (JsonNode node : fillInBlankArray) {
                    fillInBlankQuestions.add(parseQuestion(node));
                }
            }

            // listening問題をパース
            JsonNode listeningArray = questionsNode.path("listening");
            if (listeningArray.isArray()) {
                for (JsonNode node : listeningArray) {
                    listeningQuestions.add(parseQuestion(node));
                }
            }

            logger.info("問題生成完了: fillInBlank={}, listening={}",
                fillInBlankQuestions.size(), listeningQuestions.size());

            return ClaudeQuestionResponse.builder()
                .fillInBlank(fillInBlankQuestions)
                .listening(listeningQuestions)
                .build();

        } catch (Exception e) {
            logger.error("レスポンスのパースに失敗しました: {}", responseText, e);
            throw new RuntimeException("レスポンスの解析に失敗しました", e);
        }
    }

    /**
     * レスポンスからJSON部分を抽出
     */
    private String extractJson(String text) {
        // マークダウンのコードブロックを除去
        if (text.contains("```json")) {
            int start = text.indexOf("```json") + 7;
            int end = text.lastIndexOf("```");
            if (end > start) {
                return text.substring(start, end).trim();
            }
        } else if (text.contains("```")) {
            int start = text.indexOf("```") + 3;
            int end = text.lastIndexOf("```");
            if (end > start) {
                return text.substring(start, end).trim();
            }
        }
        return text.trim();
    }

    /**
     * 個別の問題をパース
     */
    private Question parseQuestion(JsonNode node) {
        return Question.builder()
            .sentence(node.path("sentence").asText())
            .blankWord(node.path("blankWord").asText())
            .difficulty(node.path("difficulty").asInt(3))
            .explanation(node.path("explanation").asText())
            .build();
    }

    /**
     * モックレスポンスを作成（APIキーが設定されていない場合）
     */
    private ClaudeQuestionResponse createMockResponse(int fillInBlankCount, int listeningCount) {
        List<Question> fillInBlankQuestions = new ArrayList<>();
        List<Question> listeningQuestions = new ArrayList<>();

        // モックデータ生成
        for (int i = 0; i < fillInBlankCount; i++) {
            fillInBlankQuestions.add(Question.builder()
                .sentence("I _____ to the store yesterday")
                .blankWord("went")
                .difficulty(2)
                .explanation("過去形の不規則動詞")
                .build());
        }

        for (int i = 0; i < listeningCount; i++) {
            listeningQuestions.add(Question.builder()
                .sentence("She is singing beautifully")
                .blankWord("beautifully")
                .difficulty(3)
                .explanation("副詞の使用")
                .build());
        }

        return ClaudeQuestionResponse.builder()
            .fillInBlank(fillInBlankQuestions)
            .listening(listeningQuestions)
            .build();
    }
}
