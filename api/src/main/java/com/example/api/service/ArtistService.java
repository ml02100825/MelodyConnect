package com.example.api.service;

import com.example.api.client.SpotifyApiClient;
import com.example.api.dto.LikeArtistRequest;
import com.example.api.dto.SpotifyArtistDto;
import com.example.api.entity.Artist;
import com.example.api.entity.LikeArtist;
import com.example.api.entity.User;
import com.example.api.repository.ArtistRepository;
import com.example.api.repository.GenreRepository;
import com.example.api.repository.LikeArtistRepository;
import com.example.api.repository.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;

/**
 * アーティスト関連のサービス
 */
@Service
public class ArtistService {

    private static final Logger logger = LoggerFactory.getLogger(ArtistService.class);

    @Autowired
    private SpotifyApiClient spotifyApiClient;

    @Autowired
    private ArtistRepository artistRepository;

    @Autowired
    private LikeArtistRepository likeArtistRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private GenreRepository genreRepository;

    /**
     * アーティストを検索
     */
    public List<SpotifyArtistDto> searchArtists(String query, int limit) {
        return spotifyApiClient.searchArtists(query, limit);
    }

    /**
     * お気に入りアーティストを登録
     */
    @Transactional
    public void registerLikeArtists(Long userId, LikeArtistRequest request) {
        User user = userRepository.findById(userId)
            .orElseThrow(() -> new RuntimeException("ユーザーが見つかりません: " + userId));

        List<LikeArtist> savedArtists = new ArrayList<>();

        for (LikeArtistRequest.ArtistInfo artistInfo : request.getArtists()) {
            // アーティストがDBに存在するか確認、なければ作成
            Artist artist = artistRepository.findByArtistApiId(artistInfo.getSpotifyId())
                .orElseGet(() -> createArtist(artistInfo));

            // 既に登録済みでないか確認
            if (likeArtistRepository.findByUserIdAndArtistId(userId, artist.getArtistId()).isEmpty()) {
                LikeArtist likeArtist = new LikeArtist();
                likeArtist.setUser(user);
                likeArtist.setArtist(artist);
                savedArtists.add(likeArtistRepository.save(likeArtist));
            }
        }

        // 初期設定完了フラグを更新
        user.setInitialSetupCompleted(true);
        userRepository.save(user);

        logger.info("お気に入りアーティストを登録しました: userId={}, count={}", userId, savedArtists.size());
    }

    /**
     * 新しいアーティストをDBに作成
     */
    private Artist createArtist(LikeArtistRequest.ArtistInfo artistInfo) {
        Artist artist = new Artist();
        artist.setArtistName(artistInfo.getName());
        artist.setArtistApiId(artistInfo.getSpotifyId());
        artist.setImageUrl(artistInfo.getImageUrl());

        // ジャンルIDを設定（デフォルトは1: Pop）
        Integer genreId = 1;
        if (artistInfo.getGenre() != null && !artistInfo.getGenre().isEmpty()) {
            genreId = genreRepository.findByName(artistInfo.getGenre())
                .map(genre -> genre.getId().intValue())
                .orElse(1);
        }
   

        Artist savedArtist = artistRepository.save(artist);
        logger.info("新しいアーティストを作成しました: name={}, spotifyId={}",
            artistInfo.getName(), artistInfo.getSpotifyId());
        return savedArtist;
    }

    /**
     * ユーザーのお気に入りアーティストを取得
     */
    public List<Artist> getLikeArtists(Long userId) {
        List<LikeArtist> likeArtists = likeArtistRepository.findByUserId(userId);
        List<Artist> artists = new ArrayList<>();
        for (LikeArtist la : likeArtists) {
            artists.add(la.getArtist());
        }
        return artists;
    }

    /**
     * ユーザーの初期設定完了状態を確認
     */
    public boolean isInitialSetupCompleted(Long userId) {
        return userRepository.findById(userId)
            .map(User::isInitialSetupCompleted)
            .orElse(false);
    }
}
