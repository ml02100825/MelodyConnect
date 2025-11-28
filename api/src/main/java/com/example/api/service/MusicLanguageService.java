package com.example.api.service;

import com.example.api.enums.LanguageCode;

/**
 * 音楽の言語判定サービス
 * Spotify API、Genius API、文字種分析などを組み合わせて楽曲の言語を判定
 */
public interface MusicLanguageService {

    /**
     * Spotifyトラックから言語を判定
     * 以下の優先度順で判定を試行：
     * 1. トラック名・アーティスト名の文字種分析
     * 2. Spotifyのジャンル情報
     * 3. Genius APIで取得した歌詞の分析
     * 4. デフォルト（ENGLISH）
     *
     * @param spotifyTrackId Spotify Track ID
     * @return 判定された言語コード
     */
    LanguageCode detectLanguage(String spotifyTrackId);

    /**
     * トラック名とアーティスト名から言語を判定（Spotify APIなしで使える）
     * 文字種分析とGenius API歌詞分析を組み合わせて判定
     *
     * @param trackName トラック名
     * @param artistName アーティスト名
     * @return 判定された言語コード
     */
    LanguageCode detectLanguageFromNames(String trackName, String artistName);

    /**
     * 歌詞テキストから言語を判定
     * 既に歌詞が取得済みの場合に使用
     *
     * @param lyrics 歌詞テキスト
     * @return 判定された言語コード
     */
    LanguageCode detectLanguageFromLyrics(String lyrics);
}
