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
import com.example.api.repository.UserRepository;
import com.example.api.repository.WeeklyLessonsRepository;
import com.example.api.entity.User;
import com.example.api.entity.WeeklyLessons;
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

    /** ★ 追加: ランダム選択用 */
    private final Random random = new Random();

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
    private UserVocabularyService userVocabularyService;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private WeeklyLessonsRepository weeklyLessonsRepository;

        /**
     * Songからアーティスト名を取得するヘルパーメソッド
     * aritst_idを使ってArtistエンティティから取得
     */
    private String getArtistNameFromSong(Song song) {
        if (song.getArtistId() == null || song.getArtistId() == 0L) {
            return null;
        }
        
        return artistRepository.findById(song.getArtistId())
            .map(Artist::getArtistName)
            .orElse(null);
    }

    /**
     * クイズ開始
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
            Song actualSong = selectedSong; // ★ 実際に使用するSong（新規生成後は更新される）

            if (selectedSong != null) {
                // 2. 曲が選択された場合、50問チェック
                // ★ selectedSong.getSongId()がnullの場合（新規Song）は0問として扱う
                Long songId = selectedSong.getSongId();
                long questionCount = (songId != null) ? questionRepository.countBySongId(songId) : 0;
                logger.info("既存の問題数: songId={}, count={}", songId, questionCount);

                if (questionCount >= QUESTION_THRESHOLD) {
                    // DBから問題を取得
                    questions = getQuestionsFromDatabase(songId, request);
                    logger.info("DBから問題を取得: count={}", questions.size());
                } else {
                    // 新規生成
                    questions = generateNewQuestions(selectedSong, request);
                    logger.info("新規問題を生成: count={}", questions.size());
                    
                    // ★ 新規生成後、問題リストからSong情報を取得（保存後のIDを持つ）
                    if (!questions.isEmpty() && questions.get(0).getSong() != null) {
                        actualSong = questions.get(0).getSong();
                        logger.debug("新規生成後のSong情報を更新: songId={}", actualSong.getSongId());
                    }
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
            LHistory history = saveQuizSession(request, questions, actualSong);

            // 5. レスポンスを構築
            List<QuizStartResponse.QuizQuestion> quizQuestions = questions.stream()
                .map(this::convertToQuizQuestion)
                .collect(Collectors.toList());

            QuizStartResponse.SongInfo songInfo = null;
            if (actualSong != null && actualSong.getSongId() != null) {
                String artistName = getArtistNameFromSong(actualSong);
                // アーティスト名がnullの場合はフォールバック
                if (artistName == null || artistName.isEmpty()) {
                    artistName = "Unknown Artist";
                }

                songInfo = QuizStartResponse.SongInfo.builder()
                    .songId(actualSong.getSongId())
                    .songName(actualSong.getSongname())
                    .artistName(artistName)
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
                    // ★ 正解判定: リスニング問題はcompleteSentenceと比較
                    String correctAnswer;
                    if (com.example.api.enums.QuestionFormat.LISTENING.equals(q.getQuestionFormat())) {
                        correctAnswer = q.getCompleteSentence() != null ? q.getCompleteSentence() : q.getText();
                    } else {
                        correctAnswer = q.getAnswer();
                    }
                    
                    boolean isCorrect = correctAnswer.trim().equalsIgnoreCase(answer.getUserAnswer().trim());
                    if (isCorrect) correctCount++;

                    // ★ UserVocabularyに非同期で登録（レスポンスを高速化）
                    if (com.example.api.enums.QuestionFormat.FILL_IN_THE_BLANK.equals(q.getQuestionFormat())) {
                        // FILL_IN_BLANK: 全ての問題のanswerを登録
                        userVocabularyService.registerFillInBlankAnswerAsync(request.getUserId(), q.getAnswer());
                    } else if (com.example.api.enums.QuestionFormat.LISTENING.equals(q.getQuestionFormat()) && !isCorrect) {
                        // LISTENING: 不正解の場合、間違えた単語を登録
                        userVocabularyService.registerListeningMistakesAsync(
                            request.getUserId(),
                            answer.getUserAnswer(),
                            correctAnswer
                        );
                    }

                    questionResults.add(QuizCompleteResponse.QuestionResult.builder()
                        .questionId(q.getQuestionId())
                        .questionText(q.getText())
                        .questionFormat(q.getQuestionFormat().getValue())
                        .correctAnswer(correctAnswer)
                        .userAnswer(answer.getUserAnswer())
                        .isCorrect(isCorrect)
                        .difficultyLevel(q.getDifficultyLevel())
                        .build());
                }
            }

            // 3. 結果をl_historyに更新
            updateQuizResult(history, request.getAnswers(), correctCount);

            // 4. リタイアでない場合、カウントを増加
            if (request.getRetired() == null || !request.getRetired()) {
                // User.totalPlay を +1
                User user = userRepository.findById(request.getUserId())
                    .orElseThrow(() -> new IllegalArgumentException("ユーザーが見つかりません: " + request.getUserId()));
                user.setTotalPlay(user.getTotalPlay() + 1);
                userRepository.save(user);
                logger.info("User.totalPlay を更新: userId={}, newTotalPlay={}", user.getId(), user.getTotalPlay());

                // WeeklyLessons.lessonsNum を +1
                WeeklyLessons weeklyLessons = weeklyLessonsRepository
                    .findByUserAndWeekFlag(user, true)
                    .stream()
                    .findFirst()
                    .orElseGet(() -> {
                        WeeklyLessons newWl = new WeeklyLessons(user);
                        return weeklyLessonsRepository.save(newWl);
                    });
                weeklyLessons.setLessonsNum(weeklyLessons.getLessonsNum() + 1);
                weeklyLessonsRepository.save(weeklyLessons);
                logger.info("WeeklyLessons.lessonsNum を更新: userId={}, newLessonsNum={}", user.getId(), weeklyLessons.getLessonsNum());
            } else {
                logger.info("リタイアのためカウント増加をスキップ: userId={}", request.getUserId());
            }

            // 5. 正解率を計算
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
     * @param genreName ジャンル名
     * @return 選択された1曲
     */
    private Song selectSongByGenre(String genreName) {
        logger.debug("ジャンルから楽曲を選択: genre={}", genreName);

        // SpotifyApiClientから最大5曲を取得
        List<Song> songs = spotifyApiClient.getRandomSongsByGenre(genreName);

        if (songs == null || songs.isEmpty()) {
            logger.warn("ジャンル '{}' から楽曲を取得できませんでした。ランダム選曲にフォールバックします。", genreName);
            return songRepository.findRandom().orElse(null);
        }

        // リストからランダムに1曲選択
        Song selectedSong = songs.get(random.nextInt(songs.size()));
        logger.info("ジャンル '{}' から楽曲を選択: {} (全{}曲から)", genreName, selectedSong.getSongname(), songs.size());

        return selectedSong;
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

        // ★ 修正: ResponseからsongIdを取得（新規Songの場合、selectedSongのIDはnullのため）
        Long songId = (response.getSongInfo() != null && response.getSongInfo().getSongId() != null)
            ? response.getSongInfo().getSongId()
            : selectedSong.getSongId();
        
        logger.debug("問題取得用songId: {} (selectedSong.getSongId()={}, response.songId={})",
            songId, 
            selectedSong.getSongId(),
            response.getSongInfo() != null ? response.getSongInfo().getSongId() : "null");

        // 生成された問題を取得
        return questionRepository.findBySongId(songId);
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
     * 
     * リスニング問題の場合:
     *   - answer に completeSentence を設定（ユーザーが入力すべき完全な文）
     * 
     * 虫食い問題の場合:
     *   - answer に answer を設定（空欄に入る単語）
     */
    private QuizStartResponse.QuizQuestion convertToQuizQuestion(Question q) {
        // ★ リスニング問題の場合はanswerにcompleteSentenceを設定
        String answerValue;
        if (com.example.api.enums.QuestionFormat.LISTENING.equals(q.getQuestionFormat())) {
            // リスニング: 完全な文を正解とする
            answerValue = q.getCompleteSentence() != null ? q.getCompleteSentence() : q.getText();
        } else {
            // 虫食い: 空欄に入る単語を正解とする
            answerValue = q.getAnswer();
        }

        return QuizStartResponse.QuizQuestion.builder()
            .questionId(q.getQuestionId())
            .text(q.getText())
            .questionFormat(q.getQuestionFormat().getValue())
            .difficultyLevel(q.getDifficultyLevel())
            .audioUrl(q.getAudioUrl())
            .language(q.getLanguage())
            .answer(answerValue)
            .completeSentence(q.getCompleteSentence())  // ★ 追加
            .translationJa(q.getTranslationJa())        // ★ 追加
            .build();
    }



    /**
     * 言語名をTTS言語コードに変換
     */
   
}