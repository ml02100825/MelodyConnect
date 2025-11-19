package com.example.api.client;

import com.example.api.dto.SpotifyArtistDto;
import com.example.api.entity.Song;

import java.util.List;

/**
 * Spotify API Client Interface
 * 楽曲検索機能を提供
 */
public interface SpotifyApiClient {

    /**
     * アーティスト名で検索
     *
     * @param query 検索クエリ
     * @param limit 取得件数
     * @return アーティストリスト
     */
    List<SpotifyArtistDto> searchArtists(String query, int limit);

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

    /**
     * 楽曲名とアーティスト名で検索
     *
     * @param songName 楽曲名
     * @param artistName アーティスト名
     * @return 楽曲情報
     */
    Song searchSong(String songName, String artistName);

    /**
     * 人気アーティストを取得（開発用）
     * 様々なジャンルから人気アーティストを取得
     *
     * @param limit 取得件数
     * @return アーティストリスト
     */
    List<SpotifyArtistDto> getPopularArtists(int limit);
}
