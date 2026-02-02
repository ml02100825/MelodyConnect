package com.example.api.service;

import com.example.api.client.SpotifyApiClient;
import com.example.api.dto.LikeArtistRequest;
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
import java.util.List;
import java.util.Optional;

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

    public List<SpotifyArtistDto> searchArtists(String query, int limit) {
        return spotifyApiClient.searchArtists(query, limit);
    }

    @Transactional
    public void registerLikeArtists(Long userId, LikeArtistRequest request) {
        User user = userRepository.findById(userId)
            .orElseThrow(() -> new RuntimeException("ユーザーが見つかりません: " + userId));

        List<LikeArtist> savedArtists = new ArrayList<>();

        for (LikeArtistRequest.ArtistInfo artistInfo : request.getArtists()) {
            // アーティストが既に存在するか確認
            Artist artist = artistRepository.findByArtistApiId(artistInfo.getSpotifyId())
                .orElseGet(() -> createArtist(artistInfo));

            // お気に入り登録がまだなら登録
            if (likeArtistRepository.findByUserIdAndArtistId(userId, artist.getArtistId()).isEmpty()) {
                LikeArtist likeArtist = new LikeArtist();
                likeArtist.setUser(user);
                likeArtist.setArtist(artist);
                savedArtists.add(likeArtistRepository.save(likeArtist));
            }
        }

        user.setInitialSetupCompleted(true);
        userRepository.save(user);

        logger.info("お気に入りアーティストを登録しました: userId={}, count={}", userId, savedArtists.size());
    }

    private Artist createArtist(LikeArtistRequest.ArtistInfo artistInfo) {
        // 1. ジャンルIDを特定（なければ自動作成）
        Long genreId = determineGenreId(artistInfo.getGenre());

        LocalDateTime now = LocalDateTime.now();

        // 2. artistテーブルへINSERT
        artistRepository.insertArtistWithGenre(
                artistInfo.getName(),
                artistInfo.getSpotifyId(),
                artistInfo.getImageUrl(),
                now,
                now,
                true,
                false,
                genreId
        );

        // 3. ID取得
        Artist savedArtist = artistRepository.findByArtistApiId(artistInfo.getSpotifyId())
                .orElseThrow(() -> new RuntimeException("アーティストの作成に失敗しました"));

        // 4. artist_genreテーブルへINSERT
        artistRepository.insertArtistGenre(savedArtist.getArtistId(), genreId, now);
        
        logger.info("アーティスト登録完了: name={}, genreId={}, originalGenre={}", 
            artistInfo.getName(), genreId, artistInfo.getGenre());

        return savedArtist;
    }

    /**
     * ジャンルIDを決定するロジック
     */
    private Long determineGenreId(String genreName) {
        // ジャンル名が空の場合は、Spotifyが情報をくれなかったということなので 'other' (または未分類) を作成して割り当て
        if (genreName == null || genreName.isEmpty()) {
            return findGenreIdByNameOrAutoCreate("other");
        }

        String lowerName = genreName.toLowerCase();

        // --- キーワードマッチング ---
        // ヒットしたら、その「親ジャンル名」でDBを探し、なければ作る
        if (lowerName.contains("rock") || lowerName.contains("punk") || lowerName.contains("metal") || lowerName.contains("grunge")) 
            return findGenreIdByNameOrAutoCreate("Rock");
            
        if (lowerName.contains("hip hop") || lowerName.contains("rap") || lowerName.contains("trap") || lowerName.contains("drill")) 
            return findGenreIdByNameOrAutoCreate("Hip Hop");
            
        if (lowerName.contains("jazz") || lowerName.contains("blues")) 
            return findGenreIdByNameOrAutoCreate("Jazz");
            
        if (lowerName.contains("r&b") || lowerName.contains("soul") || lowerName.contains("funk")) 
            return findGenreIdByNameOrAutoCreate("R&B");
            
        if (lowerName.contains("electronic") || lowerName.contains("dance") || lowerName.contains("techno") || lowerName.contains("house") || lowerName.contains("edm")) 
            return findGenreIdByNameOrAutoCreate("Electronic");
            
        if (lowerName.contains("reggae") || lowerName.contains("ska")) 
            return findGenreIdByNameOrAutoCreate("Reggae");
            
        if (lowerName.contains("latin") || lowerName.contains("reggaeton")) 
            return findGenreIdByNameOrAutoCreate("Latin");
            
        if (lowerName.contains("classic") || lowerName.contains("orchestra")) 
            return findGenreIdByNameOrAutoCreate("Classical");
            
        if (lowerName.contains("folk") || lowerName.contains("acoustic") || lowerName.contains("country")) 
            return findGenreIdByNameOrAutoCreate("Country");
            
        if (lowerName.contains("anime") || lowerName.contains("game") || lowerName.contains("soundtrack")) 
            return findGenreIdByNameOrAutoCreate("Anime");
            
        if (lowerName.contains("k-pop")) 
            return findGenreIdByNameOrAutoCreate("K-Pop");
            
        if (lowerName.contains("j-pop")) 
            return findGenreIdByNameOrAutoCreate("J-Pop");
            
        // Popは他のジャンルに含まれやすいので最後に判定
        if (lowerName.contains("pop") || lowerName.contains("indie")) 
            return findGenreIdByNameOrAutoCreate("Pop");

        // --- キーワードに当てはまらない場合 ---
        // そのままの名前で登録（例: "Bossa Nova" など）
        return findGenreIdByNameOrAutoCreate(genreName);
    }

    /**
     * ★修正ポイント: 名前で検索し、なければ「Other」ではなく「新規作成」する
     */
    private Long findGenreIdByNameOrAutoCreate(String targetName) {
        // 大文字小文字の違いによる重複を防ぐため、一旦全部小文字などで検索するか、
        // DBに正しい表記（例: Rock）があるか確認する
        
        Optional<Genre> existingGenre = genreRepository.findByName(targetName);
        if (existingGenre.isPresent()) {
            return existingGenre.get().getId();
        }

        // DBにないので新規作成する
        return createNewGenre(targetName);
    }

    /**
     * 新しいジャンルをDBに作成してIDを返す
     */
    private Long createNewGenre(String name) {
        try {
            // 名前が空文字の場合は "other" に置き換え
            String safeName = (name == null || name.trim().isEmpty()) ? "other" : name;

            // 念のため再チェック（同時アクセスなどで作られている可能性があるため）
            return genreRepository.findByName(safeName)
                    .map(Genre::getId)
                    .orElseGet(() -> {
                        Genre newGenre = new Genre();
                        newGenre.setName(safeName);
                        // 先頭を大文字にするなどの整形はお好みで
                        // newGenre.setName(StringUtils.capitalize(safeName)); 
                        newGenre.setIsActive(true);
                        newGenre.setIsDeleted(false);
                        newGenre.setCreatedAt(LocalDateTime.now());
                        
                        Genre saved = genreRepository.save(newGenre);
                        logger.info("ジャンルを自動作成しました: id={}, name={}", saved.getId(), saved.getName());
                        return saved.getId();
                    });
        } catch (Exception e) {
            logger.error("ジャンル作成中にエラーが発生: {}", name, e);
            // 本当にどうしようもない時だけ 1 を返す（通常ここには来ないはず）
            return 1L; 
        }
    }

    public List<Artist> getLikeArtists(Long userId) {
        List<LikeArtist> likeArtists = likeArtistRepository.findByUserId(userId);
        List<Artist> artists = new ArrayList<>();
        for (LikeArtist la : likeArtists) {
            artists.add(la.getArtist());
        }
        return artists;
    }

    public boolean isInitialSetupCompleted(Long userId) {
        return userRepository.findById(userId)
            .map(User::isInitialSetupCompleted)
            .orElse(false);
    }
}