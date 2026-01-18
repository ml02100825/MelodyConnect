package com.example.api.controller;

import com.example.api.dto.history.*;
import com.example.api.service.HistoryService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * 履歴コントローラー
 * 対戦履歴・学習履歴のエンドポイントを提供
 */
@RestController
@RequestMapping("/api/history")
public class HistoryController {

    private static final Logger logger = LoggerFactory.getLogger(HistoryController.class);

    @Autowired
    private HistoryService historyService;

    // ========== 対戦履歴 ==========

    /**
     * 対戦履歴一覧を取得
     */
    @GetMapping("/battle/{userId}")
    public ResponseEntity<List<BattleHistoryItemResponse>> getBattleHistory(
            @PathVariable Long userId) {
        logger.info("対戦履歴一覧取得: userId={}", userId);

        try {
            List<BattleHistoryItemResponse> history = historyService.getBattleHistory(userId);
            return ResponseEntity.ok(history);
        } catch (Exception e) {
            logger.error("対戦履歴取得エラー: {}", e.getMessage(), e);
            return ResponseEntity.internalServerError().build();
        }
    }

    /**
     * 対戦履歴詳細を取得
     */
    @GetMapping("/battle/detail/{resultId}")
    public ResponseEntity<BattleHistoryDetailResponse> getBattleHistoryDetail(
            @PathVariable Long resultId) {
        logger.info("対戦履歴詳細取得: resultId={}", resultId);

        try {
            BattleHistoryDetailResponse detail = historyService.getBattleHistoryDetail(resultId);
            return ResponseEntity.ok(detail);
        } catch (IllegalArgumentException e) {
            logger.warn("対戦履歴が見つかりません: resultId={}", resultId);
            return ResponseEntity.notFound().build();
        } catch (Exception e) {
            logger.error("対戦履歴詳細取得エラー: {}", e.getMessage(), e);
            return ResponseEntity.internalServerError().build();
        }
    }

    // ========== 学習履歴 ==========

    /**
     * 学習履歴一覧を取得
     */
    @GetMapping("/learning/{userId}")
    public ResponseEntity<List<LearningHistoryItemResponse>> getLearningHistory(
            @PathVariable Long userId) {
        logger.info("学習履歴一覧取得: userId={}", userId);

        try {
            List<LearningHistoryItemResponse> history = historyService.getLearningHistory(userId);
            return ResponseEntity.ok(history);
        } catch (Exception e) {
            logger.error("学習履歴取得エラー: {}", e.getMessage(), e);
            return ResponseEntity.internalServerError().build();
        }
    }

    /**
     * 学習履歴詳細を取得
     */
    @GetMapping("/learning/detail/{historyId}")
    public ResponseEntity<LearningHistoryDetailResponse> getLearningHistoryDetail(
            @PathVariable Long historyId) {
        logger.info("学習履歴詳細取得: historyId={}", historyId);

        try {
            LearningHistoryDetailResponse detail = historyService.getLearningHistoryDetail(historyId);
            return ResponseEntity.ok(detail);
        } catch (IllegalArgumentException e) {
            logger.warn("学習履歴が見つかりません: historyId={}", historyId);
            return ResponseEntity.notFound().build();
        } catch (Exception e) {
            logger.error("学習履歴詳細取得エラー: {}", e.getMessage(), e);
            return ResponseEntity.internalServerError().build();
        }
    }
}
