package com.example.api.controller;

import com.example.api.dto.BadgeDto;
import com.example.api.service.BadgeService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/badges")
@RequiredArgsConstructor
@CrossOrigin
public class BadgeController {

    private final BadgeService badgeService;

    @GetMapping
    public ResponseEntity<List<BadgeDto>> getBadges(
            @RequestParam Long userId,
            // ★追加: フロントから送られてくる mode パラメータを受け取る (無い場合は "all")
            @RequestParam(required = false, defaultValue = "all") String mode
    ) {
        // Serviceに userId と mode の両方を渡す
        return ResponseEntity.ok(badgeService.getUserBadges(userId, mode));
    }
}