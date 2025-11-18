package com.example.api.client;

import com.example.api.entity.Song;

/**
 * Apple Music API Client Interface
 * TODO: 実際のAPI統合時に実装を追加
 */
public interface AppleMusicApiClient {

    /**
     * アーティストIDからランダムな楽曲を取得
     *
     * @param artistId アーティストID
     * @return 楽曲情報
     */
    Song getRandomSongByArtist(Integer artistId);

    /**
     * ジャンル名からランダムな楽曲を取得
     *
     * @param genreName ジャンル名
     * @return 楽曲情報
     */
    Song getRandomSongByGenre(String genreName);

    /**
     * 完全ランダムで楽曲を取得
     *
     * @return 楽曲情報
     */
    Song getRandomSong();
}
