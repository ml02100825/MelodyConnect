package com.example.api.client.impl;

import com.example.api.client.WordnikApiClient;
import com.example.api.dto.WordnikWordInfo;
import org.springframework.stereotype.Component;

import java.util.Arrays;

/**
 * Wordnik API Client のモック実装
 * TODO: 実際のAPI統合時に削除または @Profile("mock") を追加
 */
@Component
public class WordnikApiClientMock implements WordnikApiClient {

    @Override
    public WordnikWordInfo getWordInfo(String word) {
        // モックデータを返す
        return WordnikWordInfo.builder()
            .word(word)
            .meaningJa("（モックデータ）意味")
            .pronunciation("/wɜːrd/")
            .partOfSpeech("noun")
            .exampleSentence("This is an example sentence with " + word)
            .exampleTranslate("これは" + word + "を含む例文です")
            .audioUrl(null)
            .definitions(Arrays.asList(
                WordnikWordInfo.Definition.builder()
                    .text("Mock definition for " + word)
                    .partOfSpeech("noun")
                    .source("mock")
                    .build()
            ))
            .build();
    }
}
