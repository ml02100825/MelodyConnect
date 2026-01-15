package com.example.api.controller;

import com.example.api.dto.ReportRequest;
import com.example.api.dto.ReportResponse;
import com.example.api.service.ReportService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

/**
 * 通報コントローラー
 * Vocabulary/Question の通報機能を提供
 */
@RestController
@RequestMapping("/api/reports")
public class ReportController {

    private static final Logger logger = LoggerFactory.getLogger(ReportController.class);

    @Autowired
    private ReportService reportService;

    /**
     * 通報を作成
     * POST /api/reports
     */
    @PostMapping
    public ResponseEntity<ReportResponse> createReport(@RequestBody ReportRequest request) {
        logger.info("通報リクエスト受信: type={}, targetId={}, userId={}",
            request.getReportType(), request.getTargetId(), request.getUserId());

        try {
            ReportResponse response = reportService.createReport(request);

            if (response.getSuccess()) {
                return ResponseEntity.ok(response);
            } else {
                return ResponseEntity.badRequest().body(response);
            }

        } catch (Exception e) {
            logger.error("通報処理中にエラーが発生しました", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(
                ReportResponse.builder()
                    .success(false)
                    .message("通報の処理に失敗しました: " + e.getMessage())
                    .build()
            );
        }
    }

    /**
     * ヘルスチェック
     */
    @GetMapping("/health")
    public ResponseEntity<String> health() {
        return ResponseEntity.ok("Report Service is running");
    }
}
