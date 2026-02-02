package com.example.api.service;

import com.example.api.dto.ProfileUpdateRequest;
import com.example.api.entity.User;
import com.example.api.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.util.Optional;

/**
 * プロフィールサービスクラス
 * ユーザープロフィール（ユーザー名、アイコン）の更新を提供します
 */
@Service
public class ProfileService {

    @Autowired
    private UserRepository userRepository;
    @Autowired
    private ImageUploadService imageUploadService;

    /**
     * プロフィール更新（ステップ2: ユーザー名、アイコン、ユーザーID設定）
     * @param userId ユーザーID
     * @param request プロフィール更新リクエスト
     * @return 更新されたユーザー
     * @throws IllegalArgumentException ユーザーが見つからない場合、またはユーザーIDが重複している場合
     */
    @Transactional
public User updateProfileMultipart(Long userId, String username, String userUuid, MultipartFile icon) throws Exception {
    User user = userRepository.findById(userId)
        .orElseThrow(() -> new IllegalArgumentException("ユーザーが見つかりません"));

    if (userUuid != null && !userUuid.isEmpty()) {
        Optional<User> existingUser = userRepository.findByUserUuid(userUuid);
        if (existingUser.isPresent() && !existingUser.get().getId().equals(userId)) {
            throw new IllegalArgumentException("このユーザーIDは既に使用されています");
        }
        user.setUserUuid(userUuid);
    }

    user.setUsername(username);

    if (icon != null && !icon.isEmpty()) {
        String imageUrl = imageUploadService.uploadImage(icon);
        user.setImageUrl(imageUrl);
    }
    // icon が無い場合は imageUrl を変えない（デフォルト表示のまま）

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
