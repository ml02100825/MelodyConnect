package com.example.api.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * 問題生成リクエストDTO
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class QuestionGenerationRequest {

    /**
     * 生成モード
     * FAVORITE_ARTIST: お気に入りアーティストからランダム
     * GENRE_RANDOM: 指定ジャンルからランダム
     * COMPLETE_RANDOM: 完全ランダム
     * URL_INPUT: URLから指定
     */
    private GenerationMode mode;

    /**
     * ユーザーID（FAVORITE_ARTISTモード時に必要）
     */
    private Long userId;

    /**
     * ジャンル名（GENRE_RANDOMモード時に必要）
     */
    private String genreName;

    /**
     * 楽曲URL（URL_INPUTモード時に必要）
     */
    private String songUrl;

    /**
     * 問題数（虫食い問題）
     */
    private Integer fillInBlankCount = 10;

    /**
     * 問題数（リスニング問題）
     */
    private Integer listeningCount = 10;

    /**
     * 生成モード enum
     */
    public enum GenerationMode {
        FAVORITE_ARTIST,
        GENRE_RANDOM,
        COMPLETE_RANDOM,
        URL_INPUT
    }
}
