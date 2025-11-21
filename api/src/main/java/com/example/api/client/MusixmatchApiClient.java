package com.example.api.client;

/**
 * Musixmatch API Client Interface
 * Musixmatch APIを使用して歌詞を取得
 * Geniusのフォールバックとして使用
 */
public interface MusixmatchApiClient {

    /**
     * アーティスト名と曲名から歌詞を取得
     *
     * @param artistName アーティスト名
     * @param trackName 曲名
     * @return 歌詞（取得できない場合はnull）
     */
    String getLyrics(String artistName, String trackName);

    /**
     * Musixmatch Track IDから歌詞を取得
     *
     * @param trackId Musixmatch Track ID
     * @return 歌詞（取得できない場合はnull）
     */
    String getLyricsByTrackId(Long trackId);
}
