package com.example.api.controller;

import com.example.api.dto.SeasonRankingResponse;
import com.example.api.dto.WeeklyRankingResponse;
import com.example.api.service.RankingService;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/rankings")
public class RankingController {
    private final RankingService rankingService;

    public RankingController(RankingService rankingService) {
        this.rankingService = rankingService;
    }

    @GetMapping("/season")
    public SeasonRankingResponse getSeasonRanking(
            @RequestParam(name = "season") String season,
            @RequestParam(name = "limit", defaultValue = "30") int limit,
            @RequestParam(name = "userId", required = false) Long userId,
            @RequestParam(name = "friendsOnly", defaultValue = "false") boolean friendsOnly
    ) {
        return rankingService.getSeasonRanking(season, limit, userId, friendsOnly);
    }

    @GetMapping("/weekly")
    public WeeklyRankingResponse getWeeklyRanking(
            @RequestParam(name = "weekFlag", required = false) Integer weekFlag,
            @RequestParam(name = "limit", defaultValue = "30") int limit,
            @RequestParam(name = "userId", required = false) Long userId,
            @RequestParam(name = "friendsOnly", defaultValue = "false") boolean friendsOnly
    ) {
        return rankingService.getWeeklyRanking(weekFlag, limit, userId, friendsOnly);
    }
}