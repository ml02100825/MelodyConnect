package com.example.api.controller;

import com.example.api.dto.AnswerValidationRequest;
import com.example.api.dto.AnswerValidationResponse;
import com.example.api.dto.QuestionGenerationRequest;
import com.example.api.dto.QuestionGenerationResponse;
import com.example.api.entity.Question;
import com.example.api.repository.QuestionRepository;
import com.example.api.service.QuestionGeneratorService;
import com.example.api.service.VocabularyService;

import java.util.List;
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

    @Autowired
    private VocabularyService vocabularyService;

    @Autowired
    private QuestionRepository questionRepository;

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
     * 回答を検証（リスニング問題用）
     * 間違えた単語をWordnikで取得して保存します
     *
     * @param request 回答検証リクエスト
     * @return 回答検証レスポンス
     */
    @PostMapping("/validate-answer")
    public ResponseEntity<AnswerValidationResponse> validateAnswer(
            @RequestBody AnswerValidationRequest request) {

        logger.info("回答検証リクエスト受信: questionId={}", request.getQuestionId());

        try {
            // 問題を取得
            Question q = questionRepository.findById(request.getQuestionId())
                .orElseThrow(() -> new IllegalArgumentException("問題が見つかりません: " + request.getQuestionId()));

            String correctAnswer = q.getAnswer();
            String userAnswer = request.getUserAnswer();

            // 完全一致チェック（大文字小文字無視、前後の空白除去）
            boolean isCorrect = correctAnswer.trim().equalsIgnoreCase(userAnswer.trim());

            // リスニング問題の場合、間違えた単語を保存
            List<String> incorrectWords = List.of();
            if ("listening".equals(q.getQuestionFormat()) && !isCorrect) {
                incorrectWords = vocabularyService.saveIncorrectWords(userAnswer, correctAnswer);
            }

            // 正解率を計算（単純な文字列比較）
            double accuracy = calculateAccuracy(userAnswer, correctAnswer);

            AnswerValidationResponse response = AnswerValidationResponse.builder()
                .correct(isCorrect)
                .correctAnswer(correctAnswer)
                .userAnswer(userAnswer)
                .incorrectWords(incorrectWords)
                .accuracy(accuracy)
                .message(isCorrect ? "正解です！" : "不正解です。正解は「" + correctAnswer + "」です。")
                .build();

            return ResponseEntity.ok(response);

        } catch (IllegalArgumentException e) {
            logger.error("不正なリクエスト: {}", e.getMessage());
            return ResponseEntity.badRequest().body(
                AnswerValidationResponse.builder()
                    .message("エラー: " + e.getMessage())
                    .build()
            );
        } catch (Exception e) {
            logger.error("回答検証中にエラーが発生しました", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(
                AnswerValidationResponse.builder()
                    .message("回答検証に失敗しました: " + e.getMessage())
                    .build()
            );
        }
    }

    /**
     * 正解率を計算
     */
    private double calculateAccuracy(String userAnswer, String correctAnswer) {
        String[] userWords = userAnswer.toLowerCase().split("\\s+");
        String[] correctWords = correctAnswer.toLowerCase().split("\\s+");

        int matchCount = 0;
        for (int i = 0; i < Math.min(userWords.length, correctWords.length); i++) {
            if (userWords[i].equals(correctWords[i])) {
                matchCount++;
            }
        }

        return (double) matchCount / correctWords.length;
    }

    /**
     * ヘルスチェックエンドポイント
     */
    @GetMapping("/health")
    public ResponseEntity<String> health() {
        return ResponseEntity.ok("Question Generator Service is running");
    }
}
