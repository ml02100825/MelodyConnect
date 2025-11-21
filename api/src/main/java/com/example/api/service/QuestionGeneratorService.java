package com.example.api.service;

import com.example.api.client.GeminiApiClient;
import com.example.api.client.GeniusApiClient;
import com.example.api.client.SpotifyApiClient;
import com.example.api.client.WordnikApiClient;
import com.example.api.dto.*;
import com.example.api.entity.*;
import com.example.api.repository.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;

/**
 * 問題生成サービス
 * 歌詞から問題を自動生成し、データベースに保存します
 */
@Service
public class QuestionGeneratorService {

    private static final Logger logger = LoggerFactory.getLogger(QuestionGeneratorService.class);

    @Autowired
    private GeminiApiClient geminiApiClient;

    @Autowired
    private WordnikApiClient wordnikApiClient;

    @Autowired
    private GeniusApiClient geniusApiClient;

    @Autowired
    private SpotifyApiClient spotifyApiClient;

    @Autowired
    private QuestionRepository questionRepository;

    @Autowired
    private SongRepository songRepository;

    @Autowired
    private ArtistRepository artistRepository;

    @Autowired
    private LikeArtistRepository likeArtistRepository;

    @Autowired
    private VocabularyRepository vocabularyRepository;

    /**
     * 問題を生成
     *
     * @param request 問題生成リクエスト
     * @return 問題生成レスポンス
     */
    @Transactional
    public QuestionGenerationResponse generateQuestions(QuestionGenerationRequest request) {
        logger.info("問題生成開始: mode={}, userId={}", request.getMode(), request.getUserId());

        try {
            // 1. 楽曲を選択
            Song selectedSong = selectSong(request);
            if (selectedSong == null) {
                throw new IllegalStateException("楽曲の選択に失敗しました");
            }

            logger.info("選択された楽曲: songId={}, songName={}", selectedSong.getSong_id(), selectedSong.getSongname());

            // 2. 歌詞を取得
            String lyrics = fetchLyrics(selectedSong);
            if (lyrics == null || lyrics.isEmpty()) {
                throw new IllegalStateException("歌詞の取得に失敗しました");
            }

            logger.info("歌詞取得完了: length={}", lyrics.length());

            // 3. Gemini APIで問題を生成
            String language = selectedSong.getLanguage() != null ? selectedSong.getLanguage() : "en";
            ClaudeQuestionResponse claudeResponse = geminiApiClient.generateQuestions(
                lyrics,
                language,
                request.getFillInBlankCount(),
                request.getListeningCount()
            );

            logger.info("Gemini APIから問題生成完了: fillInBlank={}, listening={}",
                claudeResponse.getFillInBlank().size(),
                claudeResponse.getListening().size());

            // 4. 問題を保存し、単語情報を取得
            List<QuestionGenerationResponse.GeneratedQuestionDto> generatedQuestions = new ArrayList<>();

            // 虫食い問題を保存
            for (ClaudeQuestionResponse.Question q : claudeResponse.getFillInBlank()) {
                Question savedQuestion = saveQuestion(selectedSong, q, "fill_in_blank");
                generatedQuestions.add(convertToDto(savedQuestion));

                // 虫食い問題の場合は、全ての空欄単語の情報を保存
                saveVocabulary(q.getBlankWord());
            }

            // リスニング問題を保存
            for (ClaudeQuestionResponse.Question q : claudeResponse.getListening()) {
                Question savedQuestion = saveQuestion(selectedSong, q, "listening");
                generatedQuestions.add(convertToDto(savedQuestion));
                // リスニング問題の単語情報は、ユーザーが間違えた時に保存（ここでは保存しない）
            }

            logger.info("問題保存完了: total={}", generatedQuestions.size());

            // 5. レスポンスを構築
            return QuestionGenerationResponse.builder()
                .questions(generatedQuestions)
                .songInfo(buildSongInfo(selectedSong))
                .totalCount(generatedQuestions.size())
                .fillInBlankCount(claudeResponse.getFillInBlank().size())
                .listeningCount(claudeResponse.getListening().size())
                .message("問題生成が成功しました")
                .build();

        } catch (Exception e) {
            logger.error("問題生成中にエラーが発生しました", e);
            throw new RuntimeException("問題生成に失敗しました: " + e.getMessage(), e);
        }
    }

    /**
     * 生成モードに応じて楽曲を選択
     */
    private Song selectSong(QuestionGenerationRequest request) {
        switch (request.getMode()) {
            case FAVORITE_ARTIST:
                return selectSongFromFavoriteArtist(request.getUserId());
            case GENRE_RANDOM:
                return selectSongByGenre(request.getGenreName());
            case COMPLETE_RANDOM:
                return selectRandomSong();
            case URL_INPUT:
                return selectSongByUrl(request.getSongUrl());
            default:
                throw new IllegalArgumentException("未知の生成モード: " + request.getMode());
        }
    }

    /**
     * お気に入りアーティストからランダムに楽曲を選択
     */
    private Song selectSongFromFavoriteArtist(Long userId) {
        logger.debug("お気に入りアーティストから楽曲を選択: userId={}", userId);

        LikeArtist randomLikeArtist = likeArtistRepository.findRandomByUserId(userId)
            .orElseThrow(() -> new IllegalStateException("お気に入りアーティストが見つかりません"));

        Integer artistId = randomLikeArtist.getArtist().getArtistId();
        String artistApiId = randomLikeArtist.getArtist().getArtistApiId();

        logger.debug("選択されたアーティスト: artistId={}, artistApiId={}", artistId, artistApiId);

        return songRepository.findRandomByArtist(artistId.longValue())
            .orElseGet(() -> spotifyApiClient.getRandomSongBySpotifyArtistId(artistApiId));
    }

    /**
     * ジャンルから楽曲を選択
     */
    private Song selectSongByGenre(String genreName) {
        logger.debug("ジャンルから楽曲を選択: genre={}", genreName);

        return songRepository.findRandomByGenre(genreName)
            .orElseGet(() -> spotifyApiClient.getRandomSongByGenre(genreName));
    }

    /**
     * 完全ランダムで楽曲を選択
     */
    private Song selectRandomSong() {
        logger.debug("ランダムに楽曲を選択");

        return songRepository.findRandom()
            .orElseGet(() -> spotifyApiClient.getRandomSong());
    }

    /**
     * URLから楽曲を選択
     */
    private Song selectSongByUrl(String songUrl) {
        logger.debug("URLから楽曲を選択: url={}", songUrl);

        // TODO: URLをパースして楽曲を特定する処理を実装
        // 仮実装としてランダムな楽曲を返す
        return selectRandomSong();
    }

    /**
     * 歌詞を取得
     */
    private String fetchLyrics(Song song) {
        if (song.getGenius_song_id() != null) {
            return geniusApiClient.getLyrics(song.getGenius_song_id());
        }
        throw new IllegalStateException("Genius Song IDが設定されていません");
    }

    /**
     * 問題を保存
     */
    private Question saveQuestion(Song song, ClaudeQuestionResponse.Question claudeQuestion, String questionFormat) {
        Artist artist = null;
        Song savedSong = song;

        // Songがまだ保存されていない場合は先に保存
        if (song.getSong_id() == null) {
            // Artistを作成/検索
            if (song.getAritst_id() == null || song.getAritst_id() == 0L) {
                if (song.getTempArtistName() != null && song.getTempArtistApiId() != null) {
                    // SpotifyのartistApiIdでArtistを検索
                    artist = artistRepository.findByArtistApiId(song.getTempArtistApiId())
                        .orElseGet(() -> {
                            // 存在しない場合は新規作成
                            Artist newArtist = new Artist();
                            newArtist.setArtistName(song.getTempArtistName());
                            newArtist.setArtistApiId(song.getTempArtistApiId());
                            // デフォルトのジャンルIDを設定（1 = Pop等）
                            newArtist.setGenreId(1);
                            return artistRepository.save(newArtist);
                        });
                    song.setAritst_id(artist.getArtistId().longValue());
                    logger.debug("Artist設定完了: artistId={}, artistName={}", artist.getArtistId(), artist.getArtistName());
                } else {
                    logger.warn("Songにアーティスト情報がありません。デフォルトのartist_id=1を使用します。");
                    song.setAritst_id(1L);
                    // デフォルトのArtistを取得
                    artist = artistRepository.findById(1)
                        .orElseThrow(() -> new IllegalStateException("Default artist (id=1) not found"));
                }
            } else {
                // artist_idが既に設定されている場合は取得
                artist = artistRepository.findById(song.getAritst_id().intValue())
                    .orElseThrow(() -> new IllegalStateException("Artist not found for id: " + song.getAritst_id()));
            }

            logger.debug("Songを保存します: songName={}", song.getSongname());
            savedSong = songRepository.save(song);
            logger.debug("Song保存完了: songId={}", savedSong.getSong_id());
        } else {
            // Songが既に保存されている場合はArtistを取得
            artist = artistRepository.findById(song.getAritst_id().intValue())
                .orElseThrow(() -> new IllegalStateException("Artist not found for id: " + song.getAritst_id()));
        }

        Question newQuestion = new Question();
        newQuestion.setSong(savedSong);
        newQuestion.setArtist(artist);
        newQuestion.setText(claudeQuestion.getSentence());
        newQuestion.setAnswer(claudeQuestion.getBlankWord());
        newQuestion.setQuestionFormat(com.example.api.enums.QuestionFormat.fromValue(questionFormat));
        newQuestion.setDifficultyLevel(claudeQuestion.getDifficulty());
        newQuestion.setLanguage(savedSong.getLanguage());
        newQuestion.setTranslationJa(claudeQuestion.getTranslationJa());
        newQuestion.setAudioUrl(claudeQuestion.getAudioUrl());
        // is_active and is_deleted are set by @PrePersist with default values

        return questionRepository.save(newQuestion);
    }

    /**
     * 単語情報を保存
     * Wordnik APIキーが設定されていない場合はスキップ
     */
    private void saveVocabulary(String word) {
        // すでに存在する場合はスキップ
        if (vocabularyRepository.existsByWord(word)) {
            logger.debug("単語は既に存在します: word={}", word);
            return;
        }

        try {
            WordnikWordInfo wordInfo = wordnikApiClient.getWordInfo(word);

            // モックデータ（APIキーなし）の場合はスキップ
            if (wordInfo == null || wordInfo.getMeaningJa() == null) {
                logger.debug("Wordnik APIが利用できないため単語保存をスキップ: word={}", word);
                return;
            }

            Vocabulary vocab = Vocabulary.builder()
                .word(word)
                .meaning_ja(wordInfo.getMeaningJa())
                .pronunciation(wordInfo.getPronunciation())
                .part_of_speech(wordInfo.getPartOfSpeech())
                .example_sentence(wordInfo.getExampleSentence())
                .example_translate(wordInfo.getExampleTranslate())
                .audio_url(wordInfo.getAudioUrl())
                .build();

            vocabularyRepository.save(vocab);
            logger.debug("単語情報を保存しました: word={}", word);

        } catch (Exception e) {
            logger.warn("単語情報の保存に失敗しました: word={}, error={}", word, e.getMessage());
        }
    }

    /**
     * QuestionエンティティをDTOに変換
     */
    private QuestionGenerationResponse.GeneratedQuestionDto convertToDto(Question question) {
        return QuestionGenerationResponse.GeneratedQuestionDto.builder()
            .questionId(question.getQuestionId())
            .text(question.getText())
            .answer(question.getAnswer())
            .questionFormat(question.getQuestionFormat().getValue())
            .difficultyLevel(question.getDifficultyLevel())
            .language(question.getLanguage())
            .build();
    }

    /**
     * 楽曲情報を構築
     */
    private QuestionGenerationResponse.SongInfo buildSongInfo(Song song) {
        String artistName = "Unknown";
        if (song.getAritst_id() != null) {
            Artist artist = artistRepository.findById(song.getAritst_id().intValue()).orElse(null);
            if (artist != null) {
                artistName = artist.getArtistName();
            }
        }

        return QuestionGenerationResponse.SongInfo.builder()
            .songId(song.getSong_id())
            .songName(song.getSongname())
            .artistName(artistName)
            .genre(song.getGenre())
            .language(song.getLanguage())
            .build();
    }
}
