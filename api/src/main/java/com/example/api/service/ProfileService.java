package com.example.api.service;

import com.example.api.dto.ProfileUpdateRequest;
import com.example.api.entity.User;
import com.example.api.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Optional;

@Service
public class ProfileService {

    @Autowired
    private UserRepository userRepository;

    @Transactional
    public User updateProfile(Long userId, ProfileUpdateRequest request) {
        User user = getUserOrThrow(userId);

        if (request.getUserUuid() != null && !request.getUserUuid().equals(user.getUserUuid())) {
            Optional<User> existing = userRepository.findByUserUuid(request.getUserUuid());
            if (existing.isPresent()) {
                throw new IllegalArgumentException("このIDは既に使用されています");
            }
            user.setUserUuid(request.getUserUuid());
        }

        user.setUsername(request.getUsername());
        if (request.getImageUrl() != null && !request.getImageUrl().isEmpty()) {
            user.setImageUrl(request.getImageUrl());
        }

        return userRepository.save(user);
    }

    // 音量更新メソッドは削除しました

    @Transactional
    public void updatePrivacy(Long userId, int privacy) {
        User user = getUserOrThrow(userId);
        user.setPrivacy(privacy);
        userRepository.save(user);
    }

    public User getUserProfile(Long userId) {
        return getUserOrThrow(userId);
    }

    private User getUserOrThrow(Long userId) {
        return userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("ユーザーが見つかりません: ID=" + userId));
    }
}