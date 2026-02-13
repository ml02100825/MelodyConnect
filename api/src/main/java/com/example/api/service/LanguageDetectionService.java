package com.example.api.service;

import com.example.api.enums.LanguageCode;
import com.example.api.util.LanguageDetectionUtils;
import com.github.pemistahl.lingua.api.Language;
import com.github.pemistahl.lingua.api.LanguageDetector;
import com.github.pemistahl.lingua.api.LanguageDetectorBuilder;
import jakarta.annotation.PostConstruct;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

/**
 * 歌詞テキストから言語を検出するサービス。
 * lingua ライブラリを第一優先とし、検出不可の場合は Unicode ブロック判定にフォールバックする。
 */
@Service
public class LanguageDetectionService {

    private static final Logger logger = LoggerFactory.getLogger(LanguageDetectionService.class);

    private LanguageDetector detector;

    @PostConstruct
    public void init() {
        this.detector = LanguageDetectorBuilder
            .fromLanguages(
                Language.JAPANESE,
                Language.ENGLISH,
                Language.KOREAN,
                Language.CHINESE,
                Language.SPANISH,
                Language.FRENCH
            )
            .build();
        logger.info("lingua LanguageDetector を初期化しました");
    }

    /**
     * テキストから言語を検出し、ISO 639-1 コード（"ja", "en" 等）を返す。
     * lingua で検出できない場合は Unicode ブロック判定にフォールバックする。
     *
     * @param text 検出対象テキスト
     * @return ISO 639-1 言語コード（検出不可の場合は null）
     */
    public String detectLanguage(String text) {
        if (text == null || text.isBlank()) {
            return null;
        }

        // 1. lingua で検出
        Language detected = detector.detectLanguageOf(text);
        if (detected != Language.UNKNOWN) {
            // IsoCode639_1 は enum（JA, EN 等）なので name().toLowerCase() で "ja", "en" 等に変換
            String isoCode = detected.getIsoCode639_1().name().toLowerCase();
            logger.debug("lingua 言語検出: {} → {}", detected, isoCode);
            return isoCode;
        }

        // 2. フォールバック: Unicode ブロック判定
        logger.debug("lingua 検出不可。Unicode ブロック判定にフォールバック");
        LanguageCode fallback = LanguageDetectionUtils.detectFromCharacters(text);
        if (fallback != null && fallback.isValid()) {
            logger.debug("Unicode ブロック判定: {}", fallback.getCode());
            return fallback.getCode();
        }

        return null;
    }
}
