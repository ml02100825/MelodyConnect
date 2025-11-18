package com.example.api.controller;

import com.example.api.dto.QuestionGenerationRequest;
import com.example.api.dto.QuestionGenerationResponse;
import com.example.api.service.QuestionGeneratorService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

/**
 * 問題生成コントローラー
 * 歌詞から問題を自動生成するためのエンドポイントを提供
 */
@RestController
@RequestMapping("/api/questions")
@CrossOrigin(origins = "*")
public class QuestionGeneratorController {

    private static final Logger logger = LoggerFactory.getLogger(QuestionGeneratorController.class);

    @Autowired
    private QuestionGeneratorService questionGeneratorService;

    /**
     * 問題を生成
     *
     * @param request 問題生成リクエスト
     * @return 問題生成レスポンス
     */
    @PostMapping("/generate")
    public ResponseEntity<QuestionGenerationResponse> generateQuestions(
            @RequestBody QuestionGenerationRequest request) {

        logger.info("問題生成リクエスト受信: mode={}, userId={}", request.getMode(), request.getUserId());

        try {
            QuestionGenerationResponse response = questionGeneratorService.generateQuestions(request);
            logger.info("問題生成成功: totalCount={}", response.getTotalCount());
            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            logger.error("不正なリクエスト: {}", e.getMessage());
            return ResponseEntity.badRequest().body(
                QuestionGenerationResponse.builder()
                    .message("エラー: " + e.getMessage())
                    .build()
            );
        } catch (Exception e) {
            logger.error("問題生成中にエラーが発生しました", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(
                QuestionGenerationResponse.builder()
                    .message("問題生成に失敗しました: " + e.getMessage())
                    .build()
            );
        }
    }

    /**
     * ヘルスチェックエンドポイント
     */
    @GetMapping("/health")
    public ResponseEntity<String> health() {
        return ResponseEntity.ok("Question Generator Service is running");
    }
}
