package com.example.api.controller;

import com.example.api.dto.*;
import com.example.api.service.FriendService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * フレンドコントローラー
 * フレンド機能のエンドポイントを提供します
 */
@RestController
@RequestMapping("/api/friend")
public class FriendController {

    @Autowired
    private FriendService friendService;

    /**
     * UUIDでユーザーを検索
     * @param userUuid ユーザーUUID
     * @return ユーザー検索結果
     */
    @GetMapping("/search/{userUuid}")
    public ResponseEntity<?> searchUser(@PathVariable String userUuid) {
        try {
            UserSearchResponse response = friendService.searchUserByUuid(userUuid);
            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(createErrorResponse(e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(createErrorResponse("ユーザー検索中にエラーが発生しました"));
        }
    }

    /**
     * フレンド申請を送信
     * @param userId 申請者ID
     * @param request 申請リクエスト
     * @return 成功メッセージ
     */
    @PostMapping("/{userId}/request")
    public ResponseEntity<?> sendFriendRequest(@PathVariable Long userId,
                                                @Valid @RequestBody FriendRequestDto request) {
        try {
            friendService.sendFriendRequest(userId, request.getTargetUserUuid());
            Map<String, String> response = new HashMap<>();
            response.put("message", "フレンド申請を送信しました");
            return ResponseEntity.status(HttpStatus.CREATED).body(response);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest()
                    .body(createErrorResponse(e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(createErrorResponse("フレンド申請送信中にエラーが発生しました"));
        }
    }

    /**
     * フレンド申請を承認
     * @param userId ユーザーID
     * @param friendId フレンドレコードID
     * @return 成功メッセージ
     */
    @PostMapping("/{userId}/accept/{friendId}")
    public ResponseEntity<?> acceptFriendRequest(@PathVariable Long userId,
                                                  @PathVariable Long friendId) {
        try {
            friendService.acceptFriendRequest(userId, friendId);
            Map<String, String> response = new HashMap<>();
            response.put("message", "フレンド申請を承認しました");
            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest()
                    .body(createErrorResponse(e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(createErrorResponse("フレンド申請承認中にエラーが発生しました"));
        }
    }

    /**
     * フレンド申請を拒否
     * @param userId ユーザーID
     * @param friendId フレンドレコードID
     * @return 成功メッセージ
     */
    @PostMapping("/{userId}/reject/{friendId}")
    public ResponseEntity<?> rejectFriendRequest(@PathVariable Long userId,
                                                  @PathVariable Long friendId) {
        try {
            friendService.rejectFriendRequest(userId, friendId);
            Map<String, String> response = new HashMap<>();
            response.put("message", "フレンド申請を拒否しました");
            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest()
                    .body(createErrorResponse(e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(createErrorResponse("フレンド申請拒否中にエラーが発生しました"));
        }
    }

    /**
     * フレンド一覧を取得
     * @param userId ユーザーID
     * @return フレンド一覧
     */
    @GetMapping("/{userId}/list")
    public ResponseEntity<?> getFriendList(@PathVariable Long userId) {
        try {
            List<FriendResponse> friends = friendService.getFriendList(userId);
            return ResponseEntity.ok(friends);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest()
                    .body(createErrorResponse(e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(createErrorResponse("フレンド一覧取得中にエラーが発生しました"));
        }
    }

    /**
     * 受信したフレンド申請一覧を取得
     * @param userId ユーザーID
     * @return フレンド申請一覧
     */
    @GetMapping("/{userId}/requests")
    public ResponseEntity<?> getPendingRequests(@PathVariable Long userId) {
        try {
            List<FriendRequestResponse> requests = friendService.getPendingRequests(userId);
            return ResponseEntity.ok(requests);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest()
                    .body(createErrorResponse(e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(createErrorResponse("フレンド申請一覧取得中にエラーが発生しました"));
        }
    }

    /**
     * フレンドのプロフィール詳細を取得
     * @param userId ユーザーID
     * @param friendUserId フレンドユーザーID
     * @return フレンドプロフィール
     */
    @GetMapping("/{userId}/profile/{friendUserId}")
    public ResponseEntity<?> getFriendProfile(@PathVariable Long userId,
                                               @PathVariable Long friendUserId) {
        try {
            FriendProfileResponse profile = friendService.getFriendProfile(userId, friendUserId);
            return ResponseEntity.ok(profile);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest()
                    .body(createErrorResponse(e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(createErrorResponse("プロフィール取得中にエラーが発生しました"));
        }
    }

    /**
     * フレンドを削除
     * @param userId ユーザーID
     * @param friendId フレンドレコードID
     * @return 成功メッセージ
     */
    @DeleteMapping("/{userId}/delete/{friendId}")
    public ResponseEntity<?> deleteFriend(@PathVariable Long userId,
                                           @PathVariable Long friendId) {
        try {
            friendService.deleteFriend(userId, friendId);
            Map<String, String> response = new HashMap<>();
            response.put("message", "フレンドを削除しました");
            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest()
                    .body(createErrorResponse(e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(createErrorResponse("フレンド削除中にエラーが発生しました"));
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
