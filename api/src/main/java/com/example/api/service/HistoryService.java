package com.example.api.service;

import com.example.api.dto.history.*;
import com.example.api.entity.LHistory;
import com.example.api.entity.Question;
import com.example.api.entity.Result;
import com.example.api.entity.User;
import com.example.api.repository.LHistoryRepository;
import com.example.api.repository.QuestionRepository;
import com.example.api.repository.ResultRepository;
import com.example.api.repository.UserRepository;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.stream.Collectors;

/**
 * 履歴サービス
 * 対戦履歴・学習履歴の取得を提供
 */
@Service
public class HistoryService {

    private static final Logger logger = LoggerFactory.getLogger(HistoryService.class);
    private static final DateTimeFormatter DATE_FORMATTER = DateTimeFormatter.ofPattern("yyyy/MM/dd HH:mm");

    @Autowired
    private ResultRepository resultRepository;

    @Autowired
    private LHistoryRepository lHistoryRepository;

    @Autowired
    private QuestionRepository questionRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private ObjectMapper objectMapper;

    // ========== 対戦履歴 ==========

    /**
     * 対戦履歴一覧を取得（直近20件）
     */
    @Transactional(readOnly = true)
    public List<BattleHistoryItemResponse> getBattleHistory(Long userId) {
        logger.info("対戦履歴取得: userId={}", userId);

        List<Result> results = resultRepository.findByPlayerIdWithUsersOrderByEndedAtDesc(
                userId, PageRequest.of(0, 20));

        return results.stream()
                .map(this::convertToBattleHistoryItem)
                .collect(Collectors.toList());
    }

    /**
     * 対戦履歴詳細を取得
     */
    @Transactional(readOnly = true)
    public BattleHistoryDetailResponse getBattleHistoryDetail(Long resultId) {
        logger.info("対戦履歴詳細取得: resultId={}", resultId);

        Result result = resultRepository.findByIdWithUsers(resultId);
        if (result == null) {
            throw new IllegalArgumentException("対戦履歴が見つかりません: " + resultId);
        }

        return convertToBattleHistoryDetail(result);
    }

    private BattleHistoryItemResponse convertToBattleHistoryItem(Result result) {
        // スコア計算
        int[] scores = calculateScores(result);

        // 引き分け判定（resultDetailから取得、またはスコアから判定）
        boolean isDraw = checkIsDraw(result, scores);

        // レート情報（ランク戦のみ）
        Integer rateChange = null;
        Integer rateAtEnd = null;
        if (result.getMatchType() == Result.MatchType.rank) {
            rateChange = result.getUpdownRate();
            rateAtEnd = result.getRateAfterMatch();
        }

        return BattleHistoryItemResponse.builder()
                .resultId(result.getId())
                .enemyName(result.getEnemy().getUsername())
                .enemyId(result.getEnemy().getId().intValue())
                .playerScore(scores[0])
                .enemyScore(scores[1])
                .isWin(!isDraw && result.getResult())
                .isDraw(isDraw)
                .matchType(result.getMatchType() == Result.MatchType.rank ? "ランク" : "ルーム")
                .endedAt(result.getEndedAt().format(DATE_FORMATTER))
                .rateAfterMatch(rateChange)
                .rateAtEnd(rateAtEnd)
                .outcomeReason(result.getOutcomeReason() != null ? result.getOutcomeReason().name() : "normal")
                .build();
    }

    private BattleHistoryDetailResponse convertToBattleHistoryDetail(Result result) {
        // スコア計算
        int[] scores = calculateScores(result);

        // 引き分け判定（resultDetailから取得、またはスコアから判定）
        boolean isDraw = checkIsDraw(result, scores);

        // レート情報（ランク戦のみ）
        Integer rateChange = null;
        Integer rateAtEnd = null;
        if (result.getMatchType() == Result.MatchType.rank) {
            rateChange = result.getUpdownRate();
            rateAtEnd = result.getRateAfterMatch();
        }

        // ラウンド詳細を取得
        List<BattleHistoryDetailResponse.RoundDetail> rounds = extractRoundDetails(result, result.getOutcomeReason());

        return BattleHistoryDetailResponse.builder()
                .resultId(result.getId())
                .enemyName(result.getEnemy().getUsername())
                .enemyId(result.getEnemy().getId().intValue())
                .playerScore(scores[0])
                .enemyScore(scores[1])
                .isWin(!isDraw && result.getResult())
                .isDraw(isDraw)
                .matchType(result.getMatchType() == Result.MatchType.rank ? "ランク" : "ルーム")
                .endedAt(result.getEndedAt().format(DATE_FORMATTER))
                .rateAfterMatch(rateChange)
                .rateAtEnd(rateAtEnd)
                .outcomeReason(result.getOutcomeReason() != null ? result.getOutcomeReason().name() : "normal")
                .useLanguage(result.getUseLanguage())
                .rounds(rounds)
                .build();
    }

    private int[] calculateScores(Result result) {
        int playerScore = 0;
        int enemyScore = 0;

        Map<String, Object> resultDetail = result.getResultDetail();
        if (resultDetail != null) {
            try {
                // myWins/opponentWinsから直接スコアを取得（降参・切断時も正しく表示）
                if (resultDetail.containsKey("myWins") && resultDetail.containsKey("opponentWins")) {
                    playerScore = resultDetail.get("myWins") != null
                        ? ((Number) resultDetail.get("myWins")).intValue() : 0;
                    enemyScore = resultDetail.get("opponentWins") != null
                        ? ((Number) resultDetail.get("opponentWins")).intValue() : 0;
                } else if (resultDetail.containsKey("rounds")) {
                    // 旧データ互換: roundsからカウント
                    @SuppressWarnings("unchecked")
                    List<Map<String, Object>> rounds = (List<Map<String, Object>>) resultDetail.get("rounds");
                    Long playerId = result.getPlayer().getId();

                    for (Map<String, Object> round : rounds) {
                        Object winnerIdObj = round.get("winnerId");
                        if (winnerIdObj != null) {
                            Long winnerId = winnerIdObj instanceof Number
                                ? ((Number) winnerIdObj).longValue()
                                : Long.parseLong(winnerIdObj.toString());
                            if (winnerId.equals(playerId)) {
                                playerScore++;
                            } else if (winnerId > 0) {
                                enemyScore++;
                            }
                        }
                    }
                }
            } catch (Exception e) {
                logger.warn("スコア計算エラー: {}", e.getMessage());
            }
        }

        return new int[]{playerScore, enemyScore};
    }

    /**
     * 引き分けかどうかを判定
     * resultDetailのisDrawフラグ、またはスコアが同点かどうかで判定
     */
    private boolean checkIsDraw(Result result, int[] scores) {
        Map<String, Object> resultDetail = result.getResultDetail();
        if (resultDetail != null && resultDetail.containsKey("isDraw")) {
            return Boolean.TRUE.equals(resultDetail.get("isDraw"));
        }
        // フォールバック: スコアが同点で、降参・切断でない場合は引き分け
        if (scores[0] == scores[1] &&
            result.getOutcomeReason() != Result.OutcomeReason.surrender &&
            result.getOutcomeReason() != Result.OutcomeReason.disconnect) {
            return true;
        }
        return false;
    }

    private List<BattleHistoryDetailResponse.RoundDetail> extractRoundDetails(Result result, Result.OutcomeReason outcomeReason) {
        List<BattleHistoryDetailResponse.RoundDetail> rounds = new ArrayList<>();

        Map<String, Object> resultDetail = result.getResultDetail();
        Map<String, Object> useQuestion = result.getUseQuestion();

        // 降参・切断の場合は全問題を表示
        boolean isSurrenderOrDisconnect = outcomeReason == Result.OutcomeReason.surrender ||
                                           outcomeReason == Result.OutcomeReason.disconnect;

        // 問題リストを取得
        List<Map<String, Object>> questions = new ArrayList<>();
        if (useQuestion != null && useQuestion.containsKey("questions")) {
            @SuppressWarnings("unchecked")
            List<Map<String, Object>> qs = (List<Map<String, Object>>) useQuestion.get("questions");
            questions = qs;
        }

        // ラウンドデータを取得
        List<Map<String, Object>> roundsData = new ArrayList<>();
        if (resultDetail != null && resultDetail.containsKey("rounds")) {
            @SuppressWarnings("unchecked")
            List<Map<String, Object>> rds = (List<Map<String, Object>>) resultDetail.get("rounds");
            roundsData = rds;
        }

        Long playerId = result.getPlayer().getId();
        Long enemyId = result.getEnemy().getId();

        try {
            // 降参・切断の場合は全問題を、通常の場合はプレイされたラウンドのみを表示
            int totalRounds = isSurrenderOrDisconnect ? questions.size() : roundsData.size();

            for (int i = 0; i < totalRounds; i++) {
                // 問題情報を取得
                Integer questionId = null;
                String questionText = "";
                String questionFormat = "";
                String correctAnswer = "";

                if (i < questions.size()) {
                    Map<String, Object> q = questions.get(i);
                    questionId = q.get("questionId") != null
                        ? ((Number) q.get("questionId")).intValue()
                        : null;
                    questionText = (String) q.getOrDefault("text", "");
                    questionFormat = (String) q.getOrDefault("questionFormat", "");
                    // リスニング問題はcompleteSentenceを正解として使用
                    if ("LISTENING".equalsIgnoreCase(questionFormat)) {
                        correctAnswer = (String) q.getOrDefault("completeSentence", "");
                        if (correctAnswer.isEmpty()) {
                            // フォールバック: completeSentenceがない場合はanswerを使用
                            correctAnswer = (String) q.getOrDefault("answer", "");
                        }
                    } else {
                        correctAnswer = (String) q.getOrDefault("answer", "");
                    }
                }

                // このラウンドがプレイされたかどうか
                boolean roundWasPlayed = i < roundsData.size();

                String playerAnswer = "";
                String enemyAnswer = "";
                boolean isPlayerCorrect = false;
                boolean isEnemyCorrect = false;
                String roundWinner = "draw";
                String status = "played";

                if (roundWasPlayed) {
                    Map<String, Object> roundData = roundsData.get(i);

                    // 回答情報を取得
                    @SuppressWarnings("unchecked")
                    Map<String, Object> answers = (Map<String, Object>) roundData.getOrDefault("answers", new HashMap<>());

                    // playerInfoからも回答を取得（新フォーマット対応）
                    @SuppressWarnings("unchecked")
                    Map<String, Object> playerInfo = (Map<String, Object>) roundData.getOrDefault("playerInfo", new HashMap<>());

                    // answersから回答を取得
                    for (Map.Entry<String, Object> entry : answers.entrySet()) {
                        String odString = entry.getKey();
                        Long odId = Long.parseLong(odString);
                        @SuppressWarnings("unchecked")
                        Map<String, Object> answerData = (Map<String, Object>) entry.getValue();

                        String answer = (String) answerData.getOrDefault("answer", "");
                        boolean isCorrect = Boolean.TRUE.equals(answerData.get("isCorrect"));

                        if (odId.equals(playerId)) {
                            playerAnswer = answer;
                            isPlayerCorrect = isCorrect;
                        } else if (odId.equals(enemyId)) {
                            enemyAnswer = answer;
                            isEnemyCorrect = isCorrect;
                        }
                    }

                    // playerInfoから回答を取得（フォールバック）
                    if (playerAnswer.isEmpty() && !playerInfo.isEmpty()) {
                        @SuppressWarnings("unchecked")
                        Map<String, Object> p1Info = (Map<String, Object>) playerInfo.get(playerId.toString());
                        if (p1Info != null) {
                            Object ans = p1Info.get("answer");
                            playerAnswer = ans != null ? ans.toString() : "";
                            isPlayerCorrect = Boolean.TRUE.equals(p1Info.get("isCorrect"));
                        }
                        @SuppressWarnings("unchecked")
                        Map<String, Object> p2Info = (Map<String, Object>) playerInfo.get(enemyId.toString());
                        if (p2Info != null) {
                            Object ans = p2Info.get("answer");
                            enemyAnswer = ans != null ? ans.toString() : "";
                            isEnemyCorrect = Boolean.TRUE.equals(p2Info.get("isCorrect"));
                        }
                    }

                    // 勝者判定
                    Object winnerIdObj = roundData.get("winnerId");
                    if (winnerIdObj != null) {
                        Long winnerId = winnerIdObj instanceof Number
                            ? ((Number) winnerIdObj).longValue()
                            : Long.parseLong(winnerIdObj.toString());
                        if (winnerId.equals(playerId)) {
                            roundWinner = "player";
                        } else if (winnerId.equals(enemyId)) {
                            roundWinner = "enemy";
                        }
                    }

                    status = "played";
                } else {
                    // ラウンドがプレイされなかった場合
                    status = isSurrenderOrDisconnect ? "surrendered" : "not_played";
                    roundWinner = "none";
                }

                rounds.add(BattleHistoryDetailResponse.RoundDetail.builder()
                        .roundNumber(i + 1)
                        .questionId(questionId)
                        .questionText(questionText)
                        .questionFormat(questionFormat)
                        .playerAnswer(playerAnswer)
                        .enemyAnswer(enemyAnswer)
                        .isPlayerCorrect(isPlayerCorrect)
                        .isEnemyCorrect(isEnemyCorrect)
                        .roundWinner(roundWinner)
                        .status(status)
                        .correctAnswer(correctAnswer)
                        .build());
            }
        } catch (Exception e) {
            logger.error("ラウンド詳細抽出エラー: {}", e.getMessage(), e);
        }

        return rounds;
    }

    // ========== 学習履歴 ==========

    /**
     * 学習履歴一覧を取得（直近20件）
     */
    @Transactional(readOnly = true)
    public List<LearningHistoryItemResponse> getLearningHistory(Long userId) {
        logger.info("学習履歴取得: userId={}", userId);

        List<LHistory> histories = lHistoryRepository.findTop20ByUserIdOrderByLearningAtDesc(userId);

        return histories.stream()
                .map(this::convertToLearningHistoryItem)
                .collect(Collectors.toList());
    }

    /**
     * 学習履歴詳細を取得
     */
    @Transactional(readOnly = true)
    public LearningHistoryDetailResponse getLearningHistoryDetail(Long historyId) {
        logger.info("学習履歴詳細取得: historyId={}", historyId);

        LHistory history = lHistoryRepository.findById(historyId)
                .orElseThrow(() -> new IllegalArgumentException("学習履歴が見つかりません: " + historyId));

        return convertToLearningHistoryDetail(history);
    }

    private LearningHistoryItemResponse convertToLearningHistoryItem(LHistory history) {
        int correctCount = 0;
        int totalCount = 0;

        try {
            Map<String, Object> result = objectMapper.readValue(
                history.getResult(),
                new TypeReference<Map<String, Object>>() {}
            );
            correctCount = result.get("correctCount") != null
                ? ((Number) result.get("correctCount")).intValue()
                : 0;
            totalCount = result.get("totalCount") != null
                ? ((Number) result.get("totalCount")).intValue()
                : 0;
        } catch (Exception e) {
            logger.warn("学習結果パースエラー: {}", e.getMessage());
        }

        return LearningHistoryItemResponse.builder()
                .historyId(history.getL_history_id())
                .learningAt(history.getLearning_at())
                .correctCount(correctCount)
                .totalCount(totalCount)
                .learningLang(history.getLearning_lang())
                .build();
    }

    private LearningHistoryDetailResponse convertToLearningHistoryDetail(LHistory history) {
        int correctCount = 0;
        int totalCount = 0;
        List<LearningHistoryDetailResponse.QuestionDetail> questionDetails = new ArrayList<>();

        try {
            Map<String, Object> result = objectMapper.readValue(
                history.getResult(),
                new TypeReference<Map<String, Object>>() {}
            );
            correctCount = result.get("correctCount") != null
                ? ((Number) result.get("correctCount")).intValue()
                : 0;
            totalCount = result.get("totalCount") != null
                ? ((Number) result.get("totalCount")).intValue()
                : 0;

            // 回答詳細を取得
            @SuppressWarnings("unchecked")
            List<Map<String, Object>> answers = (List<Map<String, Object>>) result.get("answers");
            if (answers != null) {
                // 問題IDリストを取得
                List<Integer> questionIds = objectMapper.readValue(
                    history.getQuestions(),
                    new TypeReference<List<Integer>>() {}
                );

                // 問題情報を一括取得
                Map<Integer, Question> questionMap = new HashMap<>();
                for (Integer qId : questionIds) {
                    questionRepository.findById(qId).ifPresent(q -> questionMap.put(qId, q));
                }

                for (Map<String, Object> answer : answers) {
                    Integer questionId = answer.get("questionId") != null
                        ? ((Number) answer.get("questionId")).intValue()
                        : null;
                    String userAnswer = (String) answer.getOrDefault("userAnswer", "");
                    boolean isCorrect = Boolean.TRUE.equals(answer.get("isCorrect"));

                    Question question = questionId != null ? questionMap.get(questionId) : null;
                    String questionText = question != null ? question.getText() : "";
                    String questionFormat = question != null && question.getQuestionFormat() != null
                        ? question.getQuestionFormat().getValue()
                        : "";
                    // リスニング問題はcompleteSentenceを正解として使用
                    String correctAnswer = "";
                    if (question != null) {
                        if (question.getQuestionFormat() != null &&
                            "listening".equalsIgnoreCase(question.getQuestionFormat().getValue())) {
                            correctAnswer = question.getCompleteSentence() != null
                                ? question.getCompleteSentence()
                                : question.getAnswer();
                        } else {
                            correctAnswer = question.getAnswer() != null ? question.getAnswer() : "";
                        }
                    }

                    questionDetails.add(LearningHistoryDetailResponse.QuestionDetail.builder()
                            .questionId(questionId)
                            .questionText(questionText)
                            .correctAnswer(correctAnswer)
                            .userAnswer(userAnswer)
                            .isCorrect(isCorrect)
                            .questionFormat(questionFormat)
                            .build());
                }
            }
        } catch (Exception e) {
            logger.error("学習履歴詳細パースエラー: {}", e.getMessage(), e);
        }

        return LearningHistoryDetailResponse.builder()
                .historyId(history.getL_history_id())
                .learningAt(history.getLearning_at())
                .correctCount(correctCount)
                .totalCount(totalCount)
                .learningLang(history.getLearning_lang())
                .questions(questionDetails)
                .build();
    }
}
