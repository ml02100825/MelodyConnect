package com.example.api.service;

import com.fasterxml.jackson.databind.JsonNode;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

/**
 * Genius API 検索結果から翻訳版・ローマ字版を除外し、
 * オリジナル歌詞エントリのみを返すフィルタリングサービス。
 */
@Service
public class GeniusLyricsFilterService {

    private static final Logger logger = LoggerFactory.getLogger(GeniusLyricsFilterService.class);

    /** 翻訳/ローマ字版のアーティスト名パターン（小文字） */
    private static final List<String> TRANSLATION_ARTIST_PATTERNS = List.of(
        "genius english translations",
        "genius romanizations",
        "genius french translations",
        "genius spanish translations",
        "genius german translations",
        "genius korean translations",
        "genius japanese translations",
        "genius portuguese translations",
        "genius italian translations",
        "genius translations"
    );

    /** タイトルに含まれる翻訳版の典型パターン（小文字） */
    private static final List<String> TRANSLATION_TITLE_PATTERNS = List.of(
        "english translation",
        "romanized",
        "romanization",
        "romanisation",
        "traducción",
        "traduction",
        "翻訳"
    );

    /**
     * Genius API 検索結果の hits 配列からオリジナル歌詞のエントリのみを抽出する。
     *
     * @param hits Genius API の検索レスポンスの hits 配列（JsonNodeのリスト）
     * @return オリジナルと判定されたヒットのリスト
     */
    public List<JsonNode> filterOriginalOnly(List<JsonNode> hits) {
        List<JsonNode> filtered = new ArrayList<>();
        for (JsonNode hit : hits) {
            if (isOriginal(hit)) {
                filtered.add(hit);
            }
        }
        logger.debug("Genius フィルタリング結果: {}/{} 件をオリジナルと判定", filtered.size(), hits.size());
        return filtered;
    }

    private boolean isOriginal(JsonNode hit) {
        JsonNode result = hit.path("result");

        String artistName = result.path("primary_artist").path("name").asText("").toLowerCase();
        String title = result.path("title").asText("").toLowerCase();
        String fullTitle = result.path("full_title").asText("").toLowerCase();

        // 1. アーティスト名チェック: 翻訳アカウントを除外
        for (String pattern : TRANSLATION_ARTIST_PATTERNS) {
            if (artistName.contains(pattern)) {
                logger.debug("翻訳アカウントをスキップ: artist=\"{}\"", artistName);
                return false;
            }
        }

        // 2. タイトルチェック: 翻訳/ローマ字を示すキーワードを除外
        for (String pattern : TRANSLATION_TITLE_PATTERNS) {
            if (title.contains(pattern) || fullTitle.contains(pattern)) {
                logger.debug("翻訳/ローマ字版タイトルをスキップ: title=\"{}\", fullTitle=\"{}\"",
                    title, fullTitle);
                return false;
            }
        }

        return true;
    }
}
