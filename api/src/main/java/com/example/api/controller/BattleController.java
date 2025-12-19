package com.example.api.controller;

import com.example.api.dto.battle.*;
import com.example.api.entity.Question;
import com.example.api.entity.Result;
import com.example.api.repository.ResultRepository;
import com.example.api.service.BattleService;
import com.example.api.service.BattleStateService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * バトルコントローラー
 * バトル開始、進行、終了の処理を提供します（REST + WebSocket）
 */
@RestController
@RequestMapping("/api/battle")
public class BattleController {

    private static final Logger logger = LoggerFactory.getLogger(BattleController.class);

    @Autowired
    private ResultRepository resultRepository;

    @Autowired
    private BattleService battleService;

    @Autowired
    private SimpMessagingTemplate messagingTemplate;

    // ==================== REST API ====================

    /**
     * バトル開始エンドポイント
     * マッチング成立後、このエンドポイントでバトル情報を取得します
     *
     * @param matchId マッチID
     * @return バトル情報
     */
    @GetMapping("/start/{matchId}")
    public ResponseEntity<?> startBattle(@PathVariable String matchId) {
        try {
            // マッチIDに対応するResultレコードを取得（2件）
            List<Result> results = resultRepository.findAllByMatchUuid(matchId);

            if (results.isEmpty()) {
                return ResponseEntity.badRequest()
                        .body(createErrorResponse("マッチ情報が見つかりません"));
            }

            if (results.size() != 2) {
                return ResponseEntity.badRequest()
                        .body(createErrorResponse("マッチ情報が不正です"));
            }

            Result result1 = results.get(0);

            // 対戦を初期化（問題取得・状態作成）
            BattleStateService.BattleState state = battleService.initializeBattle(
                    matchId,
                    result1.getPlayer().getId(),
                    result1.getEnemy().getId(),
                    result1.getUseLanguage()
            );

            // バトル情報を返す
            Map<String, Object> battleInfo = new HashMap<>();
            battleInfo.put("matchId", matchId);
            battleInfo.put("user1Id", state.getPlayer1Id());
            battleInfo.put("user2Id", state.getPlayer2Id());
            battleInfo.put("language", state.getLanguage());
            battleInfo.put("questionCount", state.getQuestions().size());
            battleInfo.put("roundTimeLimitSeconds", BattleStateService.ROUND_TIME_LIMIT_SECONDS);
            battleInfo.put("winsRequired", BattleStateService.WINS_TO_VICTORY);
            battleInfo.put("maxRounds", BattleStateService.MAX_ROUNDS);
            battleInfo.put("status", "ready");
            battleInfo.put("message", "バトルを開始できます");

            return ResponseEntity.ok(battleInfo);

        } catch (Exception e) {
            logger.error("バトル開始エラー: matchId={}", matchId, e);
            return ResponseEntity.status(500)
                    .body(createErrorResponse("バトル開始処理中にエラーが発生しました: " + e.getMessage()));
        }
    }

    /**
     * マッチ情報取得エンドポイント
     * 既存のマッチ情報を取得します
     *
     * @param matchId マッチID
     * @return マッチ情報
     */
    @GetMapping("/info/{matchId}")
    public ResponseEntity<?> getMatchInfo(@PathVariable String matchId) {
        try {
            List<Result> results = resultRepository.findAllByMatchUuid(matchId);

            if (results.isEmpty()) {
                return ResponseEntity.badRequest()
                        .body(createErrorResponse("マッチ情報が見つかりません"));
            }

            Result result = results.get(0);

            // 対戦状態も取得
            BattleStateService.BattleState state = battleService.getBattleState(matchId);

            Map<String, Object> matchInfo = new HashMap<>();
            matchInfo.put("matchId", matchId);
            matchInfo.put("user1Id", result.getPlayer().getId());
            matchInfo.put("user2Id", result.getEnemy().getId());
            matchInfo.put("language", result.getUseLanguage());
            matchInfo.put("matchType", result.getMatchType());

            if (state != null) {
                matchInfo.put("status", state.getStatus().name());
                matchInfo.put("currentRound", state.getCurrentRound() + 1);
                matchInfo.put("player1Wins", state.getPlayer1Wins());
                matchInfo.put("player2Wins", state.getPlayer2Wins());
            }

            return ResponseEntity.ok(matchInfo);

        } catch (Exception e) {
            return ResponseEntity.status(500)
                    .body(createErrorResponse("マッチ情報取得中にエラーが発生しました: " + e.getMessage()));
        }
    }

    /**
     * 対戦状態取得エンドポイント
     */
    @GetMapping("/state/{matchId}")
    public ResponseEntity<?> getBattleState(@PathVariable String matchId) {
        try {
            BattleStateService.BattleState state = battleService.getBattleState(matchId);

            if (state == null) {
                return ResponseEntity.badRequest()
                        .body(createErrorResponse("対戦状態が見つかりません"));
            }

            Map<String, Object> stateInfo = new HashMap<>();
            stateInfo.put("matchId", matchId);
            stateInfo.put("status", state.getStatus().name());
            stateInfo.put("currentRound", state.getCurrentRound() + 1);
            stateInfo.put("player1Id", state.getPlayer1Id());
            stateInfo.put("player2Id", state.getPlayer2Id());
            stateInfo.put("player1Wins", state.getPlayer1Wins());
            stateInfo.put("player2Wins", state.getPlayer2Wins());

            return ResponseEntity.ok(stateInfo);

        } catch (Exception e) {
            return ResponseEntity.status(500)
                    .body(createErrorResponse("対戦状態取得中にエラーが発生しました: " + e.getMessage()));
        }
    }

    // ==================== WebSocket Handlers ====================

    /**
     * バトル準備完了
     * クライアントから /app/battle/ready にメッセージを送信
     */
    @MessageMapping("/battle/ready")
    public void battleReady(@Payload BattleReadyRequest request) {
        try {
            logger.info("バトル準備完了: matchId={}, userId={}", request.getMatchId(), request.getUserId());

            BattleStateService.BattleState state = battleService.getBattleState(request.getMatchId());
            if (state == null) {
                sendError(request.getUserId(), "対戦が見つかりません");
                return;
            }

            // 対戦開始（まだ開始していない場合）
            if (state.getStatus() == BattleStateService.Status.WAITING_FOR_PLAYERS) {
                state = battleService.startBattle(request.getMatchId());
            }

            // 最初の問題を両プレイヤーに送信
            sendQuestionToPlayers(state);

        } catch (Exception e) {
            logger.error("バトル準備完了エラー: matchId={}", request.getMatchId(), e);
            sendError(request.getUserId(), "エラーが発生しました: " + e.getMessage());
        }
    }

    /**
     * 回答送信
     * クライアントから /app/battle/answer にメッセージを送信
     */
    @MessageMapping("/battle/answer")
    public void submitAnswer(@Payload AnswerRequest request) {
        try {
            logger.info("回答受信: matchId={}, userId={}, answer={}",
                    request.getMatchId(), request.getUserId(), request.getAnswer());

            BattleStateService.BattleState state = battleService.getBattleState(request.getMatchId());
            if (state == null) {
                sendError(request.getUserId(), "対戦が見つかりません");
                return;
            }

            if (state.getStatus() != BattleStateService.Status.IN_PROGRESS) {
                sendError(request.getUserId(), "対戦は進行中ではありません");
                return;
            }

            // 回答を記録
            boolean bothAnswered = battleService.submitAnswer(
                    request.getMatchId(),
                    request.getUserId(),
                    request.getAnswer()
            );

            // 回答受付確認を送信
            Map<String, Object> ackResponse = new HashMap<>();
            ackResponse.put("type", "answer_received");
            ackResponse.put("matchId", request.getMatchId());
            messagingTemplate.convertAndSend("/topic/battle/" + request.getUserId(), ackResponse);

            // 両者の回答が揃ったらラウンド確定
            if (bothAnswered) {
                processRoundEnd(request.getMatchId());
            }

        } catch (Exception e) {
            logger.error("回答処理エラー: matchId={}, userId={}", request.getMatchId(), request.getUserId(), e);
            sendError(request.getUserId(), "エラーが発生しました: " + e.getMessage());
        }
    }

    /**
     * 降参
     * クライアントから /app/battle/surrender にメッセージを送信
     */
    @MessageMapping("/battle/surrender")
    public void surrender(@Payload SurrenderRequest request) {
        try {
            logger.info("降参: matchId={}, userId={}", request.getMatchId(), request.getUserId());

            BattleService.BattleResultDto result = battleService.surrender(
                    request.getMatchId(),
                    request.getUserId()
            );

            // 結果を両プレイヤーに送信
            sendBattleResult(result);

        } catch (Exception e) {
            logger.error("降参処理エラー: matchId={}", request.getMatchId(), e);
            sendError(request.getUserId(), "エラーが発生しました: " + e.getMessage());
        }
    }

    /**
     * タイムアウト通知（クライアントから呼び出し可能）
     * クライアントから /app/battle/timeout にメッセージを送信
     */
    @MessageMapping("/battle/timeout")
    public void handleTimeout(@Payload BattleReadyRequest request) {
        try {
            logger.info("タイムアウト通知: matchId={}", request.getMatchId());

            BattleStateService.BattleState state = battleService.getBattleState(request.getMatchId());
            if (state == null || state.getStatus() != BattleStateService.Status.IN_PROGRESS) {
                return;
            }

            // タイムアウトチェック
            if (battleService.isRoundTimedOut(request.getMatchId())) {
                processRoundEnd(request.getMatchId());
            }

        } catch (Exception e) {
            logger.error("タイムアウト処理エラー: matchId={}", request.getMatchId(), e);
        }
    }

    // ==================== Scheduled Tasks ====================

    /**
     * 定期的にラウンドタイムアウトをチェック（5秒ごと）
     * 注: 本番環境では、対戦ごとにScheduledFutureを使用して個別にタイムアウト管理することを推奨
     */
    @Scheduled(fixedRate = 5000)
    public void checkRoundTimeouts() {
        // 現状の実装では、クライアントからのtimeoutメッセージで処理
        // 将来的にはサーバー側で能動的にチェックする実装を追加可能
    }

    // ==================== Private Methods ====================

    /**
     * ラウンド終了処理
     */
    private synchronized void processRoundEnd(String matchId) {
        BattleStateService.BattleState state = battleService.getBattleState(matchId);
        if (state == null) return;

        // 既に終了している場合はスキップ
        if (state.getStatus() != BattleStateService.Status.IN_PROGRESS) {
            return;
        }

        // ラウンド確定前の問題を保存（正解表示用）
        // 問題タイプに応じた正解を取得（LISTENING→complete_sentence、FILL_IN_BLANK→answer）
        Question currentQuestion = state.getCurrentQuestion();
        String correctAnswer = BattleStateService.getCorrectAnswer(currentQuestion);

        // ラウンド確定
        BattleStateService.RoundResult roundResult = battleService.processRound(matchId);

        // ラウンド結果を両プレイヤーに送信
        RoundResultResponse response = createRoundResultResponse(roundResult, state, correctAnswer);

        Map<String, Object> roundResultMessage = new HashMap<>();
        roundResultMessage.put("type", "round_result");
        roundResultMessage.put("result", response);

        messagingTemplate.convertAndSend("/topic/battle/" + state.getPlayer1Id(), roundResultMessage);
        messagingTemplate.convertAndSend("/topic/battle/" + state.getPlayer2Id(), roundResultMessage);

        // 更新後の状態を取得
        state = battleService.getBattleState(matchId);

        // 試合終了かチェック
        if (state == null || state.getStatus() == BattleStateService.Status.FINISHED) {
            // 試合終了処理
            BattleService.BattleResultDto battleResult =
                    battleService.finalizeBattle(matchId, Result.OutcomeReason.normal);
            sendBattleResult(battleResult);
        }
        // 試合継続の場合は、クライアントからのnext_roundリクエストを待つ
        // ラウンド結果がスキップされないよう、ここで自動的に次の問題を送信しない
    }

    /**
     * 次のラウンドへ進む（クライアントからのリクエスト）
     * クライアントがラウンド結果を確認後に /app/battle/next-round を送信
     */
    @MessageMapping("/battle/next-round")
    public void nextRound(@Payload BattleReadyRequest request) {
        try {
            logger.info("次ラウンドリクエスト: matchId={}, userId={}", request.getMatchId(), request.getUserId());

            BattleStateService.BattleState state = battleService.getBattleState(request.getMatchId());
            if (state == null) {
                sendError(request.getUserId(), "対戦が見つかりません");
                return;
            }

            if (state.getStatus() != BattleStateService.Status.IN_PROGRESS) {
                sendError(request.getUserId(), "対戦は進行中ではありません");
                return;
            }

            // 次の問題を両プレイヤーに送信
            sendQuestionToPlayers(state);

        } catch (Exception e) {
            logger.error("次ラウンド処理エラー: matchId={}", request.getMatchId(), e);
            sendError(request.getUserId(), "エラーが発生しました: " + e.getMessage());
        }
    }

    /**
     * 問題を両プレイヤーに送信
     */
    private void sendQuestionToPlayers(BattleStateService.BattleState state) {
        Question question = state.getCurrentQuestion();
        if (question == null) {
            logger.warn("問題がありません: matchId={}", state.getMatchUuid());
            return;
        }

        QuestionResponse response = new QuestionResponse(
                question.getQuestionId(),
                question.getText(),
                question.getQuestionFormat().name(),
                question.getAudioUrl(),
                question.getTranslationJa(),
                state.getCurrentRound() + 1,
                state.getQuestions().size(),
                BattleStateService.ROUND_TIME_LIMIT_SECONDS * 1000L
        );

        Map<String, Object> questionMessage = new HashMap<>();
        questionMessage.put("type", "question");
        questionMessage.put("matchId", state.getMatchUuid());
        questionMessage.put("question", response);
        questionMessage.put("player1Id", state.getPlayer1Id());
        questionMessage.put("player2Id", state.getPlayer2Id());
        questionMessage.put("player1Wins", state.getPlayer1Wins());
        questionMessage.put("player2Wins", state.getPlayer2Wins());

        messagingTemplate.convertAndSend("/topic/battle/" + state.getPlayer1Id(), questionMessage);
        messagingTemplate.convertAndSend("/topic/battle/" + state.getPlayer2Id(), questionMessage);

        logger.info("問題送信: matchId={}, round={}, questionId={}",
                state.getMatchUuid(), state.getCurrentRound() + 1, question.getQuestionId());
    }

    /**
     * ラウンド結果レスポンスを作成
     */
    private RoundResultResponse createRoundResultResponse(BattleStateService.RoundResult roundResult,
                                                          BattleStateService.BattleState state,
                                                          String correctAnswer) {
        RoundResultResponse response = new RoundResultResponse();
        response.setRoundNumber(roundResult.getRoundNumber());
        response.setQuestionId(roundResult.getQuestionId());
        response.setCorrectAnswer(correctAnswer);
        response.setRoundWinnerId(roundResult.getWinnerId());
        response.setNoCount(roundResult.isNoCount());
        response.setNoCountReason(roundResult.getNoCountReason());

        // Player1の情報
        response.setPlayer1Id(state.getPlayer1Id());
        if (roundResult.getPlayer1Answer() != null) {
            response.setPlayer1Answer(roundResult.getPlayer1Answer().getAnswer());
            response.setPlayer1Correct(roundResult.getPlayer1Answer().isCorrect());
            response.setPlayer1ResponseTimeMs(roundResult.getPlayer1Answer().getResponseTimeMs());
        }

        // Player2の情報
        response.setPlayer2Id(state.getPlayer2Id());
        if (roundResult.getPlayer2Answer() != null) {
            response.setPlayer2Answer(roundResult.getPlayer2Answer().getAnswer());
            response.setPlayer2Correct(roundResult.getPlayer2Answer().isCorrect());
            response.setPlayer2ResponseTimeMs(roundResult.getPlayer2Answer().getResponseTimeMs());
        }

        // 現在のスコア
        response.setPlayer1Wins(state.getPlayer1Wins());
        response.setPlayer2Wins(state.getPlayer2Wins());

        // 試合継続フラグ
        response.setMatchContinues(state.getStatus() == BattleStateService.Status.IN_PROGRESS);

        return response;
    }

    /**
     * 試合結果を両プレイヤーに送信
     */
    private void sendBattleResult(BattleService.BattleResultDto result) {
        Map<String, Object> winnerView = result.toPlayerView(result.getWinnerId());
        winnerView.put("type", "battle_result");

        Map<String, Object> loserView = result.toPlayerView(result.getLoserId());
        loserView.put("type", "battle_result");

        messagingTemplate.convertAndSend("/topic/battle/" + result.getWinnerId(), winnerView);
        messagingTemplate.convertAndSend("/topic/battle/" + result.getLoserId(), loserView);

        logger.info("試合結果送信: matchId={}, winnerId={}, loserId={}",
                result.getMatchUuid(), result.getWinnerId(), result.getLoserId());
    }

    /**
     * エラーメッセージを送信
     */
    private void sendError(Long userId, String message) {
        Map<String, Object> error = new HashMap<>();
        error.put("type", "error");
        error.put("message", message);
        messagingTemplate.convertAndSend("/topic/battle/" + userId, error);
    }

    /**
     * エラーレスポンスを作成
     */
    private Map<String, String> createErrorResponse(String message) {
        Map<String, String> error = new HashMap<>();
        error.put("error", message);
        return error;
    }
}
