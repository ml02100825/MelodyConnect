package com.example.api.controller;

import com.example.api.dto.UserVocabularyResponse;
import com.example.api.entity.UserVocabulary;
import com.example.api.service.UserVocabularyService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * ユーザー単語帳API
 */
@RestController
@RequestMapping("/api/vocabulary")
public class UserVocabularyController {

    private static final Logger logger = LoggerFactory.getLogger(UserVocabularyController.class);

    @Autowired
    private UserVocabularyService userVocabularyService;

    /**
     * ユーザーの単語一覧を取得
     * GET /api/vocabulary/user/{userId}
     */
    @GetMapping("/user/{userId}")
    public ResponseEntity<UserVocabularyResponse> getUserVocabularies(@PathVariable Long userId) {
        logger.info("ユーザー単語一覧取得: userId={}", userId);

        try {
            List<UserVocabulary> userVocabularies = userVocabularyService.getUserVocabularies(userId);

            List<UserVocabularyResponse.VocabularyItem> items = userVocabularies.stream()
                .map(this::convertToVocabularyItem)
                .collect(Collectors.toList());

            UserVocabularyResponse response = UserVocabularyResponse.builder()
                .success(true)
                .totalCount(items.size())
                .vocabularies(items)
                .build();

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            logger.error("ユーザー単語一覧取得エラー: userId={}", userId, e);
            return ResponseEntity.ok(UserVocabularyResponse.builder()
                .success(false)
                .message("単語一覧の取得に失敗しました: " + e.getMessage())
                .build());
        }
    }

    /**
     * お気に入りフラグを更新
     * PUT /api/vocabulary/{userVocabId}/favorite
     */
    @PutMapping("/{userVocabId}/favorite")
    public ResponseEntity<Map<String, Object>> updateFavoriteFlag(
            @PathVariable Integer userVocabId,
            @RequestBody Map<String, Boolean> request) {
        
        logger.info("お気に入りフラグ更新: userVocabId={}, favorite={}", userVocabId, request.get("favorite"));

        try {
            Boolean favorite = request.get("favorite");
            if (favorite == null) {
                return ResponseEntity.badRequest().body(Map.of(
                    "success", false,
                    "message", "favoriteパラメータが必要です"
                ));
            }

            userVocabularyService.updateFavoriteFlag(userVocabId, favorite);

            return ResponseEntity.ok(Map.of(
                "success", true,
                "message", favorite ? "お気に入りに追加しました" : "お気に入りを解除しました"
            ));

        } catch (IllegalArgumentException e) {
            logger.warn("お気に入りフラグ更新エラー: userVocabId={}", userVocabId, e);
            return ResponseEntity.badRequest().body(Map.of(
                "success", false,
                "message", e.getMessage()
            ));
        } catch (Exception e) {
            logger.error("お気に入りフラグ更新エラー: userVocabId={}", userVocabId, e);
            return ResponseEntity.internalServerError().body(Map.of(
                "success", false,
                "message", "お気に入りフラグの更新に失敗しました"
            ));
        }
    }

    /**
     * 学習済みフラグを更新
     * PUT /api/vocabulary/{userVocabId}/learned
     */
    @PutMapping("/{userVocabId}/learned")
    public ResponseEntity<Map<String, Object>> updateLearnedFlag(
            @PathVariable Integer userVocabId,
            @RequestBody Map<String, Boolean> request) {
        
        logger.info("学習済みフラグ更新: userVocabId={}, learned={}", userVocabId, request.get("learned"));

        try {
            Boolean learned = request.get("learned");
            if (learned == null) {
                return ResponseEntity.badRequest().body(Map.of(
                    "success", false,
                    "message", "learnedパラメータが必要です"
                ));
            }

            userVocabularyService.updateLearnedFlag(userVocabId, learned);

            return ResponseEntity.ok(Map.of(
                "success", true,
                "message", learned ? "学習済みに設定しました" : "学習済みを解除しました"
            ));

        } catch (IllegalArgumentException e) {
            logger.warn("学習済みフラグ更新エラー: userVocabId={}", userVocabId, e);
            return ResponseEntity.badRequest().body(Map.of(
                "success", false,
                "message", e.getMessage()
            ));
        } catch (Exception e) {
            logger.error("学習済みフラグ更新エラー: userVocabId={}", userVocabId, e);
            return ResponseEntity.internalServerError().body(Map.of(
                "success", false,
                "message", "学習済みフラグの更新に失敗しました"
            ));
        }
    }

    /**
     * UserVocabularyエンティティをDTOに変換
     */
    private UserVocabularyResponse.VocabularyItem convertToVocabularyItem(UserVocabulary uv) {
        var vocab = uv.getVocabulary();
        
        return UserVocabularyResponse.VocabularyItem.builder()
            .userVocabId(uv.getUserVocabId())
            .vocabId(vocab.getVocab_id())
            .word(vocab.getWord())
            .baseForm(vocab.getBase_form())           // ★追加: 原形
            .translationJa(vocab.getTranslation_ja()) // ★追加: 簡潔訳
            .meaningJa(vocab.getMeaning_ja())
            .pronunciation(vocab.getPronunciation())
            .partOfSpeech(vocab.getPart_of_speech())
            .exampleSentence(vocab.getExample_sentence())
            .exampleTranslation(vocab.getExample_translate())
            .audioUrl(vocab.getAudio_url())
            .language(vocab.getLanguage())
            .isFavorite(uv.getFavoriteFlag())
            .isLearned(uv.getLearnedWordFlag())
            .firstLearnedAt(uv.getFirstLearnedAt())
            .build();
    }
}