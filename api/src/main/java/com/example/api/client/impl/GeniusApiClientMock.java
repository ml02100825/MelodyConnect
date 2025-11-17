package com.example.api.client.impl;

import com.example.api.client.GeniusApiClient;
import org.springframework.stereotype.Component;

/**
 * Genius API Client のモック実装
 * TODO: 実際のAPI統合時に削除または @Profile("mock") を追加
 */
@Component
public class GeniusApiClientMock implements GeniusApiClient {

    private static final String MOCK_LYRICS =
        "I went to the store yesterday\n" +
        "She is singing beautifully\n" +
        "The cat sat on the mat\n" +
        "We are learning English together\n" +
        "He plays guitar every day\n" +
        "They traveled around the world\n" +
        "The sun rises in the east\n" +
        "I love listening to music\n" +
        "She dances gracefully\n" +
        "We will meet tomorrow";

    @Override
    public String getLyrics(Long geniusSongId) {
        // モックの歌詞を返す
        return MOCK_LYRICS;
    }

    @Override
    public String getLyricsByUrl(String songUrl) {
        // モックの歌詞を返す
        return MOCK_LYRICS;
    }
}
