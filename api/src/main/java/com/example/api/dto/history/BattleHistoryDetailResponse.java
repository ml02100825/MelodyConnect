package com.example.api.dto.history;

import lombok.Builder;
import lombok.Data;

import java.util.List;

/**
 * 対戦履歴詳細
 */
@Data
@Builder
public class BattleHistoryDetailResponse {
    private Long resultId;
    private String enemyName;
    private Integer enemyId;
    private int playerScore;
    private int enemyScore;
    private boolean isWin;
    private boolean isDraw;         // 引き分けかどうか
    private String matchType;
    private String endedAt;
    private Integer rateAfterMatch; // レート変動
    private Integer rateAtEnd;      // 対戦終了時のレート
    private String outcomeReason;
    private String useLanguage;
    private List<RoundDetail> rounds;

    @Data
    @Builder
    public static class RoundDetail {
        private int roundNumber;
        private Integer questionId;
        private String questionText;
        private String questionFormat;
        private String playerAnswer;
        private String enemyAnswer;
        private boolean isPlayerCorrect;
        private boolean isEnemyCorrect;
        private String roundWinner; // "player", "enemy", "draw"
        private String status;      // "played", "surrendered", "not_played"
        private String correctAnswer; // 正解（降参時に表示用）
    }
}
