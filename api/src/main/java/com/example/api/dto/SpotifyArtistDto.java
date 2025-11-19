package com.example.api.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * Spotifyアーティスト情報DTO
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SpotifyArtistDto {

    /**
     * Spotify アーティストID
     */
    private String spotifyId;

    /**
     * アーティスト名
     */
    private String name;

    /**
     * 画像URL
     */
    private String imageUrl;

    /**
     * ジャンルリスト
     */
    private List<String> genres;

    /**
     * 人気度 (0-100)
     */
    private Integer popularity;
}
