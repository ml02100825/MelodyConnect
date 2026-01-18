package com.example.api.dto.history;

import lombok.Builder;
import lombok.Data;

/**
 * 対戦履歴一覧アイテム
 */
@Data
@Builder
public class BattleHistoryItemResponse {
    private Long resultId;
    private String enemyName;
    private Integer enemyId;
    private int playerScore;
    private int enemyScore;
    private boolean isWin;
    private String matchType;       // "ランク" or "ルーム"
    private String endedAt;
    private Integer rateAfterMatch; // レート変動（ランク戦のみ、ルーム戦はnull）
    private Integer rateAtEnd;      // 対戦終了時のレート（ランク戦のみ）
    private String outcomeReason;   // normal, surrender, timeout, disconnect
}
