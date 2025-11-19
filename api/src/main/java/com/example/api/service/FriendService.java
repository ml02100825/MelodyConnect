package com.example.api.service;

import com.example.api.dto.*;
import com.example.api.entity.*;
import com.example.api.repository.*;
import com.example.api.util.SeasonCalculator;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

/**
 * フレンドサービスクラス
 * フレンド機能のビジネスロジックを提供します
 */
@Service
public class FriendService {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private FriendRepository friendRepository;

    @Autowired
    private RateRepository rateRepository;

    @Autowired
    private GotBadgeRepository gotBadgeRepository;

    @Autowired
    private SeasonCalculator seasonCalculator;

    @Autowired
    private SimpMessagingTemplate messagingTemplate;

    /**
     * UUIDでユーザーを検索
     * @param userUuid ユーザーUUID
     * @return ユーザー検索結果
     * @throws IllegalArgumentException ユーザーが見つからない場合
     */
    @Transactional(readOnly = true)
    public UserSearchResponse searchUserByUuid(String userUuid) {
        User user = userRepository.findByUserUuid(userUuid)
                .orElseThrow(() -> new IllegalArgumentException("ユーザーが見つかりません"));

        return new UserSearchResponse(
                user.getId(),
                user.getUsername(),
                user.getUserUuid(),
                user.getImageUrl()
        );
    }

    /**
     * フレンド申請を送信
     * @param requesterId 申請者ID
     * @param targetUserUuid 対象ユーザーUUID
     * @throws IllegalArgumentException 無効な申請の場合
     */
    @Transactional
    public void sendFriendRequest(Long requesterId, String targetUserUuid) {
        User requester = userRepository.findById(requesterId)
                .orElseThrow(() -> new IllegalArgumentException("申請者が見つかりません"));

        User target = userRepository.findByUserUuid(targetUserUuid)
                .orElseThrow(() -> new IllegalArgumentException("対象ユーザーが見つかりません"));

        // 自分自身には申請できない
        if (requester.getId().equals(target.getId())) {
            throw new IllegalArgumentException("自分自身にフレンド申請はできません");
        }

        // ID順でユーザーを決定（重複防止のため）
        User userLow, userHigh;
        if (requester.getId() < target.getId()) {
            userLow = requester;
            userHigh = target;
        } else {
            userLow = target;
            userHigh = requester;
        }

        // 既存の関係をチェック
        Optional<Friend> existingFriend = friendRepository.findByUserLowAndUserHigh(userLow, userHigh);
        if (existingFriend.isPresent()) {
            Friend friend = existingFriend.get();
            if (friend.getFriendFlag()) {
                throw new IllegalArgumentException("既にフレンドです");
            }
            if (friend.getInviteFlag()) {
                throw new IllegalArgumentException("既にフレンド申請が送信されています");
            }
        }

        // フレンド申請を作成
        Friend friendRequest = new Friend();
        friendRequest.setUserLow(userLow);
        friendRequest.setUserHigh(userHigh);
        friendRequest.setRequester(requester);
        friendRequest.setInviteFlag(true);
        friendRequest.setFriendFlag(false);
        friendRepository.save(friendRequest);

        // WebSocket通知を送信
        sendFriendRequestNotification(target.getId(), requester);
    }

    /**
     * フレンド申請を承認
     * @param userId 承認者ID
     * @param friendId フレンドレコードID
     * @throws IllegalArgumentException 無効な操作の場合
     */
    @Transactional
    public void acceptFriendRequest(Long userId, Long friendId) {
        Friend friend = friendRepository.findById(friendId)
                .orElseThrow(() -> new IllegalArgumentException("フレンド申請が見つかりません"));

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("ユーザーが見つかりません"));

        // 自分宛ての申請かチェック
        boolean isRecipient = (friend.getUserLow().getId().equals(userId) || friend.getUserHigh().getId().equals(userId))
                && !friend.getRequester().getId().equals(userId);

        if (!isRecipient) {
            throw new IllegalArgumentException("この申請を承認する権限がありません");
        }

        if (friend.getFriendFlag()) {
            throw new IllegalArgumentException("既にフレンドです");
        }

        if (!friend.getInviteFlag()) {
            throw new IllegalArgumentException("有効なフレンド申請ではありません");
        }

        // フレンド承認
        friend.setFriendFlag(true);
        friend.setAcceptedAt(LocalDateTime.now());
        friendRepository.save(friend);
    }

    /**
     * フレンド申請を拒否
     * @param userId 拒否者ID
     * @param friendId フレンドレコードID
     * @throws IllegalArgumentException 無効な操作の場合
     */
    @Transactional
    public void rejectFriendRequest(Long userId, Long friendId) {
        Friend friend = friendRepository.findById(friendId)
                .orElseThrow(() -> new IllegalArgumentException("フレンド申請が見つかりません"));

        // 自分宛ての申請かチェック
        boolean isRecipient = (friend.getUserLow().getId().equals(userId) || friend.getUserHigh().getId().equals(userId))
                && !friend.getRequester().getId().equals(userId);

        if (!isRecipient) {
            throw new IllegalArgumentException("この申請を拒否する権限がありません");
        }

        // レコードを削除
        friendRepository.delete(friend);
    }

    /**
     * フレンド一覧を取得
     * @param userId ユーザーID
     * @return フレンド一覧
     */
    @Transactional(readOnly = true)
    public List<FriendResponse> getFriendList(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("ユーザーが見つかりません"));

        List<Friend> friends = friendRepository.findFriendsByUser(user);

        return friends.stream().map(friend -> {
            // 自分以外のユーザーを取得
            User friendUser = friend.getUserLow().getId().equals(userId)
                    ? friend.getUserHigh()
                    : friend.getUserLow();

            return new FriendResponse(
                    friend.getId(),
                    friendUser.getId(),
                    friendUser.getUsername(),
                    friendUser.getUserUuid(),
                    friendUser.getImageUrl(),
                    friend.getAcceptedAt()
            );
        }).collect(Collectors.toList());
    }

    /**
     * 受信したフレンド申請一覧を取得
     * @param userId ユーザーID
     * @return フレンド申請一覧
     */
    @Transactional(readOnly = true)
    public List<FriendRequestResponse> getPendingRequests(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("ユーザーが見つかりません"));

        List<Friend> requests = friendRepository.findPendingRequestsForUser(user);

        return requests.stream().map(request -> {
            User requester = request.getRequester();
            return new FriendRequestResponse(
                    request.getId(),
                    requester.getId(),
                    requester.getUsername(),
                    requester.getUserUuid(),
                    requester.getImageUrl(),
                    request.getRequestedAt()
            );
        }).collect(Collectors.toList());
    }

    /**
     * フレンドのプロフィール詳細を取得
     * @param userId リクエストユーザーID
     * @param friendUserId フレンドユーザーID
     * @return フレンドプロフィール
     * @throws IllegalArgumentException フレンドでない場合
     */
    @Transactional(readOnly = true)
    public FriendProfileResponse getFriendProfile(Long userId, Long friendUserId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("ユーザーが見つかりません"));

        User friendUser = userRepository.findById(friendUserId)
                .orElseThrow(() -> new IllegalArgumentException("フレンドが見つかりません"));

        // フレンドかどうか確認
        User userLow, userHigh;
        if (user.getId() < friendUser.getId()) {
            userLow = user;
            userHigh = friendUser;
        } else {
            userLow = friendUser;
            userHigh = user;
        }

        Optional<Friend> friendRelation = friendRepository.findByUserLowAndUserHigh(userLow, userHigh);
        if (friendRelation.isEmpty() || !friendRelation.get().getFriendFlag()) {
            throw new IllegalArgumentException("フレンドではありません");
        }

        // 現在のシーズンのレートを取得
        Integer currentSeason = seasonCalculator.getCurrentSeason();
        Integer rate = rateRepository.findByUserAndSeason(friendUser, currentSeason)
                .map(Rate::getRate)
                .orElse(null);

        // バッジ情報を取得
        List<GotBadge> gotBadges = gotBadgeRepository.findByUser(friendUser);
        List<BadgeResponse> badges = gotBadges.stream().map(gotBadge -> {
            Badge badge = gotBadge.getBadge();
            return new BadgeResponse(
                    badge.getId(),
                    badge.getBadgeName(),
                    badge.getAcquisitionCondition(),
                    badge.getImageUrl(),
                    gotBadge.getAcquired_at()
            );
        }).collect(Collectors.toList());

        return new FriendProfileResponse(
                friendUser.getId(),
                friendUser.getUsername(),
                friendUser.getUserUuid(),
                friendUser.getImageUrl(),
                friendUser.getTotalPlay(),
                rate,
                badges
        );
    }

    /**
     * WebSocketでフレンド申請通知を送信
     * @param targetUserId 通知先ユーザーID
     * @param requester 申請者
     */
    private void sendFriendRequestNotification(Long targetUserId, User requester) {
        Map<String, Object> notification = new HashMap<>();
        notification.put("type", "friend_request");
        notification.put("requesterId", requester.getId());
        notification.put("requesterUsername", requester.getUsername());
        notification.put("requesterUserUuid", requester.getUserUuid());
        notification.put("requesterImageUrl", requester.getImageUrl());
        notification.put("timestamp", LocalDateTime.now().toString());

        messagingTemplate.convertAndSend(
                "/topic/friend/" + targetUserId,
                notification
        );
    }
}
