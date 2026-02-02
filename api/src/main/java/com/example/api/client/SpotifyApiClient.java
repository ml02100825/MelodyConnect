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
     * ジャンル名からアーティストを検索
     *
     * @param genreName ジャンル名
     * @param limit     取得上限
     * @return アーティストリスト
     */
    List<SpotifyArtistDto> searchArtistsByGenre(String genreName, int limit);

    /**
     * アーティストIDからランダムな楽曲を取得
     *
     * @param artistId アーティストID
     * @return 楽曲情報
     */
    Song getRandomSongByArtist(Integer artistId);

    /**
     * SpotifyアーティストIDからランダムな楽曲を取得
     *
     * @param spotifyArtistId SpotifyアーティストID
     * @return 楽曲情報
     */
    Song getRandomSongBySpotifyArtistId(String spotifyArtistId);

    /**
     * SpotifyアーティストIDから全曲を取得
     * アーティストの全アルバムから全トラックを取得します
     *
     * @param spotifyArtistId SpotifyアーティストID
     * @return 楽曲リスト
     */
    List<Song> getAllSongsByArtist(String spotifyArtistId);

    /**
     * ★ 変更 ★
     * ジャンル名からランダムな楽曲を取得（5曲）
     * 
     * 処理フロー:
     * 1. ジャンル名でArtistを絞り込み、ランダムに1人選択
     * 2. そのアーティストの楽曲をSongテーブルから取得
     * 3. Songテーブルに曲がなければSpotify APIから取得して保存
     * 4. ランダムに5曲返却
     *
     * @param genreName ジャンル名
     * @return 楽曲リスト（最大5曲）
     */
    List<Song> getRandomSongsByGenre(String genreName);

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
