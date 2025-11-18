package com.example.api.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * クイズ開始リクエストDTO
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class QuizStartRequest {

    /**
     * ユーザーID
     */
    private Long userId;

    /**
     * 学習言語
     * "en" (英語) or "ko" (韓国語)
     */
    private String language;

    /**
     * 問題生成方法
     * FAVORITE_ARTIST, GENRE_RANDOM, COMPLETE_RANDOM, URL_INPUT
     */
    private String generationMode;

    /**
     * 問題形式
     * ALL_RANDOM, LISTENING_ONLY, FILL_IN_BLANK_ONLY
     */
    private String questionFormat;

    /**
     * 問題数
     */
    private Integer questionCount;

    /**
     * ジャンル名（GENRE_RANDOMモード時に必要）
     */
    private String genreName;

    /**
     * 楽曲URL（URL_INPUTモード時に必要）
     */
    private String songUrl;
}
