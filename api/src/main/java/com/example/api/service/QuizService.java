package com.example.api.service;

import com.example.api.dto.*;
import com.example.api.entity.Artist;
import com.example.api.entity.LHistory;
import com.example.api.entity.Question;
import com.example.api.entity.Song;
import com.example.api.repository.LHistoryRepository;
import com.example.api.repository.LikeArtistRepository;
import com.example.api.repository.QuestionRepository;
import com.example.api.repository.SongRepository;
import com.example.api.repository.ArtistRepository;
import com.example.api.client.SpotifyApiClient;

import com.example.api.entity.LikeArtist;
import com.example.api.enums.QuestionFormat;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.stream.Collectors;

/**
 * クイズサービス
 * 学習機能の問題取得・結果保存を管理します
 */
@Service
public class QuizService {

    private static final Logger logger = LoggerFactory.getLogger(QuizService.class);
    private static final int QUESTION_THRESHOLD = 50;

    @Autowired
    private QuestionRepository questionRepository;

    @Autowired
    private SongRepository songRepository;

    @Autowired
    private LHistoryRepository lHistoryRepository;

    @Autowired
    private LikeArtistRepository likeArtistRepository;
    @Autowired
    private ArtistRepository artistRepository;

    @Autowired
    private SpotifyApiClient spotifyApiClient;

    @Autowired
    private QuestionGeneratorService questionGeneratorService;

    @Autowired
    private VocabularyService vocabularyService;

    @Autowired
    private ObjectMapper objectMapper;

        /**
     * Songからアーティスト名を取得するヘルパーメソッド
     * aritst_idを使ってArtistエンティティから取得
     */
    private String getArtistNameFromSong(Song song) {
        if (song.getAritst_id() == null || song.getAritst_id() == 0L) {
            return null;
        }
        
        return artistRepository.findById(song.getAritst_id().intValue())
            .map(Artist::getArtistName)
            .orElse(null);
    }

    /**
     * クイズを開始
     * 50問以上あればDBから取得、なければ新規生成
     */
    @Transactional
    public QuizStartResponse startQuiz(QuizStartRequest request) {
        logger.info("クイズ開始: userId={}, language={}, mode={}, format={}, count={}",
            request.getUserId(), request.getLanguage(), request.getGenerationMode(),
            request.getQuestionFormat(), request.getQuestionCount());

        try {
            // 1. 問題生成モードに基づいて曲を選択
            Song selectedSong = selectSong(request);

            List<Question> questions;

            if (selectedSong != null) {
                // 2. 曲が選択された場合、50問チェック
                long questionCount = questionRepository.countBySongId(selectedSong.getSong_id());
                logger.info("既存の問題数: songId={}, count={}", selectedSong.getSong_id(), questionCount);

                if (questionCount >= QUESTION_THRESHOLD) {
                    // DBから問題を取得
                    questions = getQuestionsFromDatabase(selectedSong.getSong_id(), request);
                    logger.info("DBから問題を取得: count={}", questions.size());
                } else {
                    // 新規生成
                    questions = generateNewQuestions(selectedSong, request);
                    logger.info("新規問題を生成: count={}", questions.size());
                }
            } else {
                // 曲が選択されない場合（言語のみで検索）
                questions = getQuestionsByLanguage(request);
                logger.info("言語で問題を取得: count={}", questions.size());
            }

            // 3. 問題をシャッフルして必要数を取得
            Collections.shuffle(questions);
            int requestedCount = Math.min(request.getQuestionCount(), questions.size());
            questions = questions.subList(0, requestedCount);

            // 4. l_historyに保存
            LHistory history = saveQuizSession(request, questions, selectedSong);

            // 5. レスポンスを構築
            List<QuizStartResponse.QuizQuestion> quizQuestions = questions.stream()
                .map(this::convertToQuizQuestion)
                .collect(Collectors.toList());

            QuizStartResponse.SongInfo songInfo = null;
            if (selectedSong != null) {
                String artistName = getArtistNameFromSong(selectedSong);
  
                songInfo = QuizStartResponse.SongInfo.builder()
                    .songId(selectedSong.getSong_id())
                    .songName(selectedSong.getSongname())
                    .artistName(artistName) // TODO:
                    .build();
            }

            return QuizStartResponse.builder()
                .sessionId(history.getL_history_id())
                .questions(quizQuestions)
                .songInfo(songInfo)
                .totalCount(quizQuestions.size())
                .message("クイズを開始しました")
                .build();

        } catch (Exception e) {
            logger.error("クイズ開始中にエラーが発生しました", e);
            throw new RuntimeException("クイズの開始に失敗しました: " + e.getMessage(), e);
        }
    }

    /**
     * クイズを完了して結果を保存
     */
    @Transactional
    public QuizCompleteResponse completeQuiz(QuizCompleteRequest request) {
        logger.info("クイズ完了: sessionId={}, userId={}", request.getSessionId(), request.getUserId());

        try {
            // 1. セッションを取得
            LHistory history = lHistoryRepository.findById(request.getSessionId())
                .orElseThrow(() -> new IllegalArgumentException("セッションが見つかりません: " + request.getSessionId()));

            // 2. 結果を計算
            int correctCount = 0;
            List<QuizCompleteResponse.QuestionResult> questionResults = new ArrayList<>();

            for (QuizCompleteRequest.AnswerResult answer : request.getAnswers()) {
                Question q = questionRepository.findById(answer.getQuestionId())
                    .orElse(null);

                if (q != null) {
                    boolean isCorrect = q.getAnswer().trim().equalsIgnoreCase(answer.getUserAnswer().trim());
                    if (isCorrect) correctCount++;

                    // リスニング問題で間違えた場合、単語を保存
                    if (com.example.api.enums.QuestionFormat.LISTENING.equals(q.getQuestionFormat()) && !isCorrect) {
                        vocabularyService.saveIncorrectWords(answer.getUserAnswer(), q.getAnswer());
                    }

                    questionResults.add(QuizCompleteResponse.QuestionResult.builder()
                        .questionId(q.getQuestionId())
                        .questionText(q.getText())
                        .questionFormat(q.getQuestionFormat().getValue())
                        .correctAnswer(q.getAnswer())
                        .userAnswer(answer.getUserAnswer())
                        .isCorrect(isCorrect)
                        .difficultyLevel(q.getDifficultyLevel())
                        .build());
                }
            }

            // 3. 結果をl_historyに更新
            updateQuizResult(history, request.getAnswers(), correctCount);

            // 4. 正解率を計算
            double accuracy = request.getAnswers().isEmpty() ? 0 :
                (double) correctCount / request.getAnswers().size();

            return QuizCompleteResponse.builder()
                .sessionId(request.getSessionId())
                .correctCount(correctCount)
                .totalCount(request.getAnswers().size())
                .accuracy(accuracy)
                .questionResults(questionResults)
                .message(String.format("クイズ完了！正解率: %.1f%%", accuracy * 100))
                .build();

        } catch (Exception e) {
            logger.error("クイズ完了処理中にエラーが発生しました", e);
            throw new RuntimeException("クイズの完了処理に失敗しました: " + e.getMessage(), e);
        }
    }

    /**
     * 問題生成モードに基づいて曲を選択
     */
    private Song selectSong(QuizStartRequest request) {
        String mode = request.getGenerationMode();

        switch (mode) {
            case "COMPLETE_RANDOM":
                // 完全ランダムの場合は曲を選ばずに言語で検索
                return null;

            case "FAVORITE_ARTIST":
                // お気に入りアーティストから選択
                return selectSongFromFavoriteArtist(request.getUserId());

            case "GENRE_RANDOM":
                // ジャンルから選択
                return selectSongByGenre(request.getGenreName());

            case "URL_INPUT":
                // URLから選択（TODO: 実装）
                return songRepository.findRandom().orElse(null);

            default:
                return songRepository.findRandom().orElse(null);
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
     * DBから問題を取得
     */
    private List<Question> getQuestionsFromDatabase(Long songId, QuizStartRequest request) {
        String format = request.getQuestionFormat();

        if ("LISTENING_ONLY".equals(format)) {
            return questionRepository.findBySongIdAndQuestionFormat(songId, com.example.api.enums.QuestionFormat.LISTENING);
        } else if ("FILL_IN_BLANK_ONLY".equals(format)) {
            return questionRepository.findBySongIdAndQuestionFormat(songId, com.example.api.enums.QuestionFormat.FILL_IN_THE_BLANK);
        } else {
            // ALL_RANDOM
            return questionRepository.findBySongId(songId);
        }
    }

    /**
     * 言語で問題を取得（COMPLETE_RANDOMモード用）
     */
    private List<Question> getQuestionsByLanguage(QuizStartRequest request) {
        String language = request.getLanguage();
        String format = request.getQuestionFormat();

        if ("LISTENING_ONLY".equals(format)) {
            return questionRepository.findByLanguageAndQuestionFormat(language, com.example.api.enums.QuestionFormat.LISTENING);
        } else if ("FILL_IN_BLANK_ONLY".equals(format)) {
            return questionRepository.findByLanguageAndQuestionFormat(language, com.example.api.enums.QuestionFormat.FILL_IN_THE_BLANK);
        } else {
            return questionRepository.findByLanguage(language);
        }
    }

    /**
     * 新規問題を生成
     */
    private List<Question> generateNewQuestions(Song selectedSong, QuizStartRequest request) {
        // 問題生成リクエストを作成
        int fillInBlankCount = 10;
        int listeningCount = 10;

        String format = request.getQuestionFormat();
        if ("LISTENING_ONLY".equals(format)) {
            fillInBlankCount = 0;
            listeningCount = request.getQuestionCount();
        } else if ("FILL_IN_BLANK_ONLY".equals(format)) {
            fillInBlankCount = request.getQuestionCount();
            listeningCount = 0;
        }

        QuestionGenerationRequest genRequest = QuestionGenerationRequest.builder()
            .mode(QuestionGenerationRequest.GenerationMode.valueOf(request.getGenerationMode()))
            .userId(request.getUserId())
            .genreName(request.getGenreName())
            .songUrl(request.getSongUrl())
            .fillInBlankCount(fillInBlankCount)
            .listeningCount(listeningCount)
            .build();

        // 問題を生成
        QuestionGenerationResponse response = questionGeneratorService.generateQuestions(genRequest);

        // 生成された問題を取得
        return questionRepository.findBySongId(selectedSong.getSong_id());
    }

    /**
     * クイズセッションを保存
     */
    private LHistory saveQuizSession(QuizStartRequest request, List<Question> questions, Song selectedSong) {
        try {
            LHistory history = new LHistory();
            history.setUser_id(request.getUserId());
            history.setLearning_at(LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss")));
            history.setLearning_lang(request.getLanguage());

            // 問題IDリストをJSON化
            List<Integer> questionIds = questions.stream()
                .map(Question::getQuestionId)
                .collect(Collectors.toList());
            history.setQuestions(objectMapper.writeValueAsString(questionIds));

            // テスト形式
            Map<String, String> testFormat = Map.of("mode", request.getGenerationMode());
            history.setTest_format(objectMapper.writeValueAsString(testFormat));

            // 問題形式
            Map<String, String> questionsFormat = Map.of("format", request.getQuestionFormat());
            history.setQuestions_format(objectMapper.writeValueAsString(questionsFormat));

            // 結果は空で初期化
            history.setResult(objectMapper.writeValueAsString(Map.of()));

            return lHistoryRepository.save(history);

        } catch (JsonProcessingException e) {
            throw new RuntimeException("JSON変換に失敗しました", e);
        }
    }

    /**
     * クイズ結果を更新
     */
    private void updateQuizResult(LHistory history, List<QuizCompleteRequest.AnswerResult> answers, int correctCount) {
        try {
            Map<String, Object> result = new HashMap<>();
            result.put("correctCount", correctCount);
            result.put("totalCount", answers.size());
            result.put("accuracy", answers.isEmpty() ? 0 : (double) correctCount / answers.size());

            // 各回答の詳細
            List<Map<String, Object>> answerDetails = answers.stream()
                .map(a -> {
                    Map<String, Object> detail = new HashMap<>();
                    detail.put("questionId", a.getQuestionId());
                    detail.put("userAnswer", a.getUserAnswer());
                    detail.put("isCorrect", a.getIsCorrect());
                    return detail;
                })
                .collect(Collectors.toList());
            result.put("answers", answerDetails);

            history.setResult(objectMapper.writeValueAsString(result));
            lHistoryRepository.save(history);

        } catch (JsonProcessingException e) {
            throw new RuntimeException("結果のJSON変換に失敗しました", e);
        }
    }

    /**
     * questionエンティティをQuizQuestionDTOに変換
     */
    private QuizStartResponse.QuizQuestion convertToQuizQuestion(Question q) {

     
        

        return QuizStartResponse.QuizQuestion.builder()
            .questionId(q.getQuestionId())
            .text(q.getText())
            .questionFormat(q.getQuestionFormat().getValue())
            .difficultyLevel(q.getDifficultyLevel())
            .audioUrl(q.getAudioUrl())
            .language(q.getLanguage())

            .build();
    }



    /**
     * 言語名をTTS言語コードに変換
     */
   
}
