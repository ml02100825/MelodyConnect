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
            You are an expert language learning content creator and translator.

The TARGET LANGUAGE is: {{targetLanguage}}.
The LEARNER NATIVE LANGUAGE is: Japanese.

Your tasks:

1) Select short fragments (phrases or sentences) from the ORIGINAL SONG LYRICS.
2) For each selected fragment, translate it into the TARGET LANGUAGE.
3) Based on your TARGET LANGUAGE translations, create fill-in-the-blank and listening questions.

IMPORTANT ABOUT LANGUAGES:
- "sourceFragment" must always be copied directly from the original lyrics (do NOT modify its language).
- "targetSentenceFull", "sentenceWithBlank", "blankWord" must always be in the TARGET LANGUAGE.
- "translationJa" must always be a natural Japanese translation of "targetSentenceFull".
- "explanation" must be written in natural Japanese.
- Do NOT mix multiple languages in a single field.

ORIGINAL SONG LYRICS (may contain multiple languages):
{{lyricsOriginal}}

REQUIREMENTS:

1. Generate {{numFill}} fill-in-the-blank questions:
   - Step A: Choose a short, meaningful fragment from the original lyrics (sourceFragment).
   - Step B: Translate that fragment into a complete sentence in the TARGET LANGUAGE (targetSentenceFull).
   - Step C: Choose one meaningful word (verb, noun, adjective, adverb) and replace it with "_____" in sentenceWithBlank.
   - Avoid articles (a, an, the) and simple pronouns as blanks.
   - Each question should focus on a different aspect (vocabulary, grammar, collocations).
   - Assign difficulty from 1 (beginner) to 5 (advanced) based on word frequency and complexity in the TARGET LANGUAGE.
   - Provide translationJa as a natural Japanese translation of targetSentenceFull.

2. Generate {{numListening}} listening comprehension questions:
   - Step A: Choose a complete, meaningful fragment from the original lyrics (sourceFragment).
   - Step B: Translate it into a complete sentence in the TARGET LANGUAGE (targetSentenceFull).
   - Prefer sentences with clear grammar and, when possible, idioms or interesting expressions in the TARGET LANGUAGE.
   - Assign difficulty from 1 to 5 based on sentence length, structure, and vocabulary.
   - Provide translationJa as a natural Japanese translation of targetSentenceFull.
   - Set audioUrl to an empty string "" (the backend system will fill in an actual S3 URL later).

DIFFICULTY LEVEL GUIDELINES (for the TARGET LANGUAGE):
- Level 1: Very common words (top 1000), simple grammar.
- Level 2: Intermediate words (top 3000), basic tenses.
- Level 3: Advanced vocabulary, more complex tenses.
- Level 4: Idioms, phrasal verbs, nuanced meanings.
- Level 5: Literary expressions, rare vocabulary, complex structures.

OUTPUT FORMAT (JSON ONLY):
{
  "fillInBlank": [
    {
      "sourceFragment": "Original fragment from the lyrics (any language)",
      "targetSentenceFull": "Your translation into the TARGET LANGUAGE",
      "sentenceWithBlank": "Target sentence with _____ replacing one word",
      "blankWord": "The removed word in the TARGET LANGUAGE",
      "difficulty": 1-5,
      "translationJa": "Natural Japanese translation of targetSentenceFull",
      "explanation": "Japanese explanation of why this word/grammar is important"
    }
  ],
  "listening": [
    {
      "sourceFragment": "Original fragment from the lyrics (any language)",
      "targetSentenceFull": "Your translation into the TARGET LANGUAGE",
      "difficulty": 1-5,
      "translationJa": "Natural Japanese translation of targetSentenceFull",
      "explanation": "Japanese explanation of why this sentence is valuable for listening",
      "audioUrl": ""
    }
  ]
}

IMPORTANT:
- Return ONLY valid JSON, with no extra text or markdown.
- Do NOT wrap the JSON in code blocks.
- Do NOT invent new lyrics: every sourceFragment must appear exactly in the provided lyrics.
- Keep your translations faithful to the original meaning but natural in the TARGET LANGUAGE.
- Each question must be unique and focus on a different language aspect.

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
