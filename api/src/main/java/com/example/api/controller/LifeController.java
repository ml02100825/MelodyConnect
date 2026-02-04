package com.example.api.controller;

import com.example.api.dto.LifeStatusResponse;
import com.example.api.dto.RecoveryItemResponse;
import com.example.api.dto.UseItemRequest;
import com.example.api.dto.UseItemResponse;
import com.example.api.service.LifeService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

/**
 * ライフ（スタミナ）コントローラー
 * ライフ状態の取得APIを提供します
 */
@RestController
@RequestMapping("/api/life")
public class LifeController {

    private static final Logger logger = LoggerFactory.getLogger(LifeController.class);

    @Autowired
    private LifeService lifeService;

    /**
     * ライフ状態を取得
     * GET /api/life?userId={userId}
     * @param userId ユーザーID
     * @return ライフ状態（currentLife, maxLife, nextRecoveryInSeconds, isSubscriber）
     */
    @GetMapping
    public ResponseEntity<LifeStatusResponse> getLifeStatus(@RequestParam Long userId) {
        logger.info("ライフ状態取得リクエスト: userId={}", userId);

        try {
            LifeStatusResponse response = lifeService.getLifeStatus(userId);
            logger.info("ライフ状態取得成功: userId={}, life={}/{}", userId, response.getCurrentLife(), response.getMaxLife());
            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            logger.error("ライフ状態取得エラー: userId={}, error={}", userId, e.getMessage());
            return ResponseEntity.notFound().build();
        } catch (Exception e) {
            logger.error("ライフ状態取得エラー: userId={}, error={}", userId, e.getMessage(), e);
            return ResponseEntity.internalServerError().build();
        }
    }

    /**
     * 回復アイテム情報を取得
     * GET /api/life/recovery-item?userId={userId}
     * @param userId ユーザーID
     * @return 回復アイテム情報（名前、説明、回復量、所持数）
     */
    @GetMapping("/recovery-item")
    public ResponseEntity<RecoveryItemResponse> getRecoveryItem(@RequestParam Long userId) {
        logger.info("回復アイテム情報取得リクエスト: userId={}", userId);

        try {
            RecoveryItemResponse response = lifeService.getRecoveryItem(userId);
            logger.info("回復アイテム情報取得成功: userId={}, quantity={}", userId, response.getQuantity());
            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            logger.error("回復アイテム情報取得エラー: userId={}, error={}", userId, e.getMessage());
            return ResponseEntity.notFound().build();
        } catch (Exception e) {
            logger.error("回復アイテム情報取得エラー: userId={}, error={}", userId, e.getMessage(), e);
            return ResponseEntity.internalServerError().build();
        }
    }

    /**
     * 回復アイテムを使用
     * POST /api/life/use-item
     * @param request ユーザーIDとアイテムID
     * @return 使用結果（成功/失敗、新ライフ、残り所持数）
     */
    @PostMapping("/use-item")
    public ResponseEntity<UseItemResponse> useItem(@RequestBody UseItemRequest request) {
        logger.info("回復アイテム使用リクエスト: userId={}, itemId={}", request.getUserId(), request.getItemId());

        try {
            UseItemResponse response = lifeService.useRecoveryItem(request.getUserId(), request.getItemId());

            if (response.isSuccess()) {
                logger.info("回復アイテム使用成功: userId={}, newLife={}", request.getUserId(), response.getNewLife());
                return ResponseEntity.ok(response);
            } else {
                logger.info("回復アイテム使用失敗: userId={}, message={}", request.getUserId(), response.getMessage());
                return ResponseEntity.badRequest().body(response);
            }
        } catch (IllegalArgumentException e) {
            logger.error("回復アイテム使用エラー: userId={}, error={}", request.getUserId(), e.getMessage());
            return ResponseEntity.notFound().build();
        } catch (Exception e) {
            logger.error("回復アイテム使用エラー: userId={}, error={}", request.getUserId(), e.getMessage(), e);
            return ResponseEntity.internalServerError().build();
        }
    }
}
