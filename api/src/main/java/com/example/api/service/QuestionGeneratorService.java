package com.example.api.service;

import com.example.api.client.GeminiApiClient;
import com.example.api.client.GeniusApiClient;
import com.example.api.client.SpotifyApiClient;
import com.example.api.client.TextToSpeechClient;
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

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Random;

/**
 * 問題生成サービス
 * 歌詞から問題を自動生成し、データベースに保存します
 * 
 * お気に入りアーティストの場合、初回または1ヶ月経過後に自動で全曲を同期します
 */
@Service
public class QuestionGeneratorService {

    private static final Logger logger = LoggerFactory.getLogger(QuestionGeneratorService.class);

    /** ★ 追加: ランダム選択用 */
    private final Random random = new Random();

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

    @Autowired
    private TextToSpeechClient textToSpeechClient;

    // ★ ArtistSyncServiceを注入
    @Autowired
    private ArtistSyncService artistSyncService;

    /**
     * 問題を保存
     * SpotifyApiClientImplでArtistは既にDB保存済みの前提
     *
     * @param song 楽曲エンティティ（aritst_idが設定済み）
     * @param claudeQuestion Gemini APIから取得した問題データ
     * @param questionFormat 問題形式（"fill_in_blank" or "listening"）
     * @param targetLanguage ユーザーの学習言語（問題の言語として使用）
     * @param userId ユーザーID（お気に入りアーティスト同期判定用）
     */
    private Question saveQuestion(Song song, ClaudeQuestionResponse.Question claudeQuestion, 
                                   String questionFormat, String targetLanguage, Long userId) {
        // Songがまだ保存されていない場合は先に保存
        if (song.getSong_id() == null) {
            // aritst_idが未設定の場合はデフォルト値を使用
            if (song.getAritst_id() == null || song.getAritst_id() == 0L) {
                logger.warn("Songにaritst_idが設定されていません。デフォルトのartist_id=1を使用します。");
                song.setAritst_id(1L);
            }

            // Artistを取得してお気に入り同期をチェック
            Artist artist = artistRepository.findById(song.getAritst_id()).orElse(null);
            if (artist != null) {
                logger.debug("Artist設定完了: artistId={}, artistName={}", artist.getArtistId(), artist.getArtistName());
                
                // ★★★ ここで、お気に入りアーティストの全曲を自動同期 ★★★
                syncArtistSongsIfNeeded(artist, song, userId);
            }

            logger.debug("Songを保存します: songName={}", song.getSongname());
            Song savedSong = songRepository.save(song);
            logger.debug("Song保存完了: songId={}", savedSong.getSong_id());

            Question newQuestion = new Question();
            newQuestion.setSong(savedSong);
            newQuestion.setArtist(artist);

            // デバッグログ: 値が正しく取得できているか確認
            logger.debug("Setting question - text='{}', answer='{}', completeSentence='{}'",
                claudeQuestion.getText(), claudeQuestion.getAnswer(), claudeQuestion.getCompleteSentence());

            // エンティティのフィールド名に直接マッピング
            newQuestion.setText(claudeQuestion.getText());
            newQuestion.setAnswer(claudeQuestion.getAnswer());
            newQuestion.setCompleteSentence(claudeQuestion.getCompleteSentence());
            newQuestion.setQuestionFormat(com.example.api.enums.QuestionFormat.fromValue(questionFormat));
            newQuestion.setDifficultyLevel(claudeQuestion.getDifficultyLevel());
          
            newQuestion.setLanguage(targetLanguage);  // ユーザーの学習言語を設定
            newQuestion.setTranslationJa(claudeQuestion.getTranslationJa());

            // audioUrl: リスニング問題の場合のみTTSで音声を生成
            if ("listening".equals(questionFormat)) {
                String audioUrl = textToSpeechClient.generateSpeech(claudeQuestion.getCompleteSentence(), targetLanguage);
                newQuestion.setAudioUrl(audioUrl);
                logger.debug("音声URL生成完了: audioUrl={}", audioUrl);
            }

            return questionRepository.save(newQuestion);
        } else {
            // 既存のSongを使用して問題を作成
            Question newQuestion = new Question();
            newQuestion.setSong(song);
            Artist artist = artistRepository.findById(song.getAritst_id()).orElse(null);
            newQuestion.setArtist(artist);

            logger.debug("Setting question - text='{}', answer='{}', completeSentence='{}'",
                claudeQuestion.getText(), claudeQuestion.getAnswer(), claudeQuestion.getCompleteSentence());

            newQuestion.setText(claudeQuestion.getText());
            newQuestion.setAnswer(claudeQuestion.getAnswer());
            newQuestion.setCompleteSentence(claudeQuestion.getCompleteSentence());
            newQuestion.setQuestionFormat(com.example.api.enums.QuestionFormat.fromValue(questionFormat));
            newQuestion.setDifficultyLevel(claudeQuestion.getDifficultyLevel());
            newQuestion.setLanguage(targetLanguage);
            newQuestion.setTranslationJa(claudeQuestion.getTranslationJa());

            if ("listening".equals(questionFormat)) {
                String audioUrl = textToSpeechClient.generateSpeech(claudeQuestion.getCompleteSentence(), targetLanguage);
                newQuestion.setAudioUrl(audioUrl);
            }

            return questionRepository.save(newQuestion);
        }
    }

    /**
     * ★★★ お気に入りアーティストの全曲を自動同期（必要な場合のみ） ★★★
     * 
     * 以下の条件を満たす場合、自動で全曲を同期します：
     * 1. このアーティストがお気に入りに登録されている（指定ユーザーの）
     * 2. まだ一度も同期されていない（lastSyncedAt == null）、または1ヶ月以上経過している
     * 
     * @param artist アーティストエンティティ
     * @param currentSong 現在処理中の楽曲（ログ用）
     * @param userId ユーザーID
     */
    private void syncArtistSongsIfNeeded(Artist artist, Song currentSong, Long userId) {
        try {
            // artistApiIdがない場合はスキップ（artistApiIdをSpotifyArtistIdとして使用）
            if (artist.getArtistApiId() == null || artist.getArtistApiId().isEmpty()) {
                logger.debug("ArtistApiIdがないため全曲同期をスキップ: artistId={}", artist.getArtistId());
                return;
            }

            // このアーティストがお気に入りかチェック（ユーザーIDも考慮）
            boolean isFavorite = likeArtistRepository.existsByUserIdAndArtistId(userId, artist.getArtistId());
            
            if (!isFavorite) {
                logger.debug("お気に入りアーティストではないため全曲同期をスキップ: artistId={}, userId={}", 
                    artist.getArtistId(), userId);
                return;
            }

            // 同期が必要かチェック
            LocalDateTime lastSynced = artist.getLastSyncedAt();
            boolean needsSync = false;

            if (lastSynced == null) {
                // 一度も同期されていない
                logger.info("お気に入りアーティストが初めて選択されました。全曲を同期します: artistName={}", artist.getArtistName());
                needsSync = true;
            } else {
                // 1ヶ月以上経過しているかチェック
                LocalDateTime oneMonthAgo = LocalDateTime.now().minusMonths(1);
                if (lastSynced.isBefore(oneMonthAgo)) {
                    logger.info("1ヶ月以上経過しているため全曲を再同期します: artistName={}, lastSynced={}", 
                        artist.getArtistName(), lastSynced);
                    needsSync = true;
                } else {
                    logger.debug("最近同期済みのため全曲同期をスキップ: artistName={}, lastSynced={}", 
                        artist.getArtistName(), lastSynced);
                }
            }

            // 同期実行
            if (needsSync) {
                logger.info("=== お気に入りアーティストの全曲同期を開始 ===");
                logger.info("現在の楽曲: {}", currentSong.getSongname());
                
                int newSongsCount = artistSyncService.syncArtistSongs(artist.getArtistId());
                
                logger.info("=== 全曲同期完了 ===");
                logger.info("新規保存曲数: {}", newSongsCount);
                logger.info("現在の楽曲の問題生成を続行します: {}", currentSong.getSongname());
            }

        } catch (Exception e) {
            // 全曲同期に失敗しても、現在の曲の問題生成は続行
            logger.error("全曲同期中にエラーが発生しましたが、処理を続行します: artistId={}", 
                artist.getArtistId(), e);
        }
    }

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

            // 3. ユーザーの学習言語を取得（問題生成とデータ保存に使用）
            String targetLanguage = request.getTargetLanguage() != null ? request.getTargetLanguage() : "en";
            logger.info("=== TARGET LANGUAGE CHECK ===");
            logger.info("Request targetLanguage: {}", request.getTargetLanguage());
            logger.info("Resolved targetLanguage: {}", targetLanguage);
            logger.info("============================");

            // 4. Gemini APIで問題を生成（ユーザーの学習言語で生成）
            ClaudeQuestionResponse claudeResponse = geminiApiClient.generateQuestions(
                lyrics,
                targetLanguage,
                request.getFillInBlankCount(),
                request.getListeningCount()
            );

            // 5. 問題を保存（ユーザーの学習言語も一緒に保存）
            List<QuestionGenerationResponse.GeneratedQuestionDto> generatedQuestions = new ArrayList<>();

            // Fill-in-blank問題を保存
            for (ClaudeQuestionResponse.Question q : claudeResponse.getFillInBlank()) {
                Question saved = saveQuestion(selectedSong, q, "fill_in_blank", targetLanguage, request.getUserId());
                generatedQuestions.add(convertToDto(saved));
                  saveVocabulary(q.getAnswer(), targetLanguage);
            }

            // Listening問題を保存
            for (ClaudeQuestionResponse.Question q : claudeResponse.getListening()) {
                Question saved = saveQuestion(selectedSong, q, "listening", targetLanguage, request.getUserId());
                generatedQuestions.add(convertToDto(saved));
                
            }

            logger.info("問題生成完了: 合計{}問", generatedQuestions.size());


            // レスポンスを構築
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
                return selectArtistByGenre(request.getGenreName());
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

        Long artistId = randomLikeArtist.getArtist().getArtistId();
        String artistApiId = randomLikeArtist.getArtist().getArtistApiId();

        logger.debug("選択されたアーティスト: artistId={}, artistApiId={}", artistId, artistApiId);

        return songRepository.findRandomByArtist(artistId)
            .orElseGet(() -> spotifyApiClient.getRandomSongBySpotifyArtistId(artistApiId));
    }

    /**
     * ★ 変更 ★
     * ジャンルから楽曲を選択
     * 
     * SpotifyApiClient.getRandomSongsByGenre()がList<Song>を返すようになったため、
     * その中から1曲をランダムに選択して返す。
     * 
     * 処理フロー:
     * 1. SpotifyApiClientから最大5曲を取得
     * 2. リストが空でなければ、その中からランダムに1曲選択
     * 3. リストが空の場合は、ランダム選曲にフォールバック
     * 
     * @param genreName ジャンル名
     * @return 選択された1曲
     */
    private Song selectArtistByGenre(String genreName) {
        logger.debug("ジャンルから楽曲を選択: genre={}", genreName);

        // SpotifyApiClientから最大5曲を取得
        List<Song> songs = spotifyApiClient.getRandomSongsByGenre(genreName);

        if (songs == null || songs.isEmpty()) {
            logger.warn("ジャンル '{}' から楽曲を取得できませんでした。ランダム選曲にフォールバックします。", genreName);
            return selectRandomSong();
        }

        // リストからランダムに1曲選択
        Song selectedSong = songs.get(random.nextInt(songs.size()));
        logger.info("ジャンル '{}' から楽曲を選択: {} (全{}曲から)", genreName, selectedSong.getSongname(), songs.size());

        return selectedSong;
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
     * Geniusで複数候補を試行
     * 歌詞取得成功時、GeniusSongIdと検出された言語をSongに設定
     */
    private String fetchLyrics(Song song) {
        String lyrics = null;

        // アーティスト名をArtistエンティティから取得
        String artistName = getArtistNameFromSong(song);

        // 1. Geniusで検索して複数候補を試行（優先度順）
        if (song.getSongname() != null && artistName != null) {
            logger.info("Geniusで楽曲を検索して歌詞を取得します: artist={}, song={}",
                artistName, song.getSongname());

            GeniusApiClient.LyricsResult result = geniusApiClient.searchAndGetLyricsWithMetadata(
                song.getSongname(), artistName);

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

        // 3. どの方法でも取得できなかった
        logger.error("歌詞を取得できませんでした: songName={}", song.getSongname());
        return null;
    }

    /**
     * Songからアーティスト名を取得するヘルパーメソッド
     * aritst_idを使ってArtistエンティティから取得
     */
    private String getArtistNameFromSong(Song song) {
        if (song.getAritst_id() == null || song.getAritst_id() == 0L) {
            return null;
        }
        
        return artistRepository.findById(song.getAritst_id())
            .map(Artist::getArtistName)
            .orElse(null);
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
     * 単語情報を保存
     * Wordnik APIキーが設定されていない場合はスキップ
     *
     * @param word 単語
     * @param language ユーザーの学習言語（例: "en", "ja", "ko"）
     */
    private void saveVocabulary(String word, String language) {
        logger.info("=== VOCABULARY SAVE REQUEST ===");
        logger.info("Word: {}", word);
        logger.info("Language: {}", language);

        // すでに存在する場合はスキップ
        if (vocabularyRepository.existsByWord(word)) {
            logger.info("単語は既に存在します - スキップ: word={}", word);
            logger.info("===============================");
            return;
        }

        try {
            WordnikWordInfo wordInfo = wordnikApiClient.getWordInfo(word);

            logger.info("WordInfo received:");
            logger.info("  - word: {}", wordInfo != null ? wordInfo.getWord() : "null");
            logger.info("  - meaningJa: {}", wordInfo != null ? wordInfo.getMeaningJa() : "null");
            logger.info("  - pronunciation: {}", wordInfo != null ? wordInfo.getPronunciation() : "null");
            logger.info("  - partOfSpeech: {}", wordInfo != null ? wordInfo.getPartOfSpeech() : "null");

            // モックデータ（APIキーなし）の場合はスキップ
            if (wordInfo == null || wordInfo.getMeaningJa() == null) {
                logger.warn("Wordnik APIが利用できないため単語保存をスキップ: word={}", word);
                logger.info("===============================");
                return;
            }

            // モックデータのメッセージが含まれている場合もスキップ
            if (wordInfo.getMeaningJa().contains("辞書情報を取得できませんでした") ||
                wordInfo.getMeaningJa().equals("No definition available") ||
                wordInfo.getMeaningJa().equals("Definition not available")) {
                logger.warn("有効な定義が取得できなかったため単語保存をスキップ: word={}, meaning={}",
                    word, wordInfo.getMeaningJa());
                logger.info("===============================");
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
            logger.info("✓ 単語情報を保存しました: word={}, language={}", word, language);
            logger.info("===============================");

        } catch (Exception e) {
            logger.error("単語情報の保存に失敗しました: word={}, error={}", word, e.getMessage(), e);
            logger.info("===============================");
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
            .completeSentence(question.getCompleteSentence())
            .questionFormat(question.getQuestionFormat().getValue())
            .difficultyLevel(question.getDifficultyLevel())
            .language(question.getLanguage())
            .translationJa(question.getTranslationJa())
            .audioUrl(question.getAudioUrl())
            .build();
    }

    /**
     * 楽曲情報を構築
     */
    private QuestionGenerationResponse.SongInfo buildSongInfo(Song song) {
        String artistName = "Unknown";
        if (song.getAritst_id() != null) {
            Artist artist = artistRepository.findById(song.getAritst_id()).orElse(null);
            if (artist != null) {
                artistName = artist.getArtistName();
            }
        }

        return QuestionGenerationResponse.SongInfo.builder()
            .songId(song.getSong_id())
            .songName(song.getSongname())
            .artistName(artistName)
            .language(song.getLanguage())
            .build();
    }

}