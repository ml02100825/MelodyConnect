package com.example.api.service;

import com.example.api.client.GeminiApiClient;
import com.example.api.client.GeniusApiClient;
import com.example.api.client.SpotifyApiClient;
import com.example.api.client.WordnikApiClient;
import com.example.api.dto.*;
import com.example.api.entity.*;
import com.example.api.enums.LanguageCode;
import com.example.api.repository.*;
import com.example.api.util.LanguageDetectionUtils;
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
                // ユーザーの学習言語を設定（指定されていない場合は"en"）
                String targetLang = request.getTargetLanguage() != null ? request.getTargetLanguage() : "en";
                saveVocabulary(q.getBlankWord(), targetLang);
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
     * Geniusで複数候補を試行し、失敗した場合はMusixmatchにフォールバック
     * 歌詞取得成功時、GeniusSongIdと検出された言語をSongに設定
     */
    private String fetchLyrics(Song song) {
        String lyrics = null;

        // 1. Geniusで検索して複数候補を試行（優先度順）
        if (song.getSongname() != null && song.getTempArtistName() != null) {
            logger.info("Geniusで楽曲を検索して歌詞を取得します: artist={}, song={}",
                song.getTempArtistName(), song.getSongname());

            GeniusApiClient.LyricsResult result = geniusApiClient.searchAndGetLyricsWithMetadata(
                song.getSongname(), song.getTempArtistName());

            if (result != null && result.getLyrics() != null && !result.getLyrics().isEmpty()) {
                logger.info("Geniusから歌詞を取得しました（複数候補から選択）: geniusSongId={}, language={}",
                    result.getGeniusSongId(), result.getDetectedLanguage());

                // Genius Song IDと検出された言語をSongに設定
                song.setGenius_song_id(result.getGeniusSongId());
                song.setLanguage(result.getDetectedLanguage());

                return result.getLyrics();
            }

            logger.warn("Geniusの検索で歌詞を取得できませんでした（全候補がローマ字版の可能性）");
        }

        // 2. 直接Song IDがある場合は試行（検索で失敗した場合のフォールバック）
        if (song.getGenius_song_id() != null) {
            logger.debug("Genius Song IDから直接歌詞を取得します: geniusSongId={}", song.getGenius_song_id());
            lyrics = geniusApiClient.getLyrics(song.getGenius_song_id());

            if (lyrics != null && !lyrics.isEmpty()) {
                logger.info("Genius Song IDから歌詞を取得しました");
                // 既にGeniusSongIdは設定されているので、言語のみ検出して設定
                if (song.getLanguage() == null) {
                    song.setLanguage(detectLanguageSimple(lyrics));
                }
                return lyrics;
            }

            logger.warn("Genius Song IDから歌詞を取得できませんでした");
        }

        // 3. Musixmatchにフォールバック
        if (song.getSongname() != null && song.getTempArtistName() != null) {
            logger.info("Musixmatchから歌詞を取得します: artist={}, song={}",
                song.getTempArtistName(), song.getSongname());

            lyrics = musixmatchApiClient.getLyrics(song.getTempArtistName(), song.getSongname());

            if (lyrics != null && !lyrics.isEmpty()) {
                logger.info("Musixmatchから歌詞を取得しました");
                // Musixmatchから取得した場合も言語を検出
                if (song.getLanguage() == null) {
                    song.setLanguage(detectLanguageSimple(lyrics));
                }
                return lyrics;
            }

            logger.warn("Musixmatchからも歌詞を取得できませんでした");
        }

        // 4. どちらからも取得できなかった
        logger.error("どの歌詞APIからも歌詞を取得できませんでした: songName={}", song.getSongname());
        return null;
    }

    /**
     * 歌詞から言語を簡易検出
     * LanguageDetectionUtilsを使用して判定を行う
     */
    private String detectLanguageSimple(String lyrics) {
        if (lyrics == null || lyrics.trim().isEmpty()) {
            return null;
        }

        // LanguageDetectionUtilsを使用して言語を検出
        LanguageCode detected = LanguageDetectionUtils.detectFromCharacters(lyrics);

        if (detected != null && detected.isValid()) {
            logger.debug("言語検出: {}", detected.getDisplayName());
            return detected.getCode();
        }

        return null;
    }

    /**
     * 問題を保存
     */
    private Question saveQuestion(Song song, ClaudeQuestionResponse.Question claudeQuestion, String questionFormat) {
        // Songがまだ保存されていない場合は先に保存
        if (song.getSong_id() == null) {
            // Artistを作成/検索
            if (song.getAritst_id() == null || song.getAritst_id() == 0L) {
                if (song.getTempArtistName() != null && song.getTempArtistApiId() != null) {
                    // SpotifyのartistApiIdでArtistを検索
                    Artist artist = artistRepository.findByArtistApiId(song.getTempArtistApiId())
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
                }
            }

            logger.debug("Songを保存します: songName={}", song.getSongname());
            song = songRepository.save(song);
            logger.debug("Song保存完了: songId={}", song.getSong_id());
        }

        Question newQuestion = new Question();
        newQuestion.setSong(song);
        // Artist is set via the song's artist_id - fetch from repository if needed
        Artist artist = artistRepository.findById(song.getAritst_id().intValue()).orElse(null);
        newQuestion.setArtist(artist);
        newQuestion.setText(claudeQuestion.getSentence());
        newQuestion.setAnswer(claudeQuestion.getBlankWord());
        newQuestion.setQuestionFormat(com.example.api.enums.QuestionFormat.fromValue(questionFormat));
        newQuestion.setDifficultyLevel(claudeQuestion.getDifficulty());
        newQuestion.setLanguage(song.getLanguage());

        return questionRepository.save(newQuestion);
    }

    /**
     * 単語情報を保存
     * Wordnik APIキーが設定されていない場合はスキップ
     *
     * @param word 単語
     * @param language ユーザーの学習言語（例: "en", "ja", "ko"）
     */
    private void saveVocabulary(String word, String language) {
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
                .language(language)  // ユーザーの学習言語を設定
                .build();

            vocabularyRepository.save(vocab);
            logger.debug("単語情報を保存しました: word={}, language={}", word, language);

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
