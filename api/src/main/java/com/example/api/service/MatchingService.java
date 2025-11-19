package com.example.api.service;

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
     * プレイヤーをマッチングキューに追加
     * @param userId ユーザーID
     * @param language 言語
     * @return 追加成功時true
     */
    @Transactional(readOnly = true)
    public boolean joinQueue(Long userId, String language) {
        logger.info("キュー参加処理開始: userId={}, language={}", userId, language);

        // ユーザーのレーティングを取得
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("ユーザーが見つかりません"));

        Integer currentSeason = seasonCalculator.getCurrentSeason();
        Rate rate = rateRepository.findByUserAndSeason(user, currentSeason)
                .orElseGet(() -> {
                    // レーティングが存在しない場合は作成
                    logger.info("新規Rateレコード作成: userId={}, season={}", userId, currentSeason);
                    Rate newRate = new Rate(user, currentSeason);
                    return rateRepository.save(newRate);
                });

        logger.info("プレイヤー情報: userId={}, rating={}, language={}", userId, rate.getRate(), language);
        boolean result = queueService.addToQueue(userId, rate.getRate(), language);
        logger.info("キュー追加結果: userId={}, success={}", userId, result);

        return result;
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

            // 待機時間に応じたレーティング差の許容範囲を決定
            int allowedDiff = waitTime >= 90 ? 200 : 150;

            logger.debug("プレイヤー検索: userId={}, rating={}, 待機時間={}秒, 許容レート差={}",
                    player1.getUserId(), player1.getRating(), waitTime, allowedDiff);

            // 最も近いレーティングのプレイヤーを探す
            MatchingQueueService.QueuedPlayer bestMatch = null;
            int minDiff = Integer.MAX_VALUE;

            for (int j = i + 1; j < queue.size(); j++) {
                MatchingQueueService.QueuedPlayer player2 = queue.get(j);
                int ratingDiff = Math.abs(player1.getRating() - player2.getRating());

                logger.debug("  候補チェック: userId={}, rating={}, レート差={}",
                        player2.getUserId(), player2.getRating(), ratingDiff);

                if (ratingDiff <= allowedDiff && ratingDiff < minDiff) {
                    minDiff = ratingDiff;
                    bestMatch = player2;
                    logger.debug("  -> 候補マッチ更新: userId={}, レート差={}", player2.getUserId(), ratingDiff);
                }
            }

            // マッチング成立
            if (bestMatch != null) {
                logger.info("マッチング成立確定: user1={} (rating={}), user2={} (rating={}), レート差={}",
                        player1.getUserId(), player1.getRating(), bestMatch.getUserId(), bestMatch.getRating(), minDiff);

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
