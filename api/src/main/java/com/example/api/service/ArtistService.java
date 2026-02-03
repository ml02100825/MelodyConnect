package com.example.api.service;

import com.example.api.client.SpotifyApiClient;
import com.example.api.dto.LikeArtistRequest;
import com.example.api.dto.LikeArtistResponse;
import com.example.api.dto.SpotifyArtistDto;
import com.example.api.entity.Artist;
import com.example.api.entity.Genre;
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

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Service
public class ArtistService {

    private static final Logger logger = LoggerFactory.getLogger(ArtistService.class);

    // ジャンル判定用のキーワードマッピング
    // LinkedHashMapを使用することで挿入順序（優先順位）を保証します
    private static final Map<String, List<String>> GENRE_MAPPINGS = new LinkedHashMap<>();

    static {
        GENRE_MAPPINGS.put("Rock", List.of("rock", "punk", "metal", "grunge"));
        GENRE_MAPPINGS.put("Hip Hop", List.of("hip hop", "rap", "trap", "drill"));
        GENRE_MAPPINGS.put("Jazz", List.of("jazz", "blues"));
        GENRE_MAPPINGS.put("R&B", List.of("r&b", "soul", "funk"));
        GENRE_MAPPINGS.put("Electronic", List.of("electronic", "dance", "techno", "house", "edm"));
        GENRE_MAPPINGS.put("Reggae", List.of("reggae", "ska"));
        GENRE_MAPPINGS.put("Latin", List.of("latin", "reggaeton"));
        GENRE_MAPPINGS.put("Classical", List.of("classic", "orchestra"));
        GENRE_MAPPINGS.put("Country", List.of("folk", "acoustic", "country"));
        GENRE_MAPPINGS.put("Anime", List.of("anime", "game", "soundtrack"));
        GENRE_MAPPINGS.put("K-Pop", List.of("k-pop"));
        GENRE_MAPPINGS.put("J-Pop", List.of("j-pop"));
        // Popは他のジャンルに含まれやすいので、判定順序を最後にします
        GENRE_MAPPINGS.put("Pop", List.of("pop", "indie"));
    }

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

    public List<SpotifyArtistDto> searchArtists(String query, int limit) {
        return spotifyApiClient.searchArtists(query, limit);
    }

    public List<SpotifyArtistDto> searchArtistsByGenre(String genreName, int limit) {
        return spotifyApiClient.searchArtistsByGenre(genreName, limit);
    }

    @Transactional
    public void registerLikeArtists(Long userId, LikeArtistRequest request) {
        User user = userRepository.findById(userId)
            .orElseThrow(() -> new RuntimeException("ユーザーが見つかりません: " + userId));

        List<LikeArtist> savedArtists = new ArrayList<>();

        for (LikeArtistRequest.ArtistInfo artistInfo : request.getArtists()) {
            Artist artist = artistRepository.findByArtistApiId(artistInfo.getSpotifyId())
                .orElseGet(() -> createArtist(artistInfo));

            if (likeArtistRepository.findByUserIdAndArtistId(userId, artist.getArtistId()).isEmpty()) {
                LikeArtist likeArtist = new LikeArtist();
                likeArtist.setUser(user);
                likeArtist.setArtist(artist);
                savedArtists.add(likeArtistRepository.save(likeArtist));
            }
        }

        user.setInitialSetupCompleted(true);
        userRepository.save(user);

        logger.info("お気に入りアーティスト登録完了: userId={}, count={}", userId, savedArtists.size());
    }

    private Artist createArtist(LikeArtistRequest.ArtistInfo artistInfo) {
        // ジャンルIDを特定（なければ自動作成）
        Long genreId = determineGenreId(artistInfo.getGenre());
        
        // IDからジャンルエンティティを取得
        Genre genre = genreRepository.findById(genreId)
                .orElseThrow(() -> new RuntimeException("ジャンルが見つかりません: ID=" + genreId));

        // Artistエンティティ作成
        Artist newArtist = new Artist();
        newArtist.setArtistName(artistInfo.getName());
        newArtist.setArtistApiId(artistInfo.getSpotifyId());
        newArtist.setImageUrl(artistInfo.getImageUrl());
        newArtist.setGenre(genre); // ジャンルをセット
        newArtist.setIsActive(true);
        newArtist.setIsDeleted(false);
        
        // save()を実行すると自動的にIDが採番され、newArtistオブジェクトにセットされる
        Artist savedArtist = artistRepository.save(newArtist);

        // 中間テーブルへの保存
        artistRepository.insertArtistGenre(savedArtist.getArtistId(), genreId, LocalDateTime.now());
        
        logger.info("新規アーティスト作成: name={}, genre={}", artistInfo.getName(), genre.getName());

        return savedArtist;
    }

    /**
     * ジャンルIDを決定するロジック
     * 既存のジャンルになければ新規作成する
     */
    private Long determineGenreId(String genreName) {
        if (genreName == null || genreName.trim().isEmpty()) {
            return findGenreIdByNameOrAutoCreate("other");
        }

        String lowerName = genreName.toLowerCase();

        // 定義されたキーワードと照合
        for (Map.Entry<String, List<String>> entry : GENRE_MAPPINGS.entrySet()) {
            String parentGenre = entry.getKey();
            List<String> keywords = entry.getValue();

            // キーワードのいずれかが含まれていれば、その親ジャンルを採用
            for (String keyword : keywords) {
                if (lowerName.contains(keyword)) {
                    return findGenreIdByNameOrAutoCreate(parentGenre);
                }
            }
        }

        // 当てはまらない場合は、そのジャンル名で作成または取得
        return findGenreIdByNameOrAutoCreate(genreName);
    }

    /**
     * 指定されたジャンル名で検索し、存在しなければ新規作成してIDを返す
     */
    private Long findGenreIdByNameOrAutoCreate(String targetName) {
        return genreRepository.findByName(targetName)
                // ★修正: getId() -> getGenreId()
                .map(Genre::getGenreId)
                .orElseGet(() -> createNewGenre(targetName));
    }

    /**
     * 新しいジャンルをDBに作成してIDを返す
     */
    private Long createNewGenre(String name) {
        String safeName = (name == null || name.trim().isEmpty()) ? "other" : name;

        // DBに存在するか確認し、なければ作成する
        return genreRepository.findByName(safeName)
                // ★修正: getId() -> getGenreId()
                .map(Genre::getGenreId)
                .orElseGet(() -> {
                    Genre newGenre = new Genre();
                    newGenre.setName(safeName);
                    newGenre.setIsActive(true);
                    newGenre.setIsDeleted(false);
                    newGenre.setCreatedAt(LocalDateTime.now());
                    
                    Genre saved = genreRepository.save(newGenre);
                    // ★修正: getId() -> getGenreId()
                    logger.info("ジャンル自動作成: id={}, name={}", saved.getGenreId(), saved.getName());
                    return saved.getGenreId();
                });
    }

    @Transactional(readOnly = true)
    public List<LikeArtistResponse> getLikeArtists(Long userId) {
        List<LikeArtist> likeArtists = likeArtistRepository.findByUserId(userId);
        List<LikeArtistResponse> responses = new ArrayList<>();
        for (LikeArtist la : likeArtists) {
            Artist artist = la.getArtist();
            LikeArtistResponse dto = new LikeArtistResponse();
            dto.setArtistId(artist.getArtistId());
            dto.setArtistName(artist.getArtistName());
            dto.setImageUrl(artist.getImageUrl());
            dto.setArtistApiId(artist.getArtistApiId());
            dto.setGenreName(artist.getGenre() != null ? artist.getGenre().getName() : null);
            dto.setCreatedAt(la.getCreatedAt());
            responses.add(dto);
        }
        return responses;
    }

    @Transactional
    public void removeLikeArtist(Long userId, Long artistId) {
        LikeArtist likeArtist = likeArtistRepository.findByUserIdAndArtistId(userId, artistId)
            .orElseThrow(() -> new IllegalArgumentException(
                "お気に入りアーティストが見つかりません: userId=" + userId + ", artistId=" + artistId));
        likeArtistRepository.delete(likeArtist);
        logger.info("お気に入りアーティスト削除: userId={}, artistId={}", userId, artistId);
    }

    public boolean isInitialSetupCompleted(Long userId) {
        return userRepository.findById(userId)
            .map(User::isInitialSetupCompleted)
            .orElse(false);
    }
}
