package com.example.api.controller;

import com.example.api.dto.RankingDto;
import com.example.api.service.RankingService;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@RestController
@RequestMapping("/api/v1/rankings")
@RequiredArgsConstructor
@CrossOrigin
public class RankingController {

    private final RankingService rankingService;

    // ★追加: Rateテーブルに存在するシーズン一覧を取得
    @GetMapping("/seasons")
    public ResponseEntity<List<String>> getSeasons() {
        return ResponseEntity.ok(rankingService.getAvailableSeasons());
    }

    // シーズンランキング
    @GetMapping("/season")
    public ResponseEntity<RankingDto.SeasonResponse> getSeasonRanking(
            @RequestParam(defaultValue = "シーズン3") String season,
            @RequestParam(defaultValue = "50") int limit,
            @RequestParam Long userId,
            @RequestParam(defaultValue = "false") boolean friendsOnly
    ) {
        return ResponseEntity.ok(
            rankingService.getSeasonRanking(season, limit, userId, friendsOnly)
        );
    }

    // 週間ランキング
    @GetMapping("/weekly")
    public ResponseEntity<RankingDto.WeeklyResponse> getWeeklyRanking(
            @RequestParam(defaultValue = "50") int limit,
            @RequestParam Long userId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate weekStart,
            @RequestParam(defaultValue = "false") boolean friendsOnly
    ) {
        // weekStart引数は互換性のために残していますが、Service内では無視されweekFlagが優先されます
        LocalDateTime startDateTime = (weekStart != null) ? weekStart.atStartOfDay() : LocalDateTime.now();

        return ResponseEntity.ok(
            rankingService.getWeeklyRanking(startDateTime, limit, userId, friendsOnly)
        );
    }
}