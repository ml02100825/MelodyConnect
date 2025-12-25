package com.example.api.controller;

import com.example.api.dto.LifeStatusResponse;
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
}
