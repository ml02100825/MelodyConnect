package com.example.api.service;

import com.example.api.dto.battle.BattleStartResponseDto;
import com.example.api.dto.battle.PlayerInfoDto;
import com.example.api.entity.Question;
import com.example.api.entity.Rate;
import com.example.api.entity.Result;
import com.example.api.entity.Room;
import com.example.api.entity.User;
import com.example.api.enums.QuestionFormat;
import com.example.api.repository.QuestionRepository;
import com.example.api.repository.RateRepository;
import com.example.api.repository.ResultRepository;
import com.example.api.repository.UserRepository;
import com.example.api.service.BattleStateService.BattleState;
import com.example.api.dto.battle.RoundResultResponse;
import com.example.api.util.SeasonCalculator;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.stream.Collectors;

/**
 * 対戦サービス
 * 対戦ロジック、勝敗判定、ELOレート計算、結果保存を管理します
 */
@Service
public class BattleService {

    private static final Logger logger = LoggerFactory.getLogger(BattleService.class);

    /** ELOレーティングのK係数（変動幅を決定） */
    private static final double ELO_K_FACTOR = 32.0;

    /** レートの下限 */
    private static final int MIN_RATE = 100;

    /** 問題数（ランクマッチ） */
    private static final int QUESTION_COUNT = 10;

    @Autowired
    private BattleStateService battleStateService;

    @Autowired
    private QuestionRepository questionRepository;

    @Autowired
    private ResultRepository resultRepository;

    @Autowired
    private RateRepository rateRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private SeasonCalculator seasonCalculator;

    @Autowired
    private UserVocabularyService userVocabularyService;

    @Autowired
    private RoomService roomService;

    /**
     * 対戦結果DTO（リザルト画面用）
     */
    public static class BattleResultDto {
        private final String matchUuid;
        private final Long winnerId;
        private final Long loserId;
        private final boolean isDraw;
        private final int winnerScore;
        private final int loserScore;
        private final int winnerRateChange;
        private final int loserRateChange;
        private final int winnerNewRate;
        private final int loserNewRate;
        private final List<RoundResultResponse> rounds;
        private final Result.OutcomeReason outcomeReason;

        public BattleResultDto(
        String matchUuid, Long winnerId, Long loserId, boolean isDraw,
        int winnerScore, int loserScore,
        int winnerRateChange, int loserRateChange,
        int winnerNewRate, int loserNewRate,
        List<RoundResultResponse> rounds, Result.OutcomeReason outcomeReason
                                                                         ) {                                                                                                                                    {
            this.matchUuid = matchUuid;
            this.winnerId = winnerId;
            this.loserId = loserId;
            this.isDraw = isDraw;
            this.winnerScore = winnerScore;
            this.loserScore = loserScore;
            this.winnerRateChange = winnerRateChange;
            this.loserRateChange = loserRateChange;
            this.winnerNewRate = winnerNewRate;
            this.loserNewRate = loserNewRate;
            this.rounds = rounds;
            this.outcomeReason = outcomeReason;
                                                                         }
        }

        // Getters
        public String getMatchUuid() { return matchUuid; }
        public Long getWinnerId() { return winnerId; }
        public Long getLoserId() { return loserId; }
        public boolean isDraw() { return isDraw; }
        public int getWinnerScore() { return winnerScore; }
        public int getLoserScore() { return loserScore; }
        public int getWinnerRateChange() { return winnerRateChange; }
        public int getLoserRateChange() { return loserRateChange; }
        public int getWinnerNewRate() { return winnerNewRate; }
        public int getLoserNewRate() { return loserNewRate; }
        public List<RoundResultResponse> getRounds() { return rounds; }
        public Result.OutcomeReason getOutcomeReason() { return outcomeReason; }

        /**
         * 指定ユーザー視点のリザルト情報を取得
         */
        public Map<String, Object> toPlayerView(Long userId) {
            Map<String, Object> view = new HashMap<>();
            view.put("matchUuid", matchUuid);
            view.put("outcomeReason", outcomeReason.name());
            view.put("rounds", rounds);

            if (isDraw) {
                view.put("result", "draw");
                view.put("myScore", winnerId.equals(userId) ? winnerScore : loserScore);
                view.put("opponentScore", winnerId.equals(userId) ? loserScore : winnerScore);
                view.put("rateChange", 0);
                view.put("newRate", winnerId.equals(userId) ? winnerNewRate : loserNewRate);
            } else if (winnerId.equals(userId)) {
                view.put("result", "win");
                view.put("myScore", winnerScore);
                view.put("opponentScore", loserScore);
                view.put("rateChange", winnerRateChange);
                view.put("newRate", winnerNewRate);
            } else {
                view.put("result", "lose");
                view.put("myScore", loserScore);
                view.put("opponentScore", winnerScore);
                view.put("rateChange", loserRateChange);
                view.put("newRate", loserNewRate);
            }

            return view;
        }
    }

    /**
     * ラウンドサマリー
     */
    public static class RoundSummary {
        private final int roundNumber;
        private final Integer questionId;
        private final Long roundWinnerId;
        private final boolean isNoCount;
        private final String noCountReason;
        private final Map<Long, PlayerRoundInfo> playerInfo;

        public RoundSummary(int roundNumber, Integer questionId, Long roundWinnerId,
                          boolean isNoCount, String noCountReason,
                          Map<Long, PlayerRoundInfo> playerInfo) {
            this.roundNumber = roundNumber;
            this.questionId = questionId;
            this.roundWinnerId = roundWinnerId;
            this.isNoCount = isNoCount;
            this.noCountReason = noCountReason;
            this.playerInfo = playerInfo;
        }

        public int getRoundNumber() { return roundNumber; }
        public Integer getQuestionId() { return questionId; }
        public Long getRoundWinnerId() { return roundWinnerId; }
        public boolean isNoCount() { return isNoCount; }
        public String getNoCountReason() { return noCountReason; }
        public Map<Long, PlayerRoundInfo> getPlayerInfo() { return playerInfo; }
    }

    /**
     * プレイヤーのラウンド情報
     */
    public static class PlayerRoundInfo {
        private final boolean isCorrect;
        private final long responseTimeMs;
        private final String answer;

        public PlayerRoundInfo(boolean isCorrect, long responseTimeMs, String answer) {
            this.isCorrect = isCorrect;
            this.responseTimeMs = responseTimeMs;
            this.answer = answer;
        }

        public boolean isCorrect() { return isCorrect; }
        public long getResponseTimeMs() { return responseTimeMs; }
        public String getAnswer() { return answer; }
    }

    /**
     * 対戦を初期化（問題取得・状態作成）
     */
    @Transactional(readOnly = true)
    public BattleStateService.BattleState initializeBattle(String matchUuid, Long player1Id,
                                                           Long player2Id, String language) {
        // 既に存在する場合はそれを返す
        BattleStateService.BattleState existing = battleStateService.getBattle(matchUuid);
        if (existing != null) {
            return existing;
        }

        // 言語コードを変換（マッチング時のコードをDB用に変換）
        String dbLanguageCode = convertToDbLanguageCode(language);

        // 問題を取得（言語でフィルタしてランダムに10問選択）
        List<Question> allQuestions = questionRepository.findByLanguage(dbLanguageCode);

        if (allQuestions.size() < QUESTION_COUNT) {
            logger.warn("問題数が不足: language={}, available={}, required={}",
                    language, allQuestions.size(), QUESTION_COUNT);
            // 問題が足りない場合は全問使用
            if (allQuestions.isEmpty()) {
                throw new IllegalStateException("問題がありません: language=" + language);
            }
        }

        // シャッフルして10問選択
        List<Question> selectedQuestions = new ArrayList<>(allQuestions);
        Collections.shuffle(selectedQuestions);
        if (selectedQuestions.size() > QUESTION_COUNT) {
            selectedQuestions = selectedQuestions.subList(0, QUESTION_COUNT);
        }

        for (Question question : selectedQuestions) {
            if (question.getSong() != null) {
                question.getSong().getSongname();
            }
            if (question.getArtist() != null) {
                question.getArtist().getArtistName();
            }
        }

        logger.info("対戦初期化: matchUuid={}, questions={}", matchUuid, selectedQuestions.size());

        return battleStateService.createBattle(matchUuid, player1Id, player2Id, language, selectedQuestions);
    }

    /**
     * ルームマッチ用対戦を初期化（問題取得・状態作成）
     * @param matchUuid マッチID
     * @param player1Id プレイヤー1のID（ホスト）
     * @param player2Id プレイヤー2のID（ゲスト）
     * @param language 言語
     * @param winsToVictory 勝利に必要な勝ち数（先取数: 5/7/9）
     * @param roomId ルームID
     * @return 作成された対戦状態
     */
    @Transactional(readOnly = true)
    public BattleStateService.BattleState initializeRoomBattle(String matchUuid, Long player1Id,
                                                                Long player2Id, String language,
                                                                int winsToVictory, Long roomId) {
        // 既に存在する場合はそれを返す
        BattleStateService.BattleState existing = battleStateService.getBattle(matchUuid);
        if (existing != null) {
            return existing;
        }

        // 言語コードを変換（マッチング時のコードをDB用に変換）
        String dbLanguageCode = convertToDbLanguageCode(language);

        // 問題数 = 先取数 + 5
        int questionCount = winsToVictory + 5;

        // 問題を取得（言語でフィルタしてランダムに選択）
        List<Question> allQuestions = questionRepository.findByLanguage(dbLanguageCode);

        if (allQuestions.size() < questionCount) {
            logger.warn("問題数が不足: language={}, available={}, required={}",
                    language, allQuestions.size(), questionCount);
            // 問題が足りない場合は全問使用
            if (allQuestions.isEmpty()) {
                throw new IllegalStateException("問題がありません: language=" + language);
            }
        }

        // シャッフルして必要問題数を選択
        List<Question> selectedQuestions = new ArrayList<>(allQuestions);
        Collections.shuffle(selectedQuestions);
        if (selectedQuestions.size() > questionCount) {
            selectedQuestions = selectedQuestions.subList(0, questionCount);
        }

        for (Question question : selectedQuestions) {
            if (question.getSong() != null) {
                question.getSong().getSongname();
            }
            if (question.getArtist() != null) {
                question.getArtist().getArtistName();
            }
        }

        logger.info("ルームマッチ対戦初期化: matchUuid={}, roomId={}, winsToVictory={}, questions={}",
                matchUuid, roomId, winsToVictory, selectedQuestions.size());

        return battleStateService.createRoomBattle(matchUuid, player1Id, player2Id, language,
                selectedQuestions, winsToVictory, roomId);
    }

    /**
     * ルームマッチ用の初期Resultレコードを作成
     * ランクマッチと異なり、matchType = room
     */
    @Transactional
    public void createRoomMatchResult(String matchUuid, Long hostId, Long guestId, String language) {
        // 既に存在するかチェック
        if (resultRepository.existsByMatchUuidAndPlayerId(matchUuid, hostId)) {
            logger.warn("ルームマッチ結果レコードが既に存在: matchUuid={}, hostId={}", matchUuid, hostId);
            return;
        }

        User host = userRepository.findById(hostId)
                .orElseThrow(() -> new IllegalArgumentException("ホストユーザーが見つかりません: " + hostId));
        User guest = userRepository.findById(guestId)
                .orElseThrow(() -> new IllegalArgumentException("ゲストユーザーが見つかりません: " + guestId));

        // ホスト用Resultレコード
        Result hostResult = new Result();
        hostResult.setPlayer(host);
        hostResult.setEnemy(guest);
        hostResult.setUseLanguage(language);
        hostResult.setMatchUuid(matchUuid);
        hostResult.setMatchType(Result.MatchType.room);  // ルームマッチ
        hostResult.setUpdownRate(0);  // レート変動なし
        resultRepository.save(hostResult);

        // ゲスト用Resultレコード
        Result guestResult = new Result();
        guestResult.setPlayer(guest);
        guestResult.setEnemy(host);
        guestResult.setUseLanguage(language);
        guestResult.setMatchUuid(matchUuid);
        guestResult.setMatchType(Result.MatchType.room);  // ルームマッチ
        guestResult.setUpdownRate(0);  // レート変動なし
        resultRepository.save(guestResult);

        logger.info("ルームマッチ結果レコード作成: matchUuid={}, hostId={}, guestId={}",
                matchUuid, hostId, guestId);
    }

    /**
     * バトル開始（ユーザー情報付き）
     * Controller層でLazy Entityを直接参照しないようにするため、
     * @Transactional 範囲内でUser情報を取得してDTOで返す
     *
     * @param matchId マッチID
     * @return バトル開始レスポンスDTO
     */
   @Transactional(readOnly = true)
public BattleStartResponseDto startBattleWithUserInfo(String matchId) {
    // fetch joinでResult + Userを一括取得
    List<Result> results = resultRepository.findAllByMatchUuidWithUsers(matchId);

    if (results.isEmpty()) {
        throw new IllegalArgumentException("マッチ情報が見つかりません: " + matchId);
    }
    if (results.size() != 2) {
        throw new IllegalArgumentException("マッチ情報が不正です: expected 2, got " + results.size());
    }

    Result result1 = results.get(0);
    User player = result1.getPlayer();
    User enemy = result1.getEnemy();

    // 既存のBattleStateを優先
    BattleStateService.BattleState state = battleStateService.getBattle(matchId);

    // ルームマッチなら Rank用のinitializeBattleを絶対に呼ばない
    if (result1.getMatchType() == Result.MatchType.room) {
        if (state == null) {
            // ルームマッチのstateが無いのは異常なので、ここで止める
            throw new IllegalStateException("ルームマッチの対戦状態が見つかりません: " + matchId);
        }
    } else {
        // ランクマッチのみ initializeBattle を呼ぶ
        if (state == null) {
            state = initializeBattle(
                matchId,
                player.getId(),
                enemy.getId(),
                result1.getUseLanguage()
            );
        }
    }

    Integer player1Rate = getPlayerRate(player);
    Integer player2Rate = getPlayerRate(enemy);

    PlayerInfoDto user1Info = new PlayerInfoDto(
        player.getId(), player.getUsername(), player.getImageUrl(), player1Rate
    );
    PlayerInfoDto user2Info = new PlayerInfoDto(
        enemy.getId(), enemy.getUsername(), enemy.getImageUrl(), player2Rate
    );

    Long hostId = null;
    if (result1.getMatchType() == Result.MatchType.room) {
        Long roomId = state.getRoomId();
        if (roomId != null) {
            Optional<Room> room = roomService.getRoom(roomId);
            if (room.isPresent()) {
                hostId = room.get().getHost_id();
            }
        }
    }

    return BattleStartResponseDto.builder()
        .matchId(matchId)
        .user1Id(state.getPlayer1Id())
        .user2Id(state.getPlayer2Id())
        .language(state.getLanguage())
        .questionCount(state.getQuestions().size())
        .roundTimeLimitSeconds(BattleStateService.ROUND_TIME_LIMIT_SECONDS)
        .winsRequired(state.getWinsToVictory())   // ← 既に修正済みならそのまま
        .maxRounds(state.getMaxRounds())          // ← 同上
        .hostId(hostId)
        .status("ready")
        .message("バトルを開始できます")
        .user1Info(user1Info)
        .user2Info(user2Info)
        .build();
}


    /**
     * ユーザーのレート情報を取得（Service層で使用）
     * @param user ユーザーエンティティ
     * @return レート値（未登録の場合は初期値1500）
     */
    private Integer getPlayerRate(User user) {
        try {
            int currentSeason = seasonCalculator.getCurrentSeason();
            return rateRepository.findByUserAndSeason(user, currentSeason)
                    .map(Rate::getRate)
                    .orElse(1500);  // 未登録の場合は初期値
        } catch (Exception e) {
            logger.warn("レート取得エラー: userId={}", user.getId(), e);
            return 1500;
        }
    }

    /**
     * 対戦開始
     */
    public BattleStateService.BattleState startBattle(String matchUuid) {
        return battleStateService.startBattle(matchUuid);
    }

    /**
     * 回答を記録
     * @return 両者の回答が揃った場合true
     */
    public boolean submitAnswer(String matchUuid, Long userId, String answer) {
        return battleStateService.recordAnswer(matchUuid, userId, answer);
    }

    /**
     * ラウンドを確定して次へ進む
     * @return 対戦が続行可能な場合のラウンド結果、終了した場合はnull
     */
    public BattleStateService.RoundResult processRound(String matchUuid) {
        BattleStateService.RoundResult result = battleStateService.finalizeRound(matchUuid);
        boolean continues = battleStateService.advanceToNextRound(matchUuid);

        if (!continues) {
            logger.info("対戦終了確定: matchUuid={}", matchUuid);
        }

        return result;
    }

    /**
     * 対戦を終了して結果を保存
     * 冪等性：既に終了処理済み（FINISHED状態かつDB保存済み）の場合はスキップ
     */
    @Transactional
    public BattleResultDto finalizeBattle(String matchUuid, Result.OutcomeReason outcomeReason) {
        BattleStateService.BattleState state = battleStateService.getBattle(matchUuid);
        
        if (state == null) {
            throw new IllegalArgumentException("対戦が見つかりません: " + matchUuid);
        }

        // 冪等性チェック：既にFINISHED状態で、DBに結果が保存済みならスキップ
        if (state.getStatus() == BattleStateService.Status.FINISHED) {
            List<Result> existingResults = resultRepository.findAllByMatchUuid(matchUuid);
            // 結果が保存済みかチェック（resultDetailが設定されている = 終了処理済み）
            boolean alreadyFinalized = existingResults.stream()
                    .anyMatch(r -> r.getResultDetail() != null && !r.getResultDetail().isEmpty());

            if (alreadyFinalized) {
                logger.warn("対戦は既に終了処理済み: matchUuid={}", matchUuid);
                battleStateService.removeBattle(matchUuid);
                // 既存の結果からBattleResultDtoを再構築して返す
                return reconstructBattleResult(matchUuid, existingResults, state);
            }
        }

        // 状態を終了に
        battleStateService.finishBattle(matchUuid);

        // 勝者・敗者を確定
        Long winnerId = state.getWinnerId();
        Long loserId = null;
        boolean isDraw = false;

        if (winnerId == null) {
            // 引き分け
            isDraw = true;
            winnerId = state.getPlayer1Id();
            loserId = state.getPlayer2Id();
        } else {
            loserId = winnerId.equals(state.getPlayer1Id()) ? state.getPlayer2Id() : state.getPlayer1Id();
        }

        int winnerScore = winnerId.equals(state.getPlayer1Id()) ? state.getPlayer1Wins() : state.getPlayer2Wins();
        int loserScore = loserId.equals(state.getPlayer1Id()) ? state.getPlayer1Wins() : state.getPlayer2Wins();

        // ELOレート計算（ルームマッチの場合は変動なし）
        int winnerRateChange = 0;
        int loserRateChange = 0;
        int winnerNewRate = 0;
        int loserNewRate = 0;
        boolean isRoomMatch = state.isRoomMatch();

        User winnerUser = userRepository.findById(winnerId).orElseThrow();
        User loserUser = userRepository.findById(loserId).orElseThrow();
        Integer currentSeason = seasonCalculator.getCurrentSeason();

        Rate winnerRate = rateRepository.findByUserAndSeason(winnerUser, currentSeason)
                .orElseGet(() -> new Rate(winnerUser, currentSeason));
        Rate loserRate = rateRepository.findByUserAndSeason(loserUser, currentSeason)
                .orElseGet(() -> new Rate(loserUser, currentSeason));

        int winnerOldRate = winnerRate.getRate();
        int loserOldRate = loserRate.getRate();

        if (isRoomMatch) {
            // ルームマッチの場合はレート変動なし
            winnerNewRate = winnerOldRate;
            loserNewRate = loserOldRate;
            logger.info("ルームマッチのためレート変動なし: winner={}, loser={}", winnerId, loserId);
        } else if (isDraw) {
            // 引き分けの場合はレート変動なし
            winnerNewRate = winnerOldRate;
            loserNewRate = loserOldRate;
        } else {
            // ELOレーティング計算（ランクマッチのみ）
            double expectedWinner = calculateExpectedScore(winnerOldRate, loserOldRate);
            double expectedLoser = calculateExpectedScore(loserOldRate, winnerOldRate);

            winnerRateChange = calculateRatingChange(expectedWinner, 1.0); // 勝利 = 1.0
            loserRateChange = calculateRatingChange(expectedLoser, 0.0);   // 敗北 = 0.0

            winnerNewRate = Math.max(MIN_RATE, winnerOldRate + winnerRateChange);
            loserNewRate = Math.max(MIN_RATE, loserOldRate + loserRateChange);

            // レート更新
            winnerRate.setRate(winnerNewRate);
            loserRate.setRate(loserNewRate);
            rateRepository.save(winnerRate);
            rateRepository.save(loserRate);
        }

        if (!isRoomMatch) {
            logger.info("レート更新: winner={} ({}→{}), loser={} ({}→{})",
                    winnerId, winnerOldRate, winnerNewRate,
                    loserId, loserOldRate, loserNewRate);
        }

        // ラウンドサマリー作成
        List<RoundSummary> roundSummaries = createRoundSummaries(state);
        List<RoundResultResponse> roundResponses =
        createRoundResultResponses(state, outcomeReason, loserId);


        logger.info("finalizeBattle: matchUuid={}, rounds.size={}",
        matchUuid, roundResponses.size());


        // Result更新（既存の2レコードを更新）
        updateResultRecords(matchUuid, state, winnerId, loserId, isDraw,
                winnerRateChange, loserRateChange, winnerNewRate, loserNewRate,
                roundSummaries, outcomeReason);

        // 両プレイヤーの単語帳登録（学習と同じルール）
        registerVocabularyForBothPlayers(state);

        if (isRoomMatch && state.getRoomId() != null) {
            roomService.resetToWaitingAfterMatch(state.getRoomId());
        }

        // メモリから状態削除
        battleStateService.removeBattle(matchUuid);

        return new BattleResultDto(
               matchUuid, winnerId, loserId, isDraw,
                winnerScore, loserScore,
                winnerRateChange, loserRateChange,
                winnerNewRate, loserNewRate,
                roundResponses, outcomeReason
        );
    }

    /**
     * ELO期待勝率を計算
     */
    private double calculateExpectedScore(int playerRating, int opponentRating) {
        return 1.0 / (1.0 + Math.pow(10, (opponentRating - playerRating) / 400.0));
    }

    /**
     * ELOレーティング変動を計算
     */
    private int calculateRatingChange(double expectedScore, double actualScore) {
        return (int) Math.round(ELO_K_FACTOR * (actualScore - expectedScore));
    }

    /**
     * ラウンドサマリーを作成
     */
    private List<RoundSummary> createRoundSummaries(BattleStateService.BattleState state) {
        return state.getRoundResults().stream()
                .map(rr -> {
                    Map<Long, PlayerRoundInfo> playerInfo = new HashMap<>();

                    if (rr.getPlayer1Answer() != null) {
                        playerInfo.put(state.getPlayer1Id(),
                                new PlayerRoundInfo(
                                        rr.getPlayer1Answer().isCorrect(),
                                        rr.getPlayer1Answer().getResponseTimeMs(),
                                        rr.getPlayer1Answer().getAnswer()
                                ));
                    }
                    if (rr.getPlayer2Answer() != null) {
                        playerInfo.put(state.getPlayer2Id(),
                                new PlayerRoundInfo(
                                        rr.getPlayer2Answer().isCorrect(),
                                        rr.getPlayer2Answer().getResponseTimeMs(),
                                        rr.getPlayer2Answer().getAnswer()
                                ));
                    }

                    return new RoundSummary(
                            rr.getRoundNumber(),
                            rr.getQuestionId(),
                            rr.getWinnerId(),
                            rr.isNoCount(),
                            rr.getNoCountReason(),
                            playerInfo
                    );
                })
                .collect(Collectors.toList());
               
    }
    private List<RoundResultResponse> createRoundResultResponses(
          BattleStateService.BattleState state,
        Result.OutcomeReason outcomeReason,
        Long loserId
) {
    Map<Integer, Question> questionMap = state.getQuestions().stream()
        .collect(Collectors.toMap(Question::getQuestionId, q -> q));

    List<RoundResultResponse> responses = new ArrayList<>();

    // 既存ラウンドがある場合は通常通り（+ questionText追加）
    Set<Integer> playedQuestionIds = new HashSet<>();
    if (!state.getRoundResults().isEmpty()) {
        for (BattleStateService.RoundResult rr : state.getRoundResults()) {
            Question q = questionMap.get(rr.getQuestionId());
            String correctAnswer = BattleStateService.getCorrectAnswer(q);

            RoundResultResponse r = new RoundResultResponse();
            r.setRoundNumber(rr.getRoundNumber());
            r.setQuestionId(rr.getQuestionId());
            r.setCorrectAnswer(correctAnswer);
            r.setQuestionText(q != null ? q.getText() : null);
            r.setRoundWinnerId(rr.getWinnerId());
            r.setNoCount(rr.isNoCount());
            r.setNoCountReason(rr.getNoCountReason());

            r.setPlayer1Id(state.getPlayer1Id());
            if (rr.getPlayer1Answer() != null) {
                r.setPlayer1Answer(rr.getPlayer1Answer().getAnswer());
                r.setPlayer1Correct(rr.getPlayer1Answer().isCorrect());
                r.setPlayer1ResponseTimeMs(rr.getPlayer1Answer().getResponseTimeMs());
            }

            r.setPlayer2Id(state.getPlayer2Id());
            if (rr.getPlayer2Answer() != null) {
                r.setPlayer2Answer(rr.getPlayer2Answer().getAnswer());
                r.setPlayer2Correct(rr.getPlayer2Answer().isCorrect());
                r.setPlayer2ResponseTimeMs(rr.getPlayer2Answer().getResponseTimeMs());
            }

            r.setPlayer1Wins(state.getPlayer1Wins());
            r.setPlayer2Wins(state.getPlayer2Wins());
            r.setMatchContinues(false);
            playedQuestionIds.add(rr.getQuestionId());
            responses.add(r);
        }

        // 降参/切断の場合、未プレイの問題も追加
        if (outcomeReason == Result.OutcomeReason.surrender ||
            outcomeReason == Result.OutcomeReason.disconnect) {
            appendFallbackRounds(
                    responses,
                    state,
                    outcomeReason,
                    loserId,
                    responses.size() + 1,
                    playedQuestionIds
            );
        }

        return responses;
    }

    // ここから降参/切断用のフォールバック（プレイ済みラウンドが無い場合）
    if (outcomeReason == Result.OutcomeReason.surrender ||
    outcomeReason == Result.OutcomeReason.disconnect) {

    appendFallbackRounds(
            responses,
            state,
            outcomeReason,
            loserId,
            1,
            null
    );
}


    return responses;
}

    private void appendFallbackRounds(
            List<RoundResultResponse> responses,
            BattleStateService.BattleState state,
            Result.OutcomeReason outcomeReason,
            Long loserId,
            int startRound,
            Set<Integer> playedQuestionIds
    ) {
        String p1Msg = buildFallbackAnswer(outcomeReason, state.getPlayer1Id(), loserId);
        String p2Msg = buildFallbackAnswer(outcomeReason, state.getPlayer2Id(), loserId);

        int round = startRound;
        for (Question q : state.getQuestions()) {
            if (playedQuestionIds != null && playedQuestionIds.contains(q.getQuestionId())) {
                continue;
            }

            RoundResultResponse r = new RoundResultResponse();
            r.setQuestionText(q.getText());
            r.setRoundNumber(round++);
            r.setQuestionId(q.getQuestionId());
            r.setCorrectAnswer(BattleStateService.getCorrectAnswer(q));
            r.setRoundWinnerId(null);
            r.setNoCount(true);
            r.setNoCountReason(outcomeReason.name());

            r.setPlayer1Id(state.getPlayer1Id());
            r.setPlayer1Answer(p1Msg);
            r.setPlayer1Correct(false);
            r.setPlayer1ResponseTimeMs(0);

            r.setPlayer2Id(state.getPlayer2Id());
            r.setPlayer2Answer(p2Msg);
            r.setPlayer2Correct(false);
            r.setPlayer2ResponseTimeMs(0);

            r.setPlayer1Wins(state.getPlayer1Wins());
            r.setPlayer2Wins(state.getPlayer2Wins());
            r.setMatchContinues(false);
            responses.add(r);
        }
    }


    /**
     * Resultレコードを更新
     */
    private void updateResultRecords(String matchUuid, BattleStateService.BattleState state,
                                     Long winnerId, Long loserId, boolean isDraw,
                                     int winnerRateChange, int loserRateChange,
                                     int winnerNewRate, int loserNewRate,
                                     List<RoundSummary> roundSummaries,
                                     Result.OutcomeReason outcomeReason) {
        List<Result> results = resultRepository.findAllByMatchUuid(matchUuid);

        // 問題情報をJSON用に変換
        List<Map<String, Object>> questionData = state.getQuestions().stream()
                .map(q -> {
                    Map<String, Object> qMap = new HashMap<>();
                    qMap.put("questionId", q.getQuestionId());
                    qMap.put("text", q.getText());
                    qMap.put("answer", q.getAnswer());
                    qMap.put("questionFormat", q.getQuestionFormat().name());
                    // リスニング問題用にcompleteSentenceも保存
                    if (q.getCompleteSentence() != null) {
                        qMap.put("completeSentence", q.getCompleteSentence());
                    }
                    return qMap;
                })
                .collect(Collectors.toList());

        Map<String, Object> useQuestion = new HashMap<>();
        useQuestion.put("questions", questionData);

        // ラウンド詳細をJSON用に変換
        List<Map<String, Object>> roundDetailData = roundSummaries.stream()
                .map(rs -> {
                    Map<String, Object> rdMap = new HashMap<>();
                    rdMap.put("roundNumber", rs.getRoundNumber());
                    rdMap.put("questionId", rs.getQuestionId());
                    rdMap.put("winnerId", rs.getRoundWinnerId());
                    rdMap.put("isNoCount", rs.isNoCount());
                    rdMap.put("noCountReason", rs.getNoCountReason());
                    rdMap.put("playerInfo", rs.getPlayerInfo().entrySet().stream()
                            .collect(Collectors.toMap(
                                    e -> e.getKey().toString(),
                                    e -> {
                                        Map<String, Object> piMap = new HashMap<>();
                                        piMap.put("isCorrect", e.getValue().isCorrect());
                                        piMap.put("responseTimeMs", e.getValue().getResponseTimeMs());
                                        piMap.put("answer", e.getValue().getAnswer());
                                        return piMap;
                                    }
                            )));
                    return rdMap;
                })
                .collect(Collectors.toList());

        // 対戦形式情報（動的な先取数を使用）
        Map<String, Object> resultFormat = new HashMap<>();
        resultFormat.put("format", state.isRoomMatch() ? "Room" : "Rank");
        resultFormat.put("winsRequired", state.getWinsToVictory());
        resultFormat.put("maxRounds", state.getMaxRounds());
        resultFormat.put("isRoomMatch", state.isRoomMatch());
        if (state.isRoomMatch() && state.getRoomId() != null) {
            resultFormat.put("roomId", state.getRoomId());
        }

        LocalDateTime endedAt = LocalDateTime.now();

        for (Result result : results) {
            Long playerId = result.getPlayer().getId();
            boolean isWinner = playerId.equals(winnerId);

            result.setResult(isDraw ? false : isWinner);
            result.setUpdownRate(isWinner ? winnerRateChange : loserRateChange);
            result.setRateAfterMatch(isWinner ? winnerNewRate : loserNewRate);
            result.setUseQuestion(useQuestion);
            result.setOutcomeReason(outcomeReason);
            result.setEndedAt(endedAt);

            // resultDetailにプレイヤー視点の詳細を追加
            Map<String, Object> resultDetail = new HashMap<>();
            resultDetail.put("rounds", roundDetailData);
            resultDetail.put("myWins", playerId.equals(state.getPlayer1Id()) ?
                    state.getPlayer1Wins() : state.getPlayer2Wins());
            resultDetail.put("opponentWins", playerId.equals(state.getPlayer1Id()) ?
                    state.getPlayer2Wins() : state.getPlayer1Wins());
            resultDetail.put("isDraw", isDraw);
            result.setResultDetail(resultDetail);

            result.setResultFormat(resultFormat);

            resultRepository.save(result);
        }

        logger.info("Result更新完了: matchUuid={}", matchUuid);
    }

    /**
     * 既存の結果からBattleResultDtoを再構築（冪等性対応）
     */
    private BattleResultDto reconstructBattleResult(String matchUuid, List<Result> results,
                                                    BattleStateService.BattleState state) {
        // 勝者のResultを見つける
        Result winnerResult = results.stream()
                .filter(r -> r.getResult())
                .findFirst()
                .orElse(results.get(0));

        Result loserResult = results.stream()
                .filter(r -> !r.getResult())
                .findFirst()
                .orElse(results.get(1));

        boolean isDraw = results.stream().noneMatch(Result::getResult);

        @SuppressWarnings("unchecked")
        Map<String, Object> winnerDetail = winnerResult.getResultDetail();
        int winnerScore = winnerDetail != null ? ((Number) winnerDetail.getOrDefault("myWins", 0)).intValue() : 0;
        int loserScore = winnerDetail != null ? ((Number) winnerDetail.getOrDefault("opponentWins", 0)).intValue() : 0;

        // レート情報を取得
        User winnerUser = winnerResult.getPlayer();
        User loserUser = loserResult.getPlayer();
        Integer currentSeason = seasonCalculator.getCurrentSeason();

        Rate winnerRate = rateRepository.findByUserAndSeason(winnerUser, currentSeason)
                .orElseGet(() -> new Rate(winnerUser, currentSeason));
        Rate loserRate = rateRepository.findByUserAndSeason(loserUser, currentSeason)
                .orElseGet(() -> new Rate(loserUser, currentSeason));

        return new BattleResultDto(
                matchUuid,
                winnerResult.getPlayer().getId(),
                loserResult.getPlayer().getId(),
                isDraw,
                winnerScore,
                loserScore,
                winnerResult.getUpdownRate(),
                loserResult.getUpdownRate(),
                winnerRate.getRate(),
                loserRate.getRate(),
                Collections.emptyList(), // 詳細はresultDetailに保存済み
                winnerResult.getOutcomeReason()
        );
    }

    /**
     * 対戦状態を取得
     */
    public BattleStateService.BattleState getBattleState(String matchUuid) {
        return battleStateService.getBattle(matchUuid);
    }

    /**
     * 指定ユーザーがランクマッチの対戦中かどうか
     */
    public boolean isUserInRankBattle(Long userId) {
       

        return battleStateService.isUserInRankBattle(userId);
    }

    /**
     * ラウンドタイムアウトチェック
     */
    public boolean isRoundTimedOut(String matchUuid) {
        return battleStateService.isRoundTimedOut(matchUuid);
    }

    /**
     * プレイヤーを次ラウンドへ進む準備ができた状態にマーク
     * @return 両者が準備完了またはタイムアウトで次ラウンドへ進むべき場合true
     */
    public boolean markPlayerReadyForNextRound(String matchUuid, Long userId) {
        return battleStateService.markPlayerReadyForNextRound(matchUuid, userId);
    }

    /**
     * ラウンド結果のタイムアウトをチェック（10秒経過しているか）
     */
    public boolean isRoundResultTimedOut(String matchUuid) {
        return battleStateService.isRoundResultTimedOut(matchUuid);
    }

    /**
     * ラウンド結果待ちでタイムアウトした対戦のmatchUuidリストを取得
     */
    public java.util.List<String> getTimedOutRoundResultMatches() {
        return battleStateService.getTimedOutRoundResultMatches();
    }

    /**
     * 回答フェーズでタイムアウトした対戦のmatchUuidリストを取得
     */
    public java.util.List<String> getTimedOutAnswerPhaseMatches() {
        return battleStateService.getTimedOutAnswerPhaseMatches();
    }

    /**
     * 降参処理
     */
    @Transactional
    public BattleResultDto surrender(String matchUuid, Long surrenderUserId) {
        BattleStateService.BattleState state = battleStateService.getBattle(matchUuid);

        // 状態が見つからない場合（既に終了処理済み）、DBから結果を取得して返す
        if (state == null) {
            List<Result> existingResults = resultRepository.findAllByMatchUuid(matchUuid);
            if (!existingResults.isEmpty()) {
                logger.info("降参処理: 対戦は既に終了済み matchUuid={}", matchUuid);
                return reconstructBattleResult(matchUuid, existingResults, null);
            }
            throw new IllegalArgumentException("対戦が見つかりません: " + matchUuid);
        }

        // 既にFINISHED状態の場合も同様に処理
        if (state.getStatus() == BattleStateService.Status.FINISHED) {
            List<Result> existingResults = resultRepository.findAllByMatchUuid(matchUuid);
            if (!existingResults.isEmpty()) {
                logger.info("降参処理: 対戦は既にFINISHED状態 matchUuid={}", matchUuid);
                return reconstructBattleResult(matchUuid, existingResults, state);
            }
        }

        if (!state.isParticipant(surrenderUserId)) {
            throw new IllegalArgumentException("参加者ではありません: " + surrenderUserId);
        }

        // 降参したユーザーの負けとして処理
        // 相手に3勝を与える
        Long winnerId = state.isPlayer1(surrenderUserId) ? state.getPlayer2Id() : state.getPlayer1Id();

        // 強制的に勝敗を確定
        while (!state.isMatchDecided()) {
            if (state.isPlayer1(winnerId)) {
                state.incrementPlayer1Wins();
            } else {
                state.incrementPlayer2Wins();
            }
        }

        return finalizeBattle(matchUuid, Result.OutcomeReason.surrender);
    }

    /**
     * 切断処理
     */
    @Transactional
    public BattleResultDto handleDisconnect(String matchUuid, Long disconnectedUserId) {
        return handleDisconnection(matchUuid, disconnectedUserId, null);
    }

    /**
     * マッチング時の言語コードをDB用の言語コードに変換
     * @param matchingLanguage マッチング時の言語コード（"english", "korean" 等）
     * @return DB用の言語コード（"en", "ko" 等）
     */
    private String convertToDbLanguageCode(String matchingLanguage) {
        if (matchingLanguage == null) {
            return "en"; // デフォルト
        }
        switch (matchingLanguage.toLowerCase()) {
            case "english":
                return "en";
            case "korean":
                return "ko";
            default:
                // 既に短縮形の場合はそのまま返す
                return matchingLanguage;
        }
    }

    /**
     * 両プレイヤーの単語帳登録（対戦終了時）
     * 学習と同じルール：
     * - FILL_IN_THE_BLANK: 全ての問題のanswerを登録
     * - LISTENING: 不正解の場合のみ、userAnswerとcorrectAnswerを使って登録
     *
     * @param state 対戦状態
     */
    private void registerVocabularyForBothPlayers(BattleStateService.BattleState state) {
        try {
            Long player1Id = state.getPlayer1Id();
            Long player2Id = state.getPlayer2Id();
            List<Question> questions = state.getQuestions();
            List<BattleStateService.RoundResult> roundResults = state.getRoundResults();

            // questionIdでQuestionをマップ化
            Map<Integer, Question> questionMap = questions.stream()
                    .collect(Collectors.toMap(Question::getQuestionId, q -> q));

            int player1Registered = 0;
            int player2Registered = 0;

            for (BattleStateService.RoundResult rr : roundResults) {
                Question question = questionMap.get(rr.getQuestionId());
                if (question == null) continue;

                QuestionFormat format = question.getQuestionFormat();
                String correctAnswer = BattleStateService.getCorrectAnswer(question);

                // Player1の登録処理
                BattleStateService.PlayerAnswer p1Answer = rr.getPlayer1Answer();
                if (p1Answer != null) {
                    if (registerVocabularyForPlayer(player1Id, question, format, p1Answer, correctAnswer)) {
                        player1Registered++;
                    }
                }

                // Player2の登録処理
                BattleStateService.PlayerAnswer p2Answer = rr.getPlayer2Answer();
                if (p2Answer != null) {
                    if (registerVocabularyForPlayer(player2Id, question, format, p2Answer, correctAnswer)) {
                        player2Registered++;
                    }
                }
            }

            logger.info("対戦終了時の単語帳登録完了: matchUuid={}, player1登録数={}, player2登録数={}",
                    state.getMatchUuid(), player1Registered, player2Registered);

        } catch (Exception e) {
            // 単語帳登録に失敗しても対戦終了処理は続行
            logger.warn("対戦終了時の単語帳登録でエラーが発生しましたが、処理を続行します: {}", e.getMessage());
        }
    }

    /**
     * 個別プレイヤーの単語帳登録（学習と同じロジック・非同期で実行）
     *
     * @return 登録が行われた場合true
     */
    private boolean registerVocabularyForPlayer(Long userId, Question question,
                                                 QuestionFormat format,
                                                 BattleStateService.PlayerAnswer playerAnswer,
                                                 String correctAnswer) {
        try {
            if (QuestionFormat.FILL_IN_THE_BLANK.equals(format)) {
                // FILL_IN_THE_BLANK: 全ての問題のanswerを登録（非同期）
                userVocabularyService.registerFillInBlankAnswerAsync(userId, question.getAnswer());
                return true;
            } else if (QuestionFormat.LISTENING.equals(format) && !playerAnswer.isCorrect()) {
                // LISTENING: 不正解の場合、間違えた単語を登録（非同期）
                // 空回答でも正解の単語を登録（学習モードと同じ挙動）
                String userAnswer = playerAnswer.getAnswer();
                userVocabularyService.registerListeningMistakesAsync(
                    userId,
                    userAnswer != null ? userAnswer : "",
                    correctAnswer
                );
                return true;
            }
        } catch (Exception e) {
            logger.debug("単語帳登録スキップ: userId={}, error={}", userId, e.getMessage());
        }
        return false;
    }

    /**
     * 切断による対戦終了処理（切断者を敗北として処理）
     *
     * @param matchUuid マッチUUID
     * @param disconnectedUserId 切断したユーザーID
     * @param winnerId 勝利者のユーザーID
     */
    @Transactional
    public BattleResultDto handleDisconnection(String matchUuid, Long disconnectedUserId, Long winnerId) {
        logger.info("切断による対戦終了処理: matchUuid={}, disconnectedUserId={}, winnerId={}",
                matchUuid, disconnectedUserId, winnerId);

        BattleStateService.BattleState state = battleStateService.getBattle(matchUuid);
        if (state == null) {
            logger.warn("対戦状態が見つかりません: matchUuid={}", matchUuid);
            return null;
        }

        if (winnerId == null && disconnectedUserId != null) {
            winnerId = state.isPlayer1(disconnectedUserId) ? state.getPlayer2Id() : state.getPlayer1Id();
        }

        if (winnerId == null || disconnectedUserId == null) {
            logger.warn("切断処理に必要な情報が不足しています: matchUuid={}", matchUuid);
            return null;
        }

        if (!state.isParticipant(winnerId) || !state.isParticipant(disconnectedUserId)) {
            logger.warn("切断処理対象が対戦参加者ではありません: matchUuid={}, winnerId={}, disconnectedUserId={}",
                    matchUuid, winnerId, disconnectedUserId);
            return null;
        }

        if (winnerId.equals(disconnectedUserId)) {
            logger.warn("勝者と切断者が同一です: matchUuid={}, userId={}", matchUuid, winnerId);
            return null;
        }

        while (!state.isMatchDecided()) {
            if (state.isPlayer1(winnerId)) {
                state.incrementPlayer1Wins();
            } else {
                state.incrementPlayer2Wins();
            }
        }

        return finalizeBattle(matchUuid, Result.OutcomeReason.disconnect);
    }
    private String buildFallbackAnswer(Result.OutcomeReason reason, Long playerId, Long loserId) {
    boolean isLoser = playerId != null && playerId.equals(loserId);
    if (reason == Result.OutcomeReason.surrender) {
        return isLoser
            ? "あなたが降参したため回答を表示できません"
            : "相手が降参したため回答を表示できません";
    }
    if (reason == Result.OutcomeReason.disconnect) {
        return isLoser
            ? "あなたが切断したため回答を表示できません"
            : "相手が切断したため回答を表示できません";
    }
    return "回答を表示できません";
}

}
