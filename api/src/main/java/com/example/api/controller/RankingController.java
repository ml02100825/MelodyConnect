package com.example.api.controller;

import com.example.api.dto.RankingDto;
import com.example.api.service.RankingService;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.time.LocalDateTime;

@RestController
@RequestMapping("/api/v1/rankings")
@RequiredArgsConstructor
@CrossOrigin // localhostでの開発用にCORSを許可
public class RankingController {

    private final RankingService rankingService;

    // シーズンランキング
    // URL: /api/v1/rankings/season?season=シーズン3&limit=50&userId=1&friendsOnly=false
    @GetMapping("/season")
    public ResponseEntity<RankingDto.SeasonResponse> getSeasonRanking(
            @RequestParam(defaultValue = "シーズン3") String season,
            @RequestParam(defaultValue = "50") int limit,
            @RequestParam Long userId, // Flutter側で渡しているパラメータ
            @RequestParam(defaultValue = "false") boolean friendsOnly
    ) {
        return ResponseEntity.ok(
            rankingService.getSeasonRanking(season, limit, userId, friendsOnly)
        );
    }

    // 週間ランキング
    // URL: /api/v1/rankings/weekly?limit=50&userId=1&weekStart=2024-01-01
    @GetMapping("/weekly")
    public ResponseEntity<RankingDto.WeeklyResponse> getWeeklyRanking(
            @RequestParam(defaultValue = "50") int limit,
            @RequestParam Long userId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate weekStart,
            @RequestParam(defaultValue = "false") boolean friendsOnly
    ) {
        // weekStartがnullの場合は、今週の始まり（例えば直近の日曜日など）を計算
        LocalDateTime startDateTime;
        if (weekStart != null) {
            startDateTime = weekStart.atStartOfDay();
        } else {
            // 指定がなければ今日を基準に週初め(日曜)を計算するなど
            LocalDateTime now = LocalDateTime.now();
            startDateTime = now.minusDays(now.getDayOfWeek().getValue() % 7).withHour(0).withMinute(0).withSecond(0);
        }

        return ResponseEntity.ok(
            rankingService.getWeeklyRanking(startDateTime, limit, userId, friendsOnly)
        );
    }
}