package com.example.api.util;

import com.example.api.enums.LanguageCode;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.List;

/**
 * 言語検出ユーティリティクラス
 * テキストや各種情報から言語を判定する共通ロジックを提供
 */
public class LanguageDetectionUtils {

    private static final Logger logger = LoggerFactory.getLogger(LanguageDetectionUtils.class);

    // 言語判定の閾値（全体の文字数に対する割合）
    private static final double LANGUAGE_DETECTION_THRESHOLD = 0.05; // 5%

    /**
     * テキストに含まれる日本語文字数をカウント
     * ひらがな、カタカナ、漢字を日本語文字としてカウント
     *
     * @param text 分析対象テキスト
     * @return 日本語文字数
     */
    public static long countJapaneseCharacters(String text) {
        if (text == null || text.isEmpty()) {
            return 0;
        }

        return text.chars()
            .filter(c -> (c >= 0x3040 && c <= 0x309F) ||  // ひらがな: U+3040-U+309F
                         (c >= 0x30A0 && c <= 0x30FF) ||  // カタカナ: U+30A0-U+30FF
                         (c >= 0x4E00 && c <= 0x9FAF))    // 漢字 (CJK): U+4E00-U+9FAF
            .count();
    }

    /**
     * テキストに含まれるハングル文字数をカウント
     *
     * @param text 分析対象テキスト
     * @return ハングル文字数
     */
    public static long countHangulCharacters(String text) {
        if (text == null || text.isEmpty()) {
            return 0;
        }

        return text.chars()
            .filter(c -> c >= 0xAC00 && c <= 0xD7AF)  // ハングル: U+AC00-U+D7AF
            .count();
    }

    /**
     * テキストに含まれる中国語（簡体字・繁体字）文字数をカウント
     *
     * @param text 分析対象テキスト
     * @return 中国語文字数
     */
    public static long countChineseCharacters(String text) {
        if (text == null || text.isEmpty()) {
            return 0;
        }

        // CJK統合漢字（中国語で使用される文字）
        // 注: 日本語の漢字と重複するため、日本語判定と組み合わせて使用
        return text.chars()
            .filter(c -> (c >= 0x4E00 && c <= 0x9FFF) ||  // CJK統合漢字
                         (c >= 0x3400 && c <= 0x4DBF))     // CJK統合漢字拡張A
            .count();
    }

    /**
     * テキストに含まれるキリル文字数をカウント（ロシア語など）
     *
     * @param text 分析対象テキスト
     * @return キリル文字数
     */
    public static long countCyrillicCharacters(String text) {
        if (text == null || text.isEmpty()) {
            return 0;
        }

        return text.chars()
            .filter(c -> c >= 0x0400 && c <= 0x04FF)  // キリル文字: U+0400-U+04FF
            .count();
    }

    /**
     * 空白以外の全文字数をカウント
     *
     * @param text 分析対象テキスト
     * @return 空白以外の文字数
     */
    public static long countNonWhitespaceCharacters(String text) {
        if (text == null || text.isEmpty()) {
            return 0;
        }

        return text.chars()
            .filter(c -> !Character.isWhitespace(c))
            .count();
    }

    /**
     * 文字種から言語を推測
     * テキストに含まれる特定の文字種の割合から言語を判定
     *
     * @param text 分析対象テキスト
     * @return 判定された言語コード（判定不可の場合null）
     */
    public static LanguageCode detectFromCharacters(String text) {
        if (text == null || text.trim().isEmpty()) {
            return null;
        }

        long totalChars = countNonWhitespaceCharacters(text);
        if (totalChars == 0) {
            return null;
        }

        // ハングル判定（韓国語）
        long hangulCount = countHangulCharacters(text);
        double hangulRatio = (double) hangulCount / totalChars;
        if (hangulRatio >= LANGUAGE_DETECTION_THRESHOLD) {
            logger.debug("文字種判定: 韓国語 (ハングル {}/{} = {:.2f}%)",
                hangulCount, totalChars, hangulRatio * 100);
            return LanguageCode.KOREAN;
        }

        // 日本語判定（ひらがな・カタカナ・漢字）
        long japaneseCount = countJapaneseCharacters(text);
        double japaneseRatio = (double) japaneseCount / totalChars;
        if (japaneseRatio >= LANGUAGE_DETECTION_THRESHOLD) {
            logger.debug("文字種判定: 日本語 (日本語文字 {}/{} = {:.2f}%)",
                japaneseCount, totalChars, japaneseRatio * 100);
            return LanguageCode.JAPANESE;
        }

        // キリル文字判定（ロシア語）
        long cyrillicCount = countCyrillicCharacters(text);
        double cyrillicRatio = (double) cyrillicCount / totalChars;
        if (cyrillicRatio >= LANGUAGE_DETECTION_THRESHOLD) {
            logger.debug("文字種判定: ロシア語 (キリル文字 {}/{} = {:.2f}%)",
                cyrillicCount, totalChars, cyrillicRatio * 100);
            return LanguageCode.RUSSIAN;
        }

        // 英語の一般的な単語が含まれているか確認
        String lowerText = text.toLowerCase();
        if (lowerText.matches(".*\\b(the|and|you|me|my|your|love|like|that|this|was|were|are|have|has|will|can|would)\\b.*")) {
            logger.debug("文字種判定: 英語（一般的な英単語を検出）");
            return LanguageCode.ENGLISH;
        }

        // 判定不可
        logger.debug("文字種判定: 判定不可");
        return null;
    }

    /**
     * Spotifyのジャンルリストから言語を推測
     * ジャンル名に含まれる言語キーワードから判定
     *
     * @param genres Spotifyのジャンルリスト
     * @return 判定された言語コード（判定不可の場合null）
     */
    public static LanguageCode detectFromGenres(List<String> genres) {
        if (genres == null || genres.isEmpty()) {
            return null;
        }

        String genresLower = String.join(" ", genres).toLowerCase();

        // 日本語関連ジャンル
        if (genresLower.contains("j-pop") ||
            genresLower.contains("japanese") ||
            genresLower.contains("j-rock") ||
            genresLower.contains("city pop") ||
            genresLower.contains("shibuya-kei") ||
            genresLower.contains("enka")) {
            logger.debug("ジャンル判定: 日本語 (genres={})", genres);
            return LanguageCode.JAPANESE;
        }

        // 韓国語関連ジャンル
        if (genresLower.contains("k-pop") ||
            genresLower.contains("korean") ||
            genresLower.contains("k-rap") ||
            genresLower.contains("k-indie")) {
            logger.debug("ジャンル判定: 韓国語 (genres={})", genres);
            return LanguageCode.KOREAN;
        }

        // 中国語関連ジャンル
        if (genresLower.contains("c-pop") ||
            genresLower.contains("mandopop") ||
            genresLower.contains("cantopop") ||
            genresLower.contains("chinese")) {
            logger.debug("ジャンル判定: 中国語 (genres={})", genres);
            return LanguageCode.CHINESE;
        }

        // スペイン語関連ジャンル
        if (genresLower.contains("latin") ||
            genresLower.contains("reggaeton") ||
            genresLower.contains("spanish") ||
            genresLower.contains("salsa") ||
            genresLower.contains("bachata")) {
            logger.debug("ジャンル判定: スペイン語 (genres={})", genres);
            return LanguageCode.SPANISH;
        }

        // フランス語関連ジャンル
        if (genresLower.contains("french") ||
            genresLower.contains("chanson")) {
            logger.debug("ジャンル判定: フランス語 (genres={})", genres);
            return LanguageCode.FRENCH;
        }

        // ドイツ語関連ジャンル
        if (genresLower.contains("german") ||
            genresLower.contains("neue deutsche welle")) {
            logger.debug("ジャンル判定: ドイツ語 (genres={})", genres);
            return LanguageCode.GERMAN;
        }

        // ロシア語関連ジャンル
        if (genresLower.contains("russian")) {
            logger.debug("ジャンル判定: ロシア語 (genres={})", genres);
            return LanguageCode.RUSSIAN;
        }

        logger.debug("ジャンル判定: 判定不可 (genres={})", genres);
        return null;
    }

    /**
     * 複数のテキストソースから言語を判定
     * トラック名、アーティスト名などを組み合わせて判定
     *
     * @param texts 分析対象テキストのリスト
     * @return 判定された言語コード（判定不可の場合null）
     */
    public static LanguageCode detectFromMultipleTexts(List<String> texts) {
        if (texts == null || texts.isEmpty()) {
            return null;
        }

        // 全テキストを結合して判定
        String combinedText = String.join(" ", texts);
        return detectFromCharacters(combinedText);
    }
}
