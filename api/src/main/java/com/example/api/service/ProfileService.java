package com.example.api.service;

import com.example.api.dto.PrivacyUpdateRequest;
import com.example.api.dto.ProfileUpdateRequest;
import com.example.api.entity.User;
import com.example.api.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Optional;

/**
 * プロフィールサービス
 * ユーザー情報の更新（プロフィール、音量、プライバシー）を担当します
 */
@Service
public class ProfileService {

    @Autowired
    private UserRepository userRepository;

    /**
     * プロフィール基本情報の更新
     */
    @Transactional
    public User updateProfile(Long userId, ProfileUpdateRequest request) {
        User user = getUserOrThrow(userId);

        // ユーザーID(UUID)が変更されている場合、重複チェックを行う
        if (request.getUserUuid() != null && !request.getUserUuid().equals(user.getUserUuid())) {
            Optional<User> existingUser = userRepository.findByUserUuid(request.getUserUuid());
            if (existingUser.isPresent()) {
                throw new IllegalArgumentException("このユーザーIDは既に使用されています");
            }
            user.setUserUuid(request.getUserUuid());
        }

        user.setUsername(request.getUsername());
        
        // 画像URLは空文字が送られてきた場合も更新（削除）を許容する場合の処理
        if (request.getImageUrl() != null) {
            user.setImageUrl(request.getImageUrl());
        }

        return userRepository.save(user);
    }

    /**
     * 音量設定の更新
     */
    @Transactional
    public void updateVolume(Long userId, int newVolume) {
        User user = getUserOrThrow(userId);
        user.setVolume(newVolume);
        userRepository.save(user);
    }

    /**
     * プライバシー設定の更新
     */
    @Transactional
    public void updatePrivacy(Long userId, PrivacyUpdateRequest request) {
        User user = getUserOrThrow(userId);
        user.setPrivacy(request.getPrivacy());
        userRepository.save(user);
    }

    /**
     * ユーザー情報の取得
     */
    public User getUserProfile(Long userId) {
        return getUserOrThrow(userId);
    }

    // 共通のユーザー検索メソッド
    private User getUserOrThrow(Long userId) {
        return userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("ユーザーが見つかりません: ID=" + userId));
    }
}