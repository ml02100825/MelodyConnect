package com.example.api.client.impl;

import com.example.api.client.ClaudeApiClient;
import com.example.api.dto.ClaudeQuestionResponse;
import com.example.api.dto.ClaudeQuestionResponse.Question;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.List;

/**
 * Claude API Client のモック実装
 * TODO: 実際のAPI統合時に削除または @Profile("mock") を追加
 */
@Component
public class ClaudeApiClientMock implements ClaudeApiClient {

    @Override
    public ClaudeQuestionResponse generateQuestions(
        String lyrics,
        Integer fillInBlankCount,
        Integer listeningCount
    ) {
        // モックデータを生成
        List<Question> fillInBlankQuestions = new ArrayList<>();
        List<Question> listeningQuestions = new ArrayList<>();

        // 虫食い問題のモックデータ
        for (int i = 0; i < fillInBlankCount; i++) {
            fillInBlankQuestions.add(Question.builder()
                .sentence("I ____ to the store yesterday")
                .blankWord("went")
                .difficulty(2)
                .explanation("過去形の不規則動詞")
                .build());
        }

        // リスニング問題のモックデータ
        for (int i = 0; i < listeningCount; i++) {
            listeningQuestions.add(Question.builder()
                .sentence("She is singing beautifully")
                .blankWord("beautifully")
                .difficulty(3)
                .explanation("副詞の使用")
                .audioUrl(null) // TODO: TTS実装後に追加
                .build());
        }

        return ClaudeQuestionResponse.builder()
            .fillInBlank(fillInBlankQuestions)
            .listening(listeningQuestions)
            .build();
    }
}
