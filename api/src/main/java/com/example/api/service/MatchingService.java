package com.example.api.service;

import com.example.api.dto.LifeStatusResponse;
import com.example.api.entity.Rate;
import com.example.api.entity.Result;
import com.example.api.entity.User;
import com.example.api.repository.RateRepository;
import com.example.api.repository.ResultRepository;
import com.example.api.repository.UserRepository;
import com.example.api.util.SeasonCalculator;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;

/**
 * マッチングサービス
 * Rankedマッチのマッチングロジックと結果記録を管理します
 */
@Service
public class MatchingService {

    private static final Logger logger = LoggerFactory.getLogger(MatchingService.class);

    @Autowired
    private MatchingQueueService queueService;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private RateRepository rateRepository;

    @Autowired
    private ResultRepository resultRepository;

    @Autowired
    private SeasonCalculator seasonCalculator;

    @Autowired
    private LifeService lifeService;

    /**
     * キュー参加結果
     */
    public static class JoinQueueResult {
        private final boolean success;
        private final String errorCode;
        private final String message;
        private final LifeStatusResponse lifeStatus;

        private JoinQueueResult(boolean success, String errorCode, String message, LifeStatusResponse lifeStatus) {
            this.success = success;
            this.errorCode = errorCode;
            this.message = message;
            this.lifeStatus = lifeStatus;
        }

        public static JoinQueueResult success() {
            return new JoinQueueResult(true, null, null, null);
        }

        public static JoinQueueResult insufficientLife(LifeStatusResponse lifeStatus) {
            return new JoinQueueResult(false, "INSUFFICIENT_LIFE", "ライフが不足しています", lifeStatus);
        }

        public static JoinQueueResult alreadyInQueue() {
            return new JoinQueueResult(false, "ALREADY_IN_QUEUE", "既にキューに参加しています", null);
        }

        public static JoinQueueResult error(String message) {
            return new JoinQueueResult(false, "ERROR", message, null);
        }

        public boolean isSuccess() {
            return success;
        }

        public String getErrorCode() {
            return errorCode;
        }

        public String getMessage() {
            return message;
        }

        public LifeStatusResponse getLifeStatus() {
            return lifeStatus;
        }
    }

    /**
     * マッチング結果
     */
    public static class MatchResult {
        private final String matchId;
        private final Long user1Id;
        private final Long user2Id;
        private final String language;

        public MatchResult(String matchId, Long user1Id, Long user2Id, String language) {
            this.matchId = matchId;
            this.user1Id = user1Id;
            this.user2Id = user2Id;
            this.language = language;
        }

        public String getMatchId() {
            return matchId;
        }

        public Long getUser1Id() {
            return user1Id;
        }

        public Long getUser2Id() {
            return user2Id;
        }

        public String getLanguage() {
            return language;
        }
    }

    /**
     * プレイヤーをマッチングキューに追加（ランクマッチ用）
     * @param userId ユーザーID
     * @param language 言語
     * @return キュー参加結果
     */
    @Transactional
    public JoinQueueResult joinQueue(Long userId, String language) {
        logger.info("キュー参加処理開始: userId={}, language={}", userId, language);

        // ユーザーのレーティングを取得
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("ユーザーが見つかりません"));

        // ライフが0の場合は参加不可（消費はマッチ成立時に実施）
        LifeStatusResponse lifeStatus = lifeService.getLifeStatus(userId);
        if (lifeStatus.getCurrentLife() <= 0) {
            logger.info("ライフ不足によりキュー参加拒否: userId={}, life={}", userId, lifeStatus.getCurrentLife());
            return JoinQueueResult.insufficientLife(lifeStatus);
        }

        Integer currentSeason = seasonCalculator.getCurrentSeason();
        Rate rate = rateRepository.findByUserAndSeason(user, currentSeason)
                .orElseGet(() -> {
                    // レーティングが存在しない場合は作成
                    Rate newRate = new Rate(user, currentSeason);
                    return rateRepository.save(newRate);
                });

        logger.info("プレイヤー情報: userId={}, rating={}, language={}", userId, rate.getRate(), language);
        boolean result = queueService.addToQueue(userId, rate.getRate(), language);

        if (!result) {
            // 既にキューに参加している場合
            // エラーではなく成功として扱う（画面リロードや再接続時の重複参加を許容）
            logger.info("既にキューに参加中（成功として扱う）: userId={}", userId);
            return JoinQueueResult.success();
        }

        logger.info("キュー参加成功: userId={}", userId);
        return JoinQueueResult.success();
    }

    /**
     * プレイヤーのマッチングキュー情報を更新
     * @param userId ユーザーID
     * @param language 言語
     * @return キュー更新結果
     */
    @Transactional
    public JoinQueueResult updateQueue(Long userId, String language) {
        logger.info("キュー更新処理開始: userId={}, language={}", userId, language);

        // ユーザーのレーティングを取得
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("ユーザーが見つかりません"));

        // ライフが0の場合は参加不可（消費はマッチ成立時に実施）
        LifeStatusResponse lifeStatus = lifeService.getLifeStatus(userId);
        if (lifeStatus.getCurrentLife() <= 0) {
            logger.info("ライフ不足によりキュー更新拒否: userId={}, life={}", userId, lifeStatus.getCurrentLife());
            return JoinQueueResult.insufficientLife(lifeStatus);
        }

        Integer currentSeason = seasonCalculator.getCurrentSeason();
        Rate rate = rateRepository.findByUserAndSeason(user, currentSeason)
                .orElseGet(() -> {
                    // レーティングが存在しない場合は作成
                    Rate newRate = new Rate(user, currentSeason);
                    return rateRepository.save(newRate);
                });

        logger.info("更新プレイヤー情報: userId={}, rating={}, language={}", userId, rate.getRate(), language);

        if (!queueService.isInQueue(userId)) {
            logger.info("キューに存在しないため参加処理を実行: userId={}", userId);
            return joinQueue(userId, language);
        }

        boolean updated = queueService.updateQueue(userId, rate.getRate(), language);
        if (!updated) {
            logger.warn("キュー更新失敗: userId={}", userId);
            return JoinQueueResult.error("マッチング条件の更新に失敗しました");
        }

        logger.info("キュー更新成功: userId={}", userId);
        return JoinQueueResult.success();
    }

    /**
     * プレイヤーをマッチングキューから削除
     * @param userId ユーザーID
     * @return 削除成功時true
     */
    public boolean leaveQueue(Long userId) {
        return queueService.removeFromQueue(userId);
    }

    /**
     * 指定言語でマッチングを試行
     * @param language 言語
     * @return マッチング成立時MatchResult、成立しない場合null
     */
    public synchronized MatchResult tryMatch(String language) {
        List<MatchingQueueService.QueuedPlayer> queue = queueService.getQueueByLanguage(language);

        // logger.debug("tryMatch開始: language={}, キューサイズ={}", language, queue.size());

        if (queue.size() < 2) {
            // logger.debug("マッチング不可（プレイヤー不足）: language={}, キューサイズ={}", language, queue.size());
            return null; // 2人未満の場合はマッチング不可
        }

        // レーティング順にソート
        queue.sort(Comparator.comparing(MatchingQueueService.QueuedPlayer::getRating));

        // 各プレイヤーに対してマッチング相手を探す
        for (int i = 0; i < queue.size(); i++) {
            MatchingQueueService.QueuedPlayer player1 = queue.get(i);
            long waitTime = player1.getWaitTimeSeconds();

            // 待機時間に応じたレーティング差の許容範囲を段階的に拡大（最高300）
            int allowedDiff;
            if (waitTime >= 30) {
                allowedDiff = 250;  // 15秒以上: 300（最大）
            } else if (waitTime >= 15) {
                allowedDiff = 250;  // 10-15秒: 250
            } else {
                allowedDiff = 150;  // 0-5秒: 150
            }

            // logger.debug("プレイヤー検索: userId={}, rating={}, 待機時間={}秒, 許容レート差={}",
            //         player1.getUserId(), player1.getRating(), waitTime, allowedDiff);

            // 最も近いレーティングのプレイヤーを探す
            MatchingQueueService.QueuedPlayer bestMatch = null;
            int minDiff = Integer.MAX_VALUE;

            for (int j = i + 1; j < queue.size(); j++) {
                MatchingQueueService.QueuedPlayer player2 = queue.get(j);
                int ratingDiff = Math.abs(player1.getRating() - player2.getRating());

                // logger.debug("  候補チェック: userId={}, rating={}, レート差={}",
                //         player2.getUserId(), player2.getRating(), ratingDiff);

                if (ratingDiff <= allowedDiff && ratingDiff < minDiff) {
                    minDiff = ratingDiff;
                    bestMatch = player2;
                    // logger.debug("  -> 候補マッチ更新: userId={}, レート差={}", player2.getUserId(), ratingDiff);
                }
            }

            // マッチング成立
            if (bestMatch != null) {
                // logger.info("マッチング成立確定: user1={} (rating={}), user2={} (rating={}), レート差={}",
                //         player1.getUserId(), player1.getRating(), bestMatch.getUserId(), bestMatch.getRating(), minDiff);

                // キューから削除
                queueService.removeFromQueue(player1.getUserId());
                queueService.removeFromQueue(bestMatch.getUserId());

                // マッチIDを生成
                String matchId = UUID.randomUUID().toString();

                return new MatchResult(matchId, player1.getUserId(), bestMatch.getUserId(), language);
            }
        }

        // logger.debug("マッチング不成立（条件を満たす相手なし）: language={}", language);
        return null; // マッチング不成立
    }

    /**
     * バトル初期化用のResultレコードを作成
     * @param matchId マッチID
     * @param user1Id プレイヤー1のID
     * @param user2Id プレイヤー2のID
     * @param language 言語
     */
    @Transactional
    public void createInitialResult(String matchId, Long user1Id, Long user2Id, String language) {
        Integer currentSeason = seasonCalculator.getCurrentSeason();

        // ユーザーエンティティを取得
        User user1 = userRepository.findById(user1Id)
            .orElseThrow(() -> new IllegalArgumentException("User not found: " + user1Id));
        User user2 = userRepository.findById(user2Id)
            .orElseThrow(() -> new IllegalArgumentException("User not found: " + user2Id));

        // プレイヤー1用のResultレコード
        Result result1 = new Result();
        result1.setMatchUuid(matchId);
        result1.setPlayer(user1);
        result1.setEnemy(user2);
        result1.setUseLanguage(language);
        result1.setMatchType(Result.MatchType.rank);
        resultRepository.save(result1);

        // プレイヤー2用のResultレコード
        Result result2 = new Result();
        result2.setMatchUuid(matchId);
        result2.setPlayer(user2);
        result2.setEnemy(user1);
        result2.setUseLanguage(language);
        result2.setMatchType(Result.MatchType.rank);
        resultRepository.save(result2);
    }

    /**
     * タイムアウトしたプレイヤーを削除
     * @return 削除されたユーザーIDのリスト
     */
    public List<Long> removeTimedOutPlayers() {
        return queueService.removeTimedOutPlayers();
    }

    /**
     * キュー統計情報を取得
     */
    public Map<String, Object> getQueueStats() {
        return queueService.getQueueStats();
    }
}
