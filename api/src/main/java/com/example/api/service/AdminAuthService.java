package com.example.api.service;

import com.example.api.dto.admin.AdminLoginRequest;
import com.example.api.dto.admin.AdminLoginResponse;
import com.example.api.entity.Admin;
import com.example.api.repository.AdminRepository;
import com.example.api.util.JwtUtil;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;

/**
 * 管理者認証サービス
 * 管理者のログイン、トークンリフレッシュを行います
 */
@Service
public class AdminAuthService {

    private static final Logger logger = LoggerFactory.getLogger(AdminAuthService.class);

    @Autowired
    private AdminRepository adminRepository;

    @Autowired
    private JwtUtil jwtUtil;

    private final BCryptPasswordEncoder passwordEncoder = new BCryptPasswordEncoder();

    /**
     * 管理者ログイン（メールアドレスで認証）
     * @param request ログインリクエスト
     * @return ログインレスポンス
     */
    public AdminLoginResponse login(AdminLoginRequest request) {
        logger.debug("管理者ログイン試行: email={}", request.getEmail());

        // メールアドレスで管理者を検索
        Admin admin = adminRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> {
                    logger.warn("管理者が見つかりません: email={}", request.getEmail());
                    return new IllegalArgumentException("メールアドレスまたはパスワードが正しくありません");
                });

        // パスワード検証
        if (!passwordEncoder.matches(request.getPassword(), admin.getPassword())) {
            logger.warn("パスワードが一致しません: email={}", request.getEmail());
            throw new IllegalArgumentException("メールアドレスまたはパスワードが正しくありません");
        }

        // トークン生成
        String accessToken = jwtUtil.generateAdminAccessToken(admin.getAdmin_id());
        String refreshToken = jwtUtil.generateAdminRefreshToken(admin.getAdmin_id());

        logger.info("管理者ログイン成功: adminId={}, email={}", admin.getAdmin_id(), admin.getEmail());

        return new AdminLoginResponse(
                admin.getAdmin_id(),
                admin.getEmail(),
                accessToken,
                refreshToken,
                jwtUtil.getAccessTokenExpiration()
        );
    }

    /**
     * 管理者トークンリフレッシュ
     * @param refreshToken リフレッシュトークン
     * @return 新しいログインレスポンス
     */
    public AdminLoginResponse refreshToken(String refreshToken) {
        logger.debug("管理者トークンリフレッシュ試行");

        // トークン検証
        if (!jwtUtil.validateToken(refreshToken)) {
            logger.warn("無効なリフレッシュトークン");
            throw new IllegalArgumentException("無効なリフレッシュトークンです");
        }

        // トークンタイプ確認
        String tokenType = jwtUtil.getTokenType(refreshToken);
        if (!"refresh".equals(tokenType)) {
            logger.warn("トークンタイプが不正: type={}", tokenType);
            throw new IllegalArgumentException("リフレッシュトークンではありません");
        }

        // ロール確認
        String role = jwtUtil.getRoleFromToken(refreshToken);
        if (!"ADMIN".equals(role)) {
            logger.warn("管理者トークンではありません: role={}", role);
            throw new IllegalArgumentException("管理者トークンではありません");
        }

        // 管理者ID取得
        Long adminId = jwtUtil.getUserIdFromToken(refreshToken);

        // 管理者存在確認
        Admin admin = adminRepository.findByAdmin_id(adminId)
                .orElseThrow(() -> {
                    logger.warn("管理者が見つかりません: adminId={}", adminId);
                    return new IllegalArgumentException("管理者が見つかりません");
                });

        // 新しいトークン生成
        String newAccessToken = jwtUtil.generateAdminAccessToken(admin.getAdmin_id());
        String newRefreshToken = jwtUtil.generateAdminRefreshToken(admin.getAdmin_id());

        logger.info("管理者トークンリフレッシュ成功: adminId={}", admin.getAdmin_id());

        return new AdminLoginResponse(
                admin.getAdmin_id(),
                admin.getEmail(),
                newAccessToken,
                newRefreshToken,
                jwtUtil.getAccessTokenExpiration()
        );
    }
}
