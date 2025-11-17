package com.example.api.service;

import com.example.api.entity.Rate;
import com.example.api.entity.Result;
import com.example.api.entity.User;
import com.example.api.repository.RateRepository;
import com.example.api.repository.ResultRepository;
import com.example.api.repository.UserRepository;
import com.example.api.util.SeasonCalculator;
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
        // ユーザーのレーティングを取得
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("ユーザーが見つかりません"));

        Integer currentSeason = seasonCalculator.getCurrentSeason();
        Rate rate = rateRepository.findByUserAndSeason(user, currentSeason)
                .orElseGet(() -> {
                    // レーティングが存在しない場合は作成
                    Rate newRate = new Rate(user, currentSeason);
                    return rateRepository.save(newRate);
                });

        return queueService.addToQueue(userId, rate.getRate(), language);
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

        if (queue.size() < 2) {
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

            // 最も近いレーティングのプレイヤーを探す
            MatchingQueueService.QueuedPlayer bestMatch = null;
            int minDiff = Integer.MAX_VALUE;

            for (int j = i + 1; j < queue.size(); j++) {
                MatchingQueueService.QueuedPlayer player2 = queue.get(j);
                int ratingDiff = Math.abs(player1.getRating() - player2.getRating());

                if (ratingDiff <= allowedDiff && ratingDiff < minDiff) {
                    minDiff = ratingDiff;
                    bestMatch = player2;
                }
            }

            // マッチング成立
            if (bestMatch != null) {
                // キューから削除
                queueService.removeFromQueue(player1.getUserId());
                queueService.removeFromQueue(bestMatch.getUserId());

                // マッチIDを生成
                String matchId = UUID.randomUUID().toString();

                return new MatchResult(matchId, player1.getUserId(), bestMatch.getUserId(), language);
            }
        }

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

        // プレイヤー1用のResultレコード
        Result result1 = new Result();
        result1.setMatchUuid(matchId);
        result1.setPlayerId(user1Id);
        result1.setEnemyId(user2Id);
        result1.setUseLanguage(language);
        result1.setMatchType(Result.MatchType.rank);
        resultRepository.save(result1);

        // プレイヤー2用のResultレコード
        Result result2 = new Result();
        result2.setMatchUuid(matchId);
        result2.setPlayerId(user2Id);
        result2.setEnemyId(user1Id);
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
