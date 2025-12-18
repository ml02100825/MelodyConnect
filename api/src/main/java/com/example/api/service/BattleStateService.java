package com.example.api.service;

import com.example.api.entity.Question;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;

/**
 * 対戦状態管理サービス
 * メモリ内で対戦の進行状態を管理します
 */
@Service
public class BattleStateService {

    private static final Logger logger = LoggerFactory.getLogger(BattleStateService.class);

    /** 1ラウンドの制限時間（秒） */
    public static final int ROUND_TIME_LIMIT_SECONDS = 90;

    /** 勝利に必要な勝ち数 */
    public static final int WINS_TO_VICTORY = 3;

    /** 最大ラウンド数 */
    public static final int MAX_ROUNDS = 10;

    /** 対戦状態を保持するMap（matchUuid -> BattleState） */
    private final Map<String, BattleState> activeBattles = new ConcurrentHashMap<>();

    /**
     * 対戦状態のEnum
     */
    public enum Status {
        WAITING_FOR_PLAYERS,  // プレイヤー待機中
        IN_PROGRESS,          // 対戦中
        FINISHED              // 終了
    }

    /**
     * プレイヤーの回答情報
     */
    public static class PlayerAnswer {
        private final Long userId;
        private final String answer;
        private final Instant answeredAt;
        private final boolean isCorrect;
        private final long responseTimeMs;

        public PlayerAnswer(Long userId, String answer, Instant answeredAt, boolean isCorrect, long responseTimeMs) {
            this.userId = userId;
            this.answer = answer;
            this.answeredAt = answeredAt;
            this.isCorrect = isCorrect;
            this.responseTimeMs = responseTimeMs;
        }

        public Long getUserId() { return userId; }
        public String getAnswer() { return answer; }
        public Instant getAnsweredAt() { return answeredAt; }
        public boolean isCorrect() { return isCorrect; }
        public long getResponseTimeMs() { return responseTimeMs; }
    }

    /**
     * ラウンド結果
     */
    public static class RoundResult {
        private final int roundNumber;
        private final Integer questionId;
        private final PlayerAnswer player1Answer;
        private final PlayerAnswer player2Answer;
        private final Long winnerId;        // null = ノーカウント
        private final String noCountReason; // ノーカウントの理由（両者不正解、両者タイムアウト等）

        public RoundResult(int roundNumber, Integer questionId,
                          PlayerAnswer player1Answer, PlayerAnswer player2Answer,
                          Long winnerId, String noCountReason) {
            this.roundNumber = roundNumber;
            this.questionId = questionId;
            this.player1Answer = player1Answer;
            this.player2Answer = player2Answer;
            this.winnerId = winnerId;
            this.noCountReason = noCountReason;
        }

        public int getRoundNumber() { return roundNumber; }
        public Integer getQuestionId() { return questionId; }
        public PlayerAnswer getPlayer1Answer() { return player1Answer; }
        public PlayerAnswer getPlayer2Answer() { return player2Answer; }
        public Long getWinnerId() { return winnerId; }
        public String getNoCountReason() { return noCountReason; }
        public boolean isNoCount() { return winnerId == null; }
    }

    /**
     * 対戦状態クラス
     */
    public static class BattleState {
        private final String matchUuid;
        private final Long player1Id;
        private final Long player2Id;
        private final String language;
        private final List<Question> questions;
        private final List<RoundResult> roundResults;

        private Status status;
        private int currentRound;           // 0-indexed
        private int player1Wins;
        private int player2Wins;
        private Instant roundStartTime;

        // 現在のラウンドの回答（暫定）
        private PlayerAnswer currentPlayer1Answer;
        private PlayerAnswer currentPlayer2Answer;

        public BattleState(String matchUuid, Long player1Id, Long player2Id,
                          String language, List<Question> questions) {
            this.matchUuid = matchUuid;
            this.player1Id = player1Id;
            this.player2Id = player2Id;
            this.language = language;
            this.questions = new ArrayList<>(questions);
            this.roundResults = new ArrayList<>();
            this.status = Status.WAITING_FOR_PLAYERS;
            this.currentRound = 0;
            this.player1Wins = 0;
            this.player2Wins = 0;
        }

        // Getters
        public String getMatchUuid() { return matchUuid; }
        public Long getPlayer1Id() { return player1Id; }
        public Long getPlayer2Id() { return player2Id; }
        public String getLanguage() { return language; }
        public List<Question> getQuestions() { return Collections.unmodifiableList(questions); }
        public List<RoundResult> getRoundResults() { return Collections.unmodifiableList(roundResults); }
        public Status getStatus() { return status; }
        public int getCurrentRound() { return currentRound; }
        public int getPlayer1Wins() { return player1Wins; }
        public int getPlayer2Wins() { return player2Wins; }
        public Instant getRoundStartTime() { return roundStartTime; }
        public PlayerAnswer getCurrentPlayer1Answer() { return currentPlayer1Answer; }
        public PlayerAnswer getCurrentPlayer2Answer() { return currentPlayer2Answer; }

        // Setters（パッケージプライベート）
        void setStatus(Status status) { this.status = status; }
        void setCurrentRound(int currentRound) { this.currentRound = currentRound; }
        void setRoundStartTime(Instant roundStartTime) { this.roundStartTime = roundStartTime; }
        void setCurrentPlayer1Answer(PlayerAnswer answer) { this.currentPlayer1Answer = answer; }
        void setCurrentPlayer2Answer(PlayerAnswer answer) { this.currentPlayer2Answer = answer; }
        void incrementPlayer1Wins() { this.player1Wins++; }
        void incrementPlayer2Wins() { this.player2Wins++; }
        void addRoundResult(RoundResult result) { this.roundResults.add(result); }
        void clearCurrentAnswers() {
            this.currentPlayer1Answer = null;
            this.currentPlayer2Answer = null;
        }

        /**
         * 現在の問題を取得
         */
        public Question getCurrentQuestion() {
            if (currentRound < questions.size()) {
                return questions.get(currentRound);
            }
            return null;
        }

        /**
         * 指定ユーザーがplayer1かどうか
         */
        public boolean isPlayer1(Long userId) {
            return player1Id.equals(userId);
        }

        /**
         * 指定ユーザーがこの対戦の参加者かどうか
         */
        public boolean isParticipant(Long userId) {
            return player1Id.equals(userId) || player2Id.equals(userId);
        }

        /**
         * 勝者が確定したかどうか（3勝または10ラウンド終了）
         */
        public boolean isMatchDecided() {
            return player1Wins >= WINS_TO_VICTORY ||
                   player2Wins >= WINS_TO_VICTORY ||
                   currentRound >= MAX_ROUNDS;
        }

        /**
         * 勝者のユーザーIDを取得（未確定ならnull）
         */
        public Long getWinnerId() {
            if (player1Wins >= WINS_TO_VICTORY) return player1Id;
            if (player2Wins >= WINS_TO_VICTORY) return player2Id;
            if (currentRound >= MAX_ROUNDS) {
                // 10ラウンド終了時は勝ち数で判定
                if (player1Wins > player2Wins) return player1Id;
                if (player2Wins > player1Wins) return player2Id;
                return null; // 引き分け（同点）
            }
            return null;
        }
    }

    /**
     * 新しい対戦状態を作成
     */
    public BattleState createBattle(String matchUuid, Long player1Id, Long player2Id,
                                    String language, List<Question> questions) {
        if (activeBattles.containsKey(matchUuid)) {
            logger.warn("対戦状態が既に存在: matchUuid={}", matchUuid);
            return activeBattles.get(matchUuid);
        }

        BattleState state = new BattleState(matchUuid, player1Id, player2Id, language, questions);
        activeBattles.put(matchUuid, state);
        logger.info("対戦状態作成: matchUuid={}, player1={}, player2={}, questions={}",
                matchUuid, player1Id, player2Id, questions.size());
        return state;
    }

    /**
     * 対戦状態を取得
     */
    public BattleState getBattle(String matchUuid) {
        return activeBattles.get(matchUuid);
    }

    /**
     * 対戦を開始（ラウンド1開始）
     */
    public synchronized BattleState startBattle(String matchUuid) {
        BattleState state = activeBattles.get(matchUuid);
        if (state == null) {
            throw new IllegalArgumentException("対戦が見つかりません: " + matchUuid);
        }
        if (state.getStatus() != Status.WAITING_FOR_PLAYERS) {
            logger.warn("対戦は既に開始済み: matchUuid={}, status={}", matchUuid, state.getStatus());
            return state;
        }

        state.setStatus(Status.IN_PROGRESS);
        state.setCurrentRound(0);
        state.setRoundStartTime(Instant.now());
        logger.info("対戦開始: matchUuid={}", matchUuid);
        return state;
    }

    /**
     * 回答を記録
     * @return 両者の回答が揃った場合true
     */
    public synchronized boolean recordAnswer(String matchUuid, Long userId, String answer) {
        BattleState state = activeBattles.get(matchUuid);
        if (state == null) {
            throw new IllegalArgumentException("対戦が見つかりません: " + matchUuid);
        }
        if (state.getStatus() != Status.IN_PROGRESS) {
            throw new IllegalStateException("対戦は進行中ではありません: " + state.getStatus());
        }
        if (!state.isParticipant(userId)) {
            throw new IllegalArgumentException("参加者ではありません: " + userId);
        }

        Question currentQuestion = state.getCurrentQuestion();
        if (currentQuestion == null) {
            throw new IllegalStateException("現在の問題がありません");
        }

        Instant now = Instant.now();
        long responseTimeMs = now.toEpochMilli() - state.getRoundStartTime().toEpochMilli();

        // 制限時間チェック
        if (responseTimeMs > ROUND_TIME_LIMIT_SECONDS * 1000L) {
            logger.warn("制限時間超過: matchUuid={}, userId={}, responseTimeMs={}",
                    matchUuid, userId, responseTimeMs);
            // タイムアウトとして扱う（回答は記録しない）
            return false;
        }

        // 正誤判定（大文字小文字を無視）
        boolean isCorrect = currentQuestion.getAnswer().equalsIgnoreCase(answer.trim());

        PlayerAnswer playerAnswer = new PlayerAnswer(userId, answer, now, isCorrect, responseTimeMs);

        if (state.isPlayer1(userId)) {
            if (state.getCurrentPlayer1Answer() != null) {
                logger.warn("Player1は既に回答済み: matchUuid={}", matchUuid);
                return state.getCurrentPlayer2Answer() != null;
            }
            state.setCurrentPlayer1Answer(playerAnswer);
        } else {
            if (state.getCurrentPlayer2Answer() != null) {
                logger.warn("Player2は既に回答済み: matchUuid={}", matchUuid);
                return state.getCurrentPlayer1Answer() != null;
            }
            state.setCurrentPlayer2Answer(playerAnswer);
        }

        logger.info("回答記録: matchUuid={}, userId={}, isCorrect={}, responseTimeMs={}",
                matchUuid, userId, isCorrect, responseTimeMs);

        // 両者の回答が揃ったかチェック
        return state.getCurrentPlayer1Answer() != null && state.getCurrentPlayer2Answer() != null;
    }

    /**
     * ラウンドを確定（タイムアウトまたは両者回答済み）
     * @return ラウンド結果
     */
    public synchronized RoundResult finalizeRound(String matchUuid) {
        BattleState state = activeBattles.get(matchUuid);
        if (state == null) {
            throw new IllegalArgumentException("対戦が見つかりません: " + matchUuid);
        }

        Question currentQuestion = state.getCurrentQuestion();
        PlayerAnswer p1Answer = state.getCurrentPlayer1Answer();
        PlayerAnswer p2Answer = state.getCurrentPlayer2Answer();

        // タイムアウト処理：未回答の場合はタイムアウトとして扱う
        Instant now = Instant.now();
        long elapsedMs = now.toEpochMilli() - state.getRoundStartTime().toEpochMilli();

        if (p1Answer == null) {
            p1Answer = new PlayerAnswer(state.getPlayer1Id(), null, now, false, elapsedMs);
        }
        if (p2Answer == null) {
            p2Answer = new PlayerAnswer(state.getPlayer2Id(), null, now, false, elapsedMs);
        }

        // 勝者判定
        Long winnerId = null;
        String noCountReason = null;

        boolean p1Correct = p1Answer.isCorrect();
        boolean p2Correct = p2Answer.isCorrect();
        boolean p1Timeout = p1Answer.getAnswer() == null;
        boolean p2Timeout = p2Answer.getAnswer() == null;

        if (p1Timeout && p2Timeout) {
            // 両者タイムアウト → ノーカウント
            noCountReason = "both_timeout";
        } else if (!p1Correct && !p2Correct) {
            // 両者不正解 → ノーカウント
            noCountReason = "both_incorrect";
        } else if (p1Correct && p2Correct) {
            // 両者正解 → 回答時間が短い方の勝ち
            if (p1Answer.getResponseTimeMs() < p2Answer.getResponseTimeMs()) {
                winnerId = state.getPlayer1Id();
            } else if (p2Answer.getResponseTimeMs() < p1Answer.getResponseTimeMs()) {
                winnerId = state.getPlayer2Id();
            } else {
                // 完全同時（極めてまれ）→ ノーカウント
                noCountReason = "same_time";
            }
        } else if (p1Correct) {
            // Player1のみ正解
            winnerId = state.getPlayer1Id();
        } else {
            // Player2のみ正解
            winnerId = state.getPlayer2Id();
        }

        // 勝ち数更新
        if (winnerId != null) {
            if (winnerId.equals(state.getPlayer1Id())) {
                state.incrementPlayer1Wins();
            } else {
                state.incrementPlayer2Wins();
            }
        }

        // ラウンド結果を記録
        RoundResult result = new RoundResult(
                state.getCurrentRound() + 1, // 1-indexed for display
                currentQuestion.getQuestionId(),
                p1Answer,
                p2Answer,
                winnerId,
                noCountReason
        );
        state.addRoundResult(result);
        state.clearCurrentAnswers();

        logger.info("ラウンド確定: matchUuid={}, round={}, winner={}, noCount={}",
                matchUuid, state.getCurrentRound() + 1, winnerId, noCountReason);

        return result;
    }

    /**
     * 次のラウンドへ進む
     * @return 対戦が続行可能な場合true、終了した場合false
     */
    public synchronized boolean advanceToNextRound(String matchUuid) {
        BattleState state = activeBattles.get(matchUuid);
        if (state == null) {
            throw new IllegalArgumentException("対戦が見つかりません: " + matchUuid);
        }

        // 勝者確定チェック
        if (state.isMatchDecided()) {
            state.setStatus(Status.FINISHED);
            logger.info("対戦終了: matchUuid={}, player1Wins={}, player2Wins={}, winner={}",
                    matchUuid, state.getPlayer1Wins(), state.getPlayer2Wins(), state.getWinnerId());
            return false;
        }

        // 次ラウンドへ
        state.setCurrentRound(state.getCurrentRound() + 1);
        state.setRoundStartTime(Instant.now());

        logger.info("次ラウンド開始: matchUuid={}, round={}",
                matchUuid, state.getCurrentRound() + 1);
        return true;
    }

    /**
     * 対戦を終了（強制終了用）
     */
    public synchronized BattleState finishBattle(String matchUuid) {
        BattleState state = activeBattles.get(matchUuid);
        if (state == null) {
            return null;
        }
        state.setStatus(Status.FINISHED);
        return state;
    }

    /**
     * 対戦状態を削除（結果保存後に呼び出す）
     */
    public void removeBattle(String matchUuid) {
        activeBattles.remove(matchUuid);
        logger.info("対戦状態削除: matchUuid={}", matchUuid);
    }

    /**
     * 対戦が存在し、かつ終了済みかどうか
     */
    public boolean isFinished(String matchUuid) {
        BattleState state = activeBattles.get(matchUuid);
        return state != null && state.getStatus() == Status.FINISHED;
    }

    /**
     * アクティブな対戦数を取得
     */
    public int getActiveBattleCount() {
        return activeBattles.size();
    }

    /**
     * ラウンドがタイムアウトしているかチェック
     */
    public boolean isRoundTimedOut(String matchUuid) {
        BattleState state = activeBattles.get(matchUuid);
        if (state == null || state.getRoundStartTime() == null) {
            return false;
        }
        long elapsedMs = Instant.now().toEpochMilli() - state.getRoundStartTime().toEpochMilli();
        return elapsedMs > ROUND_TIME_LIMIT_SECONDS * 1000L;
    }
}
