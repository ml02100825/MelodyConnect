package com.example.api.client.impl;

import com.example.api.client.ClaudeApiClient;
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
 * Claude API Client の実装
 * Anthropic Claude APIを使用して歌詞から問題を生成します
 */
@Component
@Primary
public class ClaudeApiClientImpl implements ClaudeApiClient {

    private static final Logger logger = LoggerFactory.getLogger(ClaudeApiClientImpl.class);
    private static final String CLAUDE_API_URL = "https://api.anthropic.com/v1/messages";

    private final WebClient webClient;
    private final ObjectMapper objectMapper;

    @Value("${claude.api.key:}")
    private String apiKey;

    @Value("${claude.api.model:claude-3-5-sonnet-20241022}")
    private String model;

    @Value("${claude.api.max-tokens:4096}")
    private int maxTokens;

    public ClaudeApiClientImpl(ObjectMapper objectMapper) {
        this.objectMapper = objectMapper;
        this.webClient = WebClient.builder()
            .baseUrl(CLAUDE_API_URL)
            .defaultHeader(HttpHeaders.CONTENT_TYPE, MediaType.APPLICATION_JSON_VALUE)
            .build();
    }

    @Override
    public ClaudeQuestionResponse generateQuestions(
        String lyrics,
        Integer fillInBlankCount,
        Integer listeningCount
    ) {
        if (apiKey == null || apiKey.isEmpty()) {
            logger.warn("Claude APIキーが設定されていません。モックデータを返します。");
            return createMockResponse(fillInBlankCount, listeningCount);
        }

        try {
            logger.info("Claude APIで問題を生成中: fillInBlank={}, listening={}", fillInBlankCount, listeningCount);

            String prompt = buildPrompt(lyrics, fillInBlankCount, listeningCount);
            String responseText = callClaudeApi(prompt);

            return parseResponse(responseText);

        } catch (Exception e) {
            logger.error("Claude API呼び出し中にエラーが発生しました", e);
            throw new RuntimeException("問題生成に失敗しました: " + e.getMessage(), e);
        }
    }

    /**
     * 改善されたプロンプトを構築
     * 問題の品質を高めるために、詳細な指示を含めます
     */
    private String buildPrompt(String lyrics, int fillInBlankCount, int listeningCount) {
        return String.format("""
            You are an expert language learning content creator. Generate high-quality English learning questions from the following Song lyrics.

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
                  "explanation": "Brief explanation of why this word/grammar point is important"
                }
              ],
              "listening": [
                {
                  "sentence": "The complete sentence from lyrics",
                  "blankWord": "key word or phrase to focus on",
                  "difficulty": 1-5,
                  "explanation": "What makes this sentence valuable for listening practice"
                }
              ]
            }

            **IMPORTANT:**
            - Return ONLY valid JSON, no additional text
            - Ensure all questions are directly from the provided lyrics
            - Each Question should be unique and test different language aspects
            - Provide clear, pedagogically sound explanations
            """, lyrics, fillInBlankCount, listeningCount);
    }

    /**
     * Claude APIを呼び出し
     */
    private String callClaudeApi(String prompt) {
        Map<String, Object> requestBody = Map.of(
            "model", model,
            "max_tokens", maxTokens,
            "messages", List.of(
                Map.of(
                    "role", "user",
                    "content", prompt
                )
            )
        );

        String response = webClient.post()
            .header("x-api-key", apiKey)
            .header("anthropic-version", "2023-06-01")
            .bodyValue(requestBody)
            .retrieve()
            .bodyToMono(String.class)
            .block();

        logger.debug("Claude APIレスポンス受信完了");
        return response;
    }

    /**
     * Claude APIのレスポンスをパース
     */
    private ClaudeQuestionResponse parseResponse(String responseText) {
        try {
            JsonNode rootNode = objectMapper.readTree(responseText);

            // Claude APIのレスポンス形式: content[0].text にJSON文字列が含まれる
            String contentText = rootNode.path("content").get(0).path("text").asText();

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

            return ClaudeQuestionResponse.builder()
                .fillInBlank(fillInBlankQuestions)
                .listening(listeningQuestions)
                .build();

        } catch (Exception e) {
            logger.error("レスポンスのパースに失敗しました", e);
            throw new RuntimeException("レスポンスの解析に失敗しました", e);
        }
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
