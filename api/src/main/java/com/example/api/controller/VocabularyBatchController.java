package com.example.api.controller;

import com.example.api.service.VocabularyBatchService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * Vocabularyバッチ更新コントローラ
 * 既存の単語データにbase_formとtranslation_jaを追加するAPI
 */
@RestController
@RequestMapping("/api/dev/vocabulary-batch")
public class VocabularyBatchController {

    private static final Logger logger = LoggerFactory.getLogger(VocabularyBatchController.class);

    @Autowired
    private VocabularyBatchService vocabularyBatchService;

    /**
     * バッチ更新のステータスを取得
     * GET /api/dev/vocabulary-batch/status
     */
    @GetMapping("/status")
    public ResponseEntity<Map<String, Object>> getStatus() {
        long total = vocabularyBatchService.countAll();
        long needsUpdate = vocabularyBatchService.countMissingFields();
        long completed = total - needsUpdate;
        
        double percentage = total > 0 ? (double) completed / total * 100 : 100;

        return ResponseEntity.ok(Map.of(
            "total", total,
            "needsUpdate", needsUpdate,
            "completed", completed,
            "percentage", String.format("%.1f%%", percentage)
        ));
    }

    /**
     * base_formまたはtranslation_jaがnullの単語を更新
     * POST /api/dev/vocabulary-batch/update
     * 
     * @param limit 一度に処理する最大件数（デフォルト: 10）
     */
    @PostMapping("/update")
    public ResponseEntity<Map<String, Object>> updateMissingFields(
            @RequestParam(defaultValue = "10") int limit) {
        
        logger.info("バッチ更新リクエスト: limit={}", limit);
        
        if (limit < 1 || limit > 100) {
            return ResponseEntity.badRequest().body(Map.of(
                "success", false,
                "message", "limitは1〜100の範囲で指定してください"
            ));
        }

        try {
            int updated = vocabularyBatchService.updateMissingFields(limit);
            long remaining = vocabularyBatchService.countMissingFields();

            return ResponseEntity.ok(Map.of(
                "success", true,
                "updated", updated,
                "remaining", remaining,
                "message", updated + "件の単語を更新しました。残り" + remaining + "件"
            ));

        } catch (Exception e) {
            logger.error("バッチ更新エラー", e);
            return ResponseEntity.internalServerError().body(Map.of(
                "success", false,
                "message", "バッチ更新に失敗しました: " + e.getMessage()
            ));
        }
    }

    /**
     * 全ての単語を強制的に更新（base_form, translation_jaを再生成）
     * POST /api/dev/vocabulary-batch/force-update
     * 
     * ⚠️ 注意: API呼び出し回数が多くなるため、少量ずつ実行してください
     * 
     * @param limit 一度に処理する最大件数（デフォルト: 5）
     */
    @PostMapping("/force-update")
    public ResponseEntity<Map<String, Object>> forceUpdate(
            @RequestParam(defaultValue = "5") int limit) {
        
        logger.info("強制バッチ更新リクエスト: limit={}", limit);
        
        if (limit < 1 || limit > 50) {
            return ResponseEntity.badRequest().body(Map.of(
                "success", false,
                "message", "limitは1〜50の範囲で指定してください"
            ));
        }

        try {
            int updated = vocabularyBatchService.forceUpdateAll(limit);

            return ResponseEntity.ok(Map.of(
                "success", true,
                "updated", updated,
                "message", updated + "件の単語を強制更新しました"
            ));

        } catch (Exception e) {
            logger.error("強制バッチ更新エラー", e);
            return ResponseEntity.internalServerError().body(Map.of(
                "success", false,
                "message", "強制バッチ更新に失敗しました: " + e.getMessage()
            ));
        }
    }
}
