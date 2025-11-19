package com.example.api.client;

/**
 * Genius API Client Interface
 * TODO: 実際のAPI統合時に実装を追加
 */
public interface GeniusApiClient {

    /**
     * 楽曲IDから歌詞を取得
     *
     * @param geniusSongId Genius APIの楽曲ID
     * @return 歌詞テキスト
     */
    String getLyrics(Long geniusSongId);

    /**
     * 楽曲URLから歌詞を取得
     *
     * @param songUrl 楽曲のURL
     * @return 歌詞テキスト
     */
    String getLyricsByUrl(String songUrl);
}
