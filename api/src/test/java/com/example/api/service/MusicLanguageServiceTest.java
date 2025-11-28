package com.example.api.service;

import com.example.api.client.GeniusApiClient;
import com.example.api.enums.LanguageCode;
import com.example.api.service.impl.MusicLanguageServiceImpl;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

/**
 * MusicLanguageServiceのテストクラス
 */
class MusicLanguageServiceTest {

    @Mock
    private GeniusApiClient geniusApiClient;

    @InjectMocks
    private MusicLanguageServiceImpl musicLanguageService;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
    }

    @Test
    void testDetectJapaneseFromTrackName() {
        // YOASOBI - 夜に駆ける
        LanguageCode result = musicLanguageService.detectLanguageFromNames("夜に駆ける", "YOASOBI");
        assertEquals(LanguageCode.JAPANESE, result);
    }

    @Test
    void testDetectJapaneseFromArtistName() {
        // Ado - うっせぇわ
        LanguageCode result = musicLanguageService.detectLanguageFromNames("うっせぇわ", "Ado");
        assertEquals(LanguageCode.JAPANESE, result);
    }

    @Test
    void testDetectKoreanFromArtistName() {
        // BTS - Dynamite
        LanguageCode result = musicLanguageService.detectLanguageFromNames("Dynamite", "방탄소년단");
        assertEquals(LanguageCode.KOREAN, result);
    }

    @Test
    void testDetectKoreanFromTrackName() {
        // BLACKPINK
        LanguageCode result = musicLanguageService.detectLanguageFromNames("블랙핑크", "BLACKPINK");
        assertEquals(LanguageCode.KOREAN, result);
    }

    @Test
    void testDetectEnglishDefault() {
        // 英語のトラック（文字種判定で判定できない場合）
        LanguageCode result = musicLanguageService.detectLanguageFromNames("Shape of You", "Ed Sheeran");
        assertEquals(LanguageCode.ENGLISH, result);
    }

    @Test
    void testDetectLanguageFromLyrics_Japanese() {
        String japaneseLyrics = "君と見た夢を\n僕は覚えている\n二人で歩いた道を";
        LanguageCode result = musicLanguageService.detectLanguageFromLyrics(japaneseLyrics);
        assertEquals(LanguageCode.JAPANESE, result);
    }

    @Test
    void testDetectLanguageFromLyrics_Korean() {
        String koreanLyrics = "너와 함께한 시간들\n나는 기억하고 있어";
        LanguageCode result = musicLanguageService.detectLanguageFromLyrics(koreanLyrics);
        assertEquals(LanguageCode.KOREAN, result);
    }

    @Test
    void testDetectLanguageFromLyrics_English() {
        String englishLyrics = "I will always love you\nNo matter what happens";
        LanguageCode result = musicLanguageService.detectLanguageFromLyrics(englishLyrics);
        assertEquals(LanguageCode.ENGLISH, result);
    }

    @Test
    void testDetectLanguageFromLyrics_Empty() {
        LanguageCode result = musicLanguageService.detectLanguageFromLyrics("");
        assertEquals(LanguageCode.UNKNOWN, result);
    }

    @Test
    void testDetectLanguageFromLyrics_Null() {
        LanguageCode result = musicLanguageService.detectLanguageFromLyrics(null);
        assertEquals(LanguageCode.UNKNOWN, result);
    }

    @Test
    void testDetectLanguageFromNames_NullInputs() {
        // 両方null
        LanguageCode result = musicLanguageService.detectLanguageFromNames(null, null);
        assertEquals(LanguageCode.ENGLISH, result);

        // トラック名のみnull
        result = musicLanguageService.detectLanguageFromNames(null, "Artist");
        // アーティスト名に日本語文字がないためデフォルト
        assertEquals(LanguageCode.ENGLISH, result);

        // アーティスト名のみnull
        result = musicLanguageService.detectLanguageFromNames("Track", null);
        assertEquals(LanguageCode.ENGLISH, result);
    }

    @Test
    void testDetectLanguageWithGeniusApiFallback() {
        // 文字種判定で判定できない場合、Genius APIにフォールバック
        GeniusApiClient.LyricsResult mockResult = new GeniusApiClient.LyricsResult(
            "日本語の歌詞",
            12345L,
            "ja"
        );

        when(geniusApiClient.searchAndGetLyricsWithMetadata(anyString(), anyString()))
            .thenReturn(mockResult);

        LanguageCode result = musicLanguageService.detectLanguageFromNames("English Title", "English Artist");

        // Genius APIから取得した言語コードを使用
        assertEquals(LanguageCode.JAPANESE, result);
        verify(geniusApiClient, times(1)).searchAndGetLyricsWithMetadata(anyString(), anyString());
    }

    @Test
    void testDetectLanguageWithGeniusApiError() {
        // Genius APIでエラーが発生した場合
        when(geniusApiClient.searchAndGetLyricsWithMetadata(anyString(), anyString()))
            .thenThrow(new RuntimeException("API Error"));

        LanguageCode result = musicLanguageService.detectLanguageFromNames("Track", "Artist");

        // エラー時はデフォルトの英語
        assertEquals(LanguageCode.ENGLISH, result);
    }
}
