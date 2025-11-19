package com.example.api.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * お気に入りアーティスト登録リクエスト
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class LikeArtistRequest {

    /**
     * 登録するアーティストのリスト
     */
    private List<ArtistInfo> artists;

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ArtistInfo {
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
    }
}
