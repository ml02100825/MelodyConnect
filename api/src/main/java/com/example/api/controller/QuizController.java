package com.example.api.controller;

import com.example.api.dto.*;
import com.example.api.service.QuizService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

/**
 * クイズコントローラー
 * 学習機能のエンドポイントを提供
 */
@RestController
@RequestMapping("/api/quiz")
@CrossOrigin(origins = "*")
public class QuizController {

    private static final Logger logger = LoggerFactory.getLogger(QuizController.class);

    @Autowired
    private QuizService quizService;

    /**
     * クイズを開始
     * 問題を取得または生成してセッションを作成
     */
    @PostMapping("/start")
    public ResponseEntity<QuizStartResponse> startQuiz(@RequestBody QuizStartRequest request) {
        logger.info("クイズ開始リクエスト: userId={}, language={}, mode={}",
            request.getUserId(), request.getLanguage(), request.getGenerationMode());

        try {
            QuizStartResponse response = quizService.startQuiz(request);
            return ResponseEntity.ok(response);

        } catch (IllegalArgumentException e) {
            logger.error("不正なリクエスト: {}", e.getMessage());
            return ResponseEntity.badRequest().body(
                QuizStartResponse.builder()
                    .message("エラー: " + e.getMessage())
                    .build()
            );
        } catch (Exception e) {
            logger.error("クイズ開始中にエラーが発生しました", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(
                QuizStartResponse.builder()
                    .message("クイズの開始に失敗しました: " + e.getMessage())
                    .build()
            );
        }
    }

    /**
     * クイズを完了
     * 結果を保存してスコアを返す
     */
    @PostMapping("/complete")
    public ResponseEntity<QuizCompleteResponse> completeQuiz(@RequestBody QuizCompleteRequest request) {
        logger.info("クイズ完了リクエスト: sessionId={}, userId={}",
            request.getSessionId(), request.getUserId());

        try {
            QuizCompleteResponse response = quizService.completeQuiz(request);
            return ResponseEntity.ok(response);

        } catch (IllegalArgumentException e) {
            logger.error("不正なリクエスト: {}", e.getMessage());
            return ResponseEntity.badRequest().body(
                QuizCompleteResponse.builder()
                    .message("エラー: " + e.getMessage())
                    .build()
            );
        } catch (Exception e) {
            logger.error("クイズ完了処理中にエラーが発生しました", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(
                QuizCompleteResponse.builder()
                    .message("クイズの完了に失敗しました: " + e.getMessage())
                    .build()
            );
        }
    }

    /**
     * ヘルスチェック
     */
    @GetMapping("/health")
    public ResponseEntity<String> health() {
        return ResponseEntity.ok("Quiz Service is running");
    }
}
