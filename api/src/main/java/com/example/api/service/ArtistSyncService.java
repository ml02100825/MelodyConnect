package com.example.api.service;

import com.example.api.client.SpotifyApiClient;
import com.example.api.entity.Artist;
import com.example.api.entity.Song;
import com.example.api.repository.ArtistRepository;
import com.example.api.repository.SongRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

/**
 * アーティスト楽曲同期サービス（簡略版）
 * QuestionGeneratorServiceから呼び出され、お気に入りアーティストの全曲を自動保存します
 */
@Service
public class ArtistSyncService {

    private static final Logger logger = LoggerFactory.getLogger(ArtistSyncService.class);

    @Autowired
    private SpotifyApiClient spotifyApiClient;

    @Autowired
    private ArtistRepository artistRepository;

    @Autowired
    private SongRepository songRepository;

    /**
     * アーティストの全曲を同期
     * 
     * @param artistId データベース内のアーティストID
     * @return 新規に保存された曲数
     */
    @Transactional
    public int syncArtistSongs(Integer artistId) {
        logger.info("=== アーティスト楽曲同期開始 ===");
        logger.info("Artist ID: {}", artistId);

        Artist artist = artistRepository.findById(artistId)
            .orElseThrow(() -> new RuntimeException("アーティストが見つかりません: " + artistId));

        String spotifyArtistId = artist.getArtistApiId();
        if (spotifyArtistId == null || spotifyArtistId.isEmpty()) {
            logger.warn("SpotifyアーティストIDが設定されていません: artistId={}", artistId);
            return 0;
        }

        try {
            // Spotify APIから全曲を取得
            List<Song> allSongs = spotifyApiClient.getAllSongsByArtist(spotifyArtistId);
            logger.info("Spotify APIから取得した曲数: {}", allSongs.size());

            // 既存の曲をチェックして、新しい曲のみ保存
            int newSongsCount = 0;
            for (Song song : allSongs) {
                // Spotify Track IDで重複チェック
                boolean exists = songRepository.existsBySpotifyTrackId(song.getSpotify_track_id());
                
                if (!exists) {
                    // artist_idを設定（IntegerからLongへの変換）
                    song.setAritst_id(artistId.longValue());
                    
                    // genius_song_idはnull（仕様通り）
                    song.setGenius_song_id(null);
                    
                    songRepository.save(song);
                    newSongsCount++;
                    
                    if (newSongsCount % 50 == 0) {
                        logger.info("保存進捗: {}曲", newSongsCount);
                    }
                }
            }

            // アーティストの最終同期時刻を更新
            artist.setLastSyncedAt(LocalDateTime.now());
            artistRepository.save(artist);

            logger.info("=== アーティスト楽曲同期完了 ===");
            logger.info("新規保存曲数: {}", newSongsCount);
            logger.info("スキップ曲数（既存）: {}", allSongs.size() - newSongsCount);

            return newSongsCount;

        } catch (Exception e) {
            logger.error("アーティスト楽曲の同期中にエラーが発生しました: artistId={}", artistId, e);
            throw new RuntimeException("楽曲同期に失敗しました", e);
        }
    }
}
