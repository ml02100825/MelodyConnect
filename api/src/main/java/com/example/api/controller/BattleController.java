package com.example.api.controller;

import com.example.api.entity.Result;
import com.example.api.repository.ResultRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * バトルコントローラー
 * バトル開始とバトル情報の取得を提供します
 */
@RestController
@RequestMapping("/api/battle")
public class BattleController {

    @Autowired
    private ResultRepository resultRepository;

    /**
     * バトル開始エンドポイント
     * マッチング成立後、このエンドポイントでバトル情報を取得します
     *
     * @param matchId マッチID
     * @return バトル情報
     */
    @GetMapping("/start/{matchId}")
    public ResponseEntity<?> startBattle(@PathVariable String matchId) {
        try {
            // マッチIDに対応するResultレコードを取得（2件）
            List<Result> results = resultRepository.findAllByMatchUuid(matchId);

            if (results.isEmpty()) {
                return ResponseEntity.badRequest()
                        .body(createErrorResponse("マッチ情報が見つかりません"));
            }

            if (results.size() != 2) {
                return ResponseEntity.badRequest()
                        .body(createErrorResponse("マッチ情報が不正です"));
            }

            Result result1 = results.get(0);
            Result result2 = results.get(1);

            // バトル情報を返す
            Map<String, Object> battleInfo = new HashMap<>();
            battleInfo.put("matchId", matchId);
            battleInfo.put("user1Id", result1.getPlayer().getId());
            battleInfo.put("user2Id", result1.getEnemy().getId());
            battleInfo.put("language", result1.getUseLanguage());
            battleInfo.put("status", "ready");
            battleInfo.put("message", "バトルを開始できます");

            return ResponseEntity.ok(battleInfo);

        } catch (Exception e) {
            return ResponseEntity.status(500)
                    .body(createErrorResponse("バトル開始処理中にエラーが発生しました: " + e.getMessage()));
        }
    }

    /**
     * マッチ情報取得エンドポイント
     * 既存のマッチ情報を取得します
     *
     * @param matchId マッチID
     * @return マッチ情報
     */
    @GetMapping("/info/{matchId}")
    public ResponseEntity<?> getMatchInfo(@PathVariable String matchId) {
        try {
            List<Result> results = resultRepository.findAllByMatchUuid(matchId);

            if (results.isEmpty()) {
                return ResponseEntity.badRequest()
                        .body(createErrorResponse("マッチ情報が見つかりません"));
            }

            Result result = results.get(0);

            Map<String, Object> matchInfo = new HashMap<>();
            matchInfo.put("matchId", matchId);
            matchInfo.put("user1Id", result.getPlayer().getId());
            matchInfo.put("user2Id", result.getEnemy().getId());
            matchInfo.put("language", result.getUseLanguage());
            matchInfo.put("matchType", result.getMatchType());

            return ResponseEntity.ok(matchInfo);

        } catch (Exception e) {
            return ResponseEntity.status(500)
                    .body(createErrorResponse("マッチ情報取得中にエラーが発生しました: " + e.getMessage()));
        }
    }

    /**
     * エラーレスポンスを作成
     * @param message エラーメッセージ
     * @return エラーレスポンスマップ
     */
    private Map<String, String> createErrorResponse(String message) {
        Map<String, String> error = new HashMap<>();
        error.put("error", message);
        return error;
    }
}
