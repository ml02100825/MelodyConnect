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

/**
 * 問題生成サービス
 * 歌詞から問題を自動生成し、データベースに保存します
 * 
 * お気に入りアーティストの場合、初回または1ヶ月経過後に自動で全曲を同期します
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

    @Autowired
    private TextToSpeechClient textToSpeechClient;

    // ★ ArtistSyncServiceを注入
    @Autowired
    private ArtistSyncService artistSyncService;

    /**
     * 問題を保存
     *
     * @param song 楽曲エンティティ
     * @param claudeQuestion Gemini APIから取得した問題データ
     * @param questionFormat 問題形式（"fill_in_blank" or "listening"）
     * @param targetLanguage ユーザーの学習言語（問題の言語として使用）
     */
    private Question saveQuestion(Song song, ClaudeQuestionResponse.Question claudeQuestion, String questionFormat, String targetLanguage) {
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
                            
                            // ★ SpotifyアーティストIDも設定（tempから）
                            if (song.getTempArtistApiId() != null) {
                                newArtist.setSpotifyArtistId(song.getTempArtistApiId());
                            }
                            
                            return artistRepository.save(newArtist);
                        });
                    song.setAritst_id(artist.getArtistId().longValue());
                    logger.debug("Artist設定完了: artistId={}, artistName={}", artist.getArtistId(), artist.getArtistName());
                    
                    // ★★★ ここで、お気に入りアーティストの全曲を自動同期 ★★★
                    syncArtistSongsIfNeeded(artist, song);
                    
                } else {
                    logger.warn("Songにアーティスト情報がありません。デフォルトのartist_id=1を使用します。");
                    song.setAritst_id(1L);
                }
            }

            logger.debug("Songを保存します: songName={}", song.getSongname());
            Song savedSong = songRepository.save(song);
            logger.debug("Song保存完了: songId={}", savedSong.getSong_id());

            Question newQuestion = new Question();
            newQuestion.setSong(savedSong);
            // Artist is set via the song's artist_id - fetch from repository if needed
            Artist artist = artistRepository.findById(savedSong.getAritst_id().intValue()).orElse(null);
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
            Artist artist = artistRepository.findById(song.getAritst_id().intValue()).orElse(null);
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
     * 1. このアーティストがお気に入りに登録されている
     * 2. まだ一度も同期されていない（lastSyncedAt == null）、または1ヶ月以上経過している
     * 
     * @param artist アーティストエンティティ
     * @param currentSong 現在処理中の楽曲（ログ用）
     */
    private void syncArtistSongsIfNeeded(Artist artist, Song currentSong) {
        try {
            // SpotifyアーティストIDがない場合はスキップ
            if (artist.getSpotifyArtistId() == null || artist.getSpotifyArtistId().isEmpty()) {
                logger.debug("SpotifyアーティストIDがないため全曲同期をスキップ: artistId={}", artist.getArtistId());
                return;
            }

            // このアーティストがお気に入りかチェック
            // ※ 実装によっては user_id を渡す必要がある場合、メソッドシグネチャを変更してください
            boolean isFavorite = likeArtistRepository.existsByArtistId(artist.getArtistId());
            
            if (!isFavorite) {
                logger.debug("お気に入りアーティストではないため全曲同期をスキップ: artistId={}", artist.getArtistId());
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

    // ★★★ 以下、元のメソッドはそのまま維持 ★★★
    // （generateQuestions、selectSong、fetchLyrics等のメソッドは変更なし）
    
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
            List<Question> savedQuestions = new ArrayList<>();

            // Fill-in-blank問題を保存
            for (ClaudeQuestionResponse.Question q : claudeResponse.getFillInBlank()) {
                Question saved = saveQuestion(selectedSong, q, "fill_in_blank", targetLanguage);
                savedQuestions.add(saved);
            }

            // Listening問題を保存
            for (ClaudeQuestionResponse.Question q : claudeResponse.getListening()) {
                Question saved = saveQuestion(selectedSong, q, "listening", targetLanguage);
                savedQuestions.add(saved);
            }

            logger.info("問題生成完了: 合計{}問", savedQuestions.size());

            // レスポンスを構築
            return QuestionGenerationResponse.builder()
                .questions(savedQuestions)
                .songId(selectedSong.getSong_id())
                .songName(selectedSong.getSongname())
                .build();

        } catch (Exception e) {
            logger.error("問題生成中にエラーが発生しました", e);
            throw new RuntimeException("問題生成に失敗しました: " + e.getMessage(), e);
        }
    }

    // 他のメソッド（selectSong、fetchLyrics等）は元のまま
    // ...（省略）
}