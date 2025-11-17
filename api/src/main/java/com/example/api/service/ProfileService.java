package com.example.api.service;

import com.example.api.dto.ProfileUpdateRequest;
import com.example.api.entity.User;
import com.example.api.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Optional;

/**
 * プロフィールサービスクラス
 * ユーザープロフィール（ユーザー名、アイコン）の更新を提供します
 */
@Service
public class ProfileService {

    @Autowired
    private UserRepository userRepository;

    /**
     * プロフィール更新（ステップ2: ユーザー名とアイコン設定）
     * @param userId ユーザーID
     * @param request プロフィール更新リクエスト
     * @return 更新されたユーザー
     * @throws IllegalArgumentException ユーザーが見つからない、またはユーザー名が重複している場合
     */
    @Transactional
    public User updateProfile(Long userId, ProfileUpdateRequest request) {
        // ユーザーを検索
        Optional<User> userOpt = userRepository.findById(userId);
        if (userOpt.isEmpty()) {
            throw new IllegalArgumentException("ユーザーが見つかりません");
        }

        User user = userOpt.get();


        // プロフィールを更新
        user.setUsername(request.getUsername());
        if (request.getImageUrl() != null && !request.getImageUrl().isEmpty()) {
            user.setImageUrl(request.getImageUrl());
        }

        return userRepository.save(user);
    }

    /**
     * ユーザー情報を取得
     * @param userId ユーザーID
     * @return ユーザー
     * @throws IllegalArgumentException ユーザーが見つからない場合
     */
    public User getUserProfile(Long userId) {
        return userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("ユーザーが見つかりません"));
    }
}
