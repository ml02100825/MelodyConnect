package com.example.api.client;

import com.example.api.dto.WordnikWordInfo;

/**
 * Wordnik API Client Interface
 * TODO: 実際のAPI統合時に実装を追加
 */
public interface WordnikApiClient {

    /**
     * 単語の詳細情報を取得
     *
     * @param word 検索する単語
     * @return 単語の詳細情報
     */
    WordnikWordInfo getWordInfo(String word);
}
