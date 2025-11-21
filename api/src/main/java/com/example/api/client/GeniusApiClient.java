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

    /**
     * 曲を検索してGenius Song IDを取得
     *
     * @param songTitle 曲名
     * @param artistName アーティスト名
     * @return Genius Song ID（見つからない場合はnull）
     */
    Long searchSong(String songTitle, String artistName);

    /**
     * 曲を検索して歌詞を取得（複数候補を優先度順に試行）
     * 検索結果の候補を優先度順に試し、最初に成功した歌詞を返す
     *
     * @param songTitle 曲名
     * @param artistName アーティスト名
     * @return 歌詞テキスト（見つからない、またはすべてローマ字版の場合はnull）
     */
    String searchAndGetLyrics(String songTitle, String artistName);
}
