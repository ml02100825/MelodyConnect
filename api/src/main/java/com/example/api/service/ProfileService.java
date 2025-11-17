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
     * プロフィール更新（ステップ2: ユーザー名、アイコン、ユーザーID設定）
     * @param userId ユーザーID
     * @param request プロフィール更新リクエスト
     * @return 更新されたユーザー
     * @throws IllegalArgumentException ユーザーが見つからない場合、またはユーザーIDが重複している場合
     */
    @Transactional
    public User updateProfile(Long userId, ProfileUpdateRequest request) {
        // ユーザーを検索
        Optional<User> userOpt = userRepository.findById(userId);
        if (userOpt.isEmpty()) {
            throw new IllegalArgumentException("ユーザーが見つかりません");
        }

        User user = userOpt.get();

        // ユーザーUUIDの重複チェック（自分以外のユーザーで同じユーザーUUIDが存在するか）
        if (request.getUserUuid() != null && !request.getUserUuid().isEmpty()) {
            Optional<User> existingUser = userRepository.findByUserUuid(request.getUserUuid());
            if (existingUser.isPresent() && !existingUser.get().getId().equals(userId)) {
                throw new IllegalArgumentException("このユーザーIDは既に使用されています");
            }
            user.setUserUuid(request.getUserUuid());
        }

        // プロフィールを更新（ユーザー名は重複可能）
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
