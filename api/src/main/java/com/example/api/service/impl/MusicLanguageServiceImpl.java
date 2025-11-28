package com.example.api.service.impl;

import com.example.api.client.GeniusApiClient;
import com.example.api.client.SpotifyApiClient;
import com.example.api.enums.LanguageCode;
import com.example.api.service.MusicLanguageService;
import com.example.api.util.LanguageDetectionUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.Arrays;
import java.util.List;

/**
 * 音楽の言語判定サービス実装
 * 複数のソースから言語を判定する複合アプローチを使用
 */
@Service
public class MusicLanguageServiceImpl implements MusicLanguageService {

    private static final Logger logger = LoggerFactory.getLogger(MusicLanguageServiceImpl.class);

    @Autowired(required = false)
    private SpotifyApiClient spotifyApiClient;

    @Autowired(required = false)
    private GeniusApiClient geniusApiClient;

    @Override
    public LanguageCode detectLanguage(String spotifyTrackId) {
        logger.info("言語判定開始: spotifyTrackId={}", spotifyTrackId);

        if (spotifyTrackId == null || spotifyTrackId.isEmpty()) {
            logger.warn("Spotify Track IDが指定されていません");
            return LanguageCode.ENGLISH;
        }

        // Spotify APIクライアントが利用できない場合はデフォルト
        if (spotifyApiClient == null) {
            logger.warn("SpotifyApiClientが利用できません");
            return LanguageCode.ENGLISH;
        }

        // TODO: Spotify APIからトラック情報を取得
        // 現在のSpotifyApiClientにはトラックIDから情報を取得するメソッドがないため、
        // 将来的に実装が必要
        logger.debug("Spotify APIからのトラック情報取得は未実装");

        return LanguageCode.ENGLISH;
    }

    @Override
    public LanguageCode detectLanguageFromNames(String trackName, String artistName) {
        logger.info("言語判定開始: trackName={}, artistName={}", trackName, artistName);

        if ((trackName == null || trackName.isEmpty()) && (artistName == null || artistName.isEmpty())) {
            logger.warn("トラック名とアーティスト名が両方とも空です");
            return LanguageCode.ENGLISH;
        }

        // 優先度1: 文字種判定（トラック名・アーティスト名）
        List<String> names = Arrays.asList(
            trackName != null ? trackName : "",
            artistName != null ? artistName : ""
        );
        LanguageCode langFromNames = LanguageDetectionUtils.detectFromMultipleTexts(names);
        if (langFromNames != null && langFromNames.isValid()) {
            logger.info("文字種判定で言語を特定: {}", langFromNames);
            return langFromNames;
        }

        // 優先度2: Genius API歌詞分析（利用可能な場合）
        if (geniusApiClient != null && trackName != null && artistName != null) {
            try {
                logger.debug("Genius APIで歌詞を検索して言語を判定します");
                GeniusApiClient.LyricsResult lyricsResult = geniusApiClient.searchAndGetLyricsWithMetadata(trackName, artistName);

                if (lyricsResult != null) {
                    String detectedLang = lyricsResult.getDetectedLanguage();
                    if (detectedLang != null && !detectedLang.isEmpty()) {
                        LanguageCode langCode = LanguageCode.fromCode(detectedLang);
                        if (langCode.isValid()) {
                            logger.info("歌詞分析で言語を特定: {}", langCode);
                            return langCode;
                        }
                    }
                }
            } catch (Exception e) {
                logger.debug("歌詞取得中にエラーが発生しました: {}", e.getMessage());
            }
        }

        // デフォルト: 英語
        logger.info("言語を特定できませんでした。デフォルトの英語を返します");
        return LanguageCode.ENGLISH;
    }

    @Override
    public LanguageCode detectLanguageFromLyrics(String lyrics) {
        logger.debug("歌詞から言語を判定: lyrics_length={}", lyrics != null ? lyrics.length() : 0);

        if (lyrics == null || lyrics.trim().isEmpty()) {
            logger.warn("歌詞が空です");
            return LanguageCode.UNKNOWN;
        }

        LanguageCode detected = LanguageDetectionUtils.detectFromCharacters(lyrics);
        if (detected != null && detected.isValid()) {
            logger.info("歌詞から言語を特定: {}", detected);
            return detected;
        }

        logger.debug("歌詞から言語を特定できませんでした");
        return LanguageCode.UNKNOWN;
    }
}
