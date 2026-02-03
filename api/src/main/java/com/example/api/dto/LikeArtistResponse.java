package com.example.api.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * お気に入りアーティスト一覧レスポンスDTO
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class LikeArtistResponse {

    /** アーティストID（Artist PK） */
    private Long artistId;

    /** アーティスト名 */
    private String artistName;

    /** 画像URL */
    private String imageUrl;

    /** Spotify ID（Flutter側の除外セット構築に使用） */
    private String artistApiId;

    /** ジャンル名（Genre.name） */
    private String genreName;

    /** お気に入り追加日時（LikeArtist.createdAt） */
    private LocalDateTime createdAt;
}
