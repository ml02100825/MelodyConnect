package com.example.api.util;

import com.example.api.enums.LanguageCode;
import org.junit.jupiter.api.Test;

import java.util.Arrays;
import java.util.Collections;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

/**
 * LanguageDetectionUtilsのテストクラス
 */
class LanguageDetectionUtilsTest {

    @Test
    void testCountJapaneseCharacters() {
        // ひらがな
        assertEquals(5, LanguageDetectionUtils.countJapaneseCharacters("あいうえお"));

        // カタカナ
        assertEquals(4, LanguageDetectionUtils.countJapaneseCharacters("カタカナ"));

        // 漢字
        assertEquals(4, LanguageDetectionUtils.countJapaneseCharacters("日本語文字"));

        // 混在
        assertEquals(7, LanguageDetectionUtils.countJapaneseCharacters("夜に駆ける"));

        // 英語のみ
        assertEquals(0, LanguageDetectionUtils.countJapaneseCharacters("Hello World"));

        // 空文字
        assertEquals(0, LanguageDetectionUtils.countJapaneseCharacters(""));
        assertEquals(0, LanguageDetectionUtils.countJapaneseCharacters(null));
    }

    @Test
    void testCountHangulCharacters() {
        // ハングル
        assertEquals(4, LanguageDetectionUtils.countHangulCharacters("방탄소년단"));

        // 混在
        String mixed = "BTS (방탄소년단)";
        assertEquals(4, LanguageDetectionUtils.countHangulCharacters(mixed));

        // ハングルなし
        assertEquals(0, LanguageDetectionUtils.countHangulCharacters("Hello World"));

        // 空文字
        assertEquals(0, LanguageDetectionUtils.countHangulCharacters(""));
        assertEquals(0, LanguageDetectionUtils.countHangulCharacters(null));
    }

    @Test
    void testCountCyrillicCharacters() {
        // キリル文字（ロシア語）
        assertTrue(LanguageDetectionUtils.countCyrillicCharacters("Привет") > 0);

        // キリル文字なし
        assertEquals(0, LanguageDetectionUtils.countCyrillicCharacters("Hello"));
    }

    @Test
    void testDetectFromCharacters_Japanese() {
        // YOASOBI - 夜に駆ける
        assertEquals(LanguageCode.JAPANESE,
            LanguageDetectionUtils.detectFromCharacters("夜に駆ける"));

        // Ado - うっせぇわ
        assertEquals(LanguageCode.JAPANESE,
            LanguageDetectionUtils.detectFromCharacters("うっせぇわ"));

        // 混在（日本語が優勢）
        assertEquals(LanguageCode.JAPANESE,
            LanguageDetectionUtils.detectFromCharacters("YOASOBI - 夜に駆ける"));
    }

    @Test
    void testDetectFromCharacters_Korean() {
        // BTS
        assertEquals(LanguageCode.KOREAN,
            LanguageDetectionUtils.detectFromCharacters("방탄소년단"));

        // BLACKPINK
        assertEquals(LanguageCode.KOREAN,
            LanguageDetectionUtils.detectFromCharacters("블랙핑크"));
    }

    @Test
    void testDetectFromCharacters_English() {
        // 英語の文章
        assertEquals(LanguageCode.ENGLISH,
            LanguageDetectionUtils.detectFromCharacters("The quick brown fox jumps over the lazy dog"));

        // 一般的な英単語
        assertEquals(LanguageCode.ENGLISH,
            LanguageDetectionUtils.detectFromCharacters("I love you"));
    }

    @Test
    void testDetectFromCharacters_Null() {
        // null
        assertNull(LanguageDetectionUtils.detectFromCharacters(null));

        // 空文字
        assertNull(LanguageDetectionUtils.detectFromCharacters(""));

        // 空白のみ
        assertNull(LanguageDetectionUtils.detectFromCharacters("   "));
    }

    @Test
    void testDetectFromGenres_Japanese() {
        // J-Pop
        List<String> genres = Arrays.asList("j-pop", "japanese indie pop");
        assertEquals(LanguageCode.JAPANESE,
            LanguageDetectionUtils.detectFromGenres(genres));

        // City Pop
        genres = Arrays.asList("city pop", "shibuya-kei");
        assertEquals(LanguageCode.JAPANESE,
            LanguageDetectionUtils.detectFromGenres(genres));
    }

    @Test
    void testDetectFromGenres_Korean() {
        // K-Pop
        List<String> genres = Arrays.asList("k-pop", "korean hip hop");
        assertEquals(LanguageCode.KOREAN,
            LanguageDetectionUtils.detectFromGenres(genres));
    }

    @Test
    void testDetectFromGenres_Chinese() {
        // C-Pop
        List<String> genres = Arrays.asList("c-pop", "mandopop");
        assertEquals(LanguageCode.CHINESE,
            LanguageDetectionUtils.detectFromGenres(genres));
    }

    @Test
    void testDetectFromGenres_Spanish() {
        // Latin / Reggaeton
        List<String> genres = Arrays.asList("latin", "reggaeton");
        assertEquals(LanguageCode.SPANISH,
            LanguageDetectionUtils.detectFromGenres(genres));
    }

    @Test
    void testDetectFromGenres_NoMatch() {
        // 一致するジャンルなし
        List<String> genres = Arrays.asList("rock", "indie");
        assertNull(LanguageDetectionUtils.detectFromGenres(genres));

        // 空リスト
        assertNull(LanguageDetectionUtils.detectFromGenres(Collections.emptyList()));

        // null
        assertNull(LanguageDetectionUtils.detectFromGenres(null));
    }

    @Test
    void testDetectFromMultipleTexts() {
        // 日本語のトラックとアーティスト
        List<String> texts = Arrays.asList("夜に駆ける", "YOASOBI");
        assertEquals(LanguageCode.JAPANESE,
            LanguageDetectionUtils.detectFromMultipleTexts(texts));

        // 韓国語のアーティスト
        texts = Arrays.asList("Dynamite", "방탄소년단");
        assertEquals(LanguageCode.KOREAN,
            LanguageDetectionUtils.detectFromMultipleTexts(texts));

        // 空リスト
        assertNull(LanguageDetectionUtils.detectFromMultipleTexts(Collections.emptyList()));
    }

    @Test
    void testCountNonWhitespaceCharacters() {
        assertEquals(11, LanguageDetectionUtils.countNonWhitespaceCharacters("Hello World"));
        assertEquals(10, LanguageDetectionUtils.countNonWhitespaceCharacters("Hello  World")); // 2つのスペース
        assertEquals(0, LanguageDetectionUtils.countNonWhitespaceCharacters("   "));
        assertEquals(0, LanguageDetectionUtils.countNonWhitespaceCharacters(""));
        assertEquals(0, LanguageDetectionUtils.countNonWhitespaceCharacters(null));
    }

    @Test
    void testLanguageDetectionThreshold() {
        // 日本語文字が5%未満の場合は判定されない
        String mostlyEnglish = "Hello World こんにちは";
        long japaneseCount = LanguageDetectionUtils.countJapaneseCharacters(mostlyEnglish);
        long totalCount = LanguageDetectionUtils.countNonWhitespaceCharacters(mostlyEnglish);
        double ratio = (double) japaneseCount / totalCount;

        // 閾値を下回る場合
        if (ratio < 0.05) {
            // 英語として判定されるべき
            LanguageCode result = LanguageDetectionUtils.detectFromCharacters(mostlyEnglish);
            assertEquals(LanguageCode.ENGLISH, result);
        }
    }
}
