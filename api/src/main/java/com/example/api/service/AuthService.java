package com.example.api.service;

import com.example.api.dto.AuthResponse;
import com.example.api.dto.LoginRequest;
import com.example.api.dto.RegisterRequest;
import com.example.api.entity.Rate;
import com.example.api.entity.Session;
import com.example.api.entity.User;
import com.example.api.entity.WeeklyLessons;
import com.example.api.repository.RateRepository;
import com.example.api.repository.SessionRepository;
import com.example.api.repository.UserRepository;
import com.example.api.repository.WeeklyLessonsRepository;
import com.example.api.util.JwtUtil;
import com.example.api.util.SeasonCalculator;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.LocalDateTime;
import java.util.Optional;

/**
 * 認証サービスクラス
 * ユーザー登録、ログイン、セッション管理のビジネスロジックを提供します
 */
@Service
public class AuthService {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private SessionRepository sessionRepository;

    @Autowired
    private RateRepository rateRepository;

    @Autowired
    private WeeklyLessonsRepository weeklyLessonsRepository;

    @Autowired
    private JwtUtil jwtUtil;

    @Autowired
    private SeasonCalculator seasonCalculator;

    private final BCryptPasswordEncoder passwordEncoder = new BCryptPasswordEncoder();

    /**
     * SHA-256でハッシュ化
     * リフレッシュトークンのハッシュ化に使用（BCryptの72バイト制限を回避）
     * @param input ハッシュ化する文字列
     * @return SHA-256ハッシュ（16進数文字列）
     */
    private String hashWithSHA256(String input) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(input.getBytes(StandardCharsets.UTF_8));
            StringBuilder hexString = new StringBuilder();
            for (byte b : hash) {
                String hex = Integer.toHexString(0xff & b);
                if (hex.length() == 1) hexString.append('0');
                hexString.append(hex);
            }
            return hexString.toString();
        } catch (NoSuchAlgorithmException e) {
            throw new RuntimeException("SHA-256アルゴリズムが見つかりません", e);
        }
    }

    /**
     * ユーザー登録（ステップ1: メールアドレスとパスワードのみ）
     * 登録後、プロフィール設定画面でユーザー名とアイコンを設定
     * @param request 登録リクエスト
     * @param userAgent ユーザーエージェント
     * @param ip IPアドレス
     * @return 認証レスポンス
     * @throws IllegalArgumentException メールアドレスが既に登録されている場合
     */
    @Transactional
    public AuthResponse register(RegisterRequest request, String userAgent, String ip) {
        // メールアドレスの重複チェック
        if (userRepository.existsByMailaddress(request.getEmail())) {
            throw new IllegalArgumentException("このメールアドレスは既に登録されています");
        }

        // BCryptの72バイト制限チェック
        byte[] passwordBytes = request.getPassword().getBytes(StandardCharsets.UTF_8);
        if (passwordBytes.length > 72) {
            throw new IllegalArgumentException("パスワードは72バイト以下である必要があります");
        }

        // パスワードをハッシュ化
        String passwordHash = passwordEncoder.encode(request.getPassword());

        // ユーザーを作成（ユーザー名は仮で"user_<timestamp>"を設定）
        User user = new User();
        user.setMailaddress(request.getEmail());
        user.setPassword(passwordHash);
        user.setUsername("user_" + System.currentTimeMillis()); // 仮ユーザー名（後でプロフィール設定画面で変更）
        user = userRepository.save(user);

        // 現在のシーズンを取得
        Integer currentSeason = seasonCalculator.getCurrentSeason();

        // Rate初期レコードを作成（現在のシーズン、レート1500）
        Rate rate = new Rate(user, currentSeason);
        rateRepository.save(rate);

        // WeeklyLessons初期レコードを作成（学習回数0）
        WeeklyLessons weeklyLessons = new WeeklyLessons(user);
        weeklyLessonsRepository.save(weeklyLessons);

        // トークンを生成
        String accessToken = jwtUtil.generateAccessToken(user.getId(), user.getMailaddress());
        String refreshToken = jwtUtil.generateRefreshToken(user.getId());

        // セッションを作成（refreshTokenはSHA-256でハッシュ化）
        String refreshHash = hashWithSHA256(refreshToken);
        LocalDateTime expiresAt = LocalDateTime.now().plusDays(30);
        Session session = new Session(user, refreshHash, expiresAt, userAgent, ip);
        sessionRepository.save(session);

        // レスポンスを返す
        return new AuthResponse(
                user.getId(),
                user.getUsername(),
                user.getMailaddress(),
                accessToken,
                refreshToken,
                jwtUtil.getAccessTokenExpiration()
        );
    }

    /**
     * ログイン
     * @param request ログインリクエスト
     * @param userAgent ユーザーエージェント
     * @param ip IPアドレス
     * @return 認証レスポンス
     * @throws IllegalArgumentException メールアドレスまたはパスワードが正しくない場合
     */
    @Transactional
    public AuthResponse login(LoginRequest request, String userAgent, String ip) {
        // BCryptの72バイト制限チェック
        byte[] passwordBytes = request.getPassword().getBytes(StandardCharsets.UTF_8);
        if (passwordBytes.length > 72) {
            throw new IllegalArgumentException("パスワードは72バイト以下である必要があります");
        }

        // ユーザーを検索
        Optional<User> userOpt = userRepository.findByMailaddress(request.getEmail());
        if (userOpt.isEmpty()) {
            throw new IllegalArgumentException("メールアドレスまたはパスワードが正しくありません");
        }

        User user = userOpt.get();

        // パスワードを検証
        if (!passwordEncoder.matches(request.getPassword(), user.getPassword())) {
            throw new IllegalArgumentException("メールアドレスまたはパスワードが正しくありません");
        }

        // 退会済みユーザーのチェック
        if (user.isDeleteFlag()) {
            throw new IllegalArgumentException("メールアドレスまたはパスワードが正しくありません");
        }
 
        // BANユーザーのチェック
        if (user.isBanFlag()) {
            throw new IllegalArgumentException("このアカウントは利用停止されています");
        }

        // 現在のシーズンを取得
        Integer currentSeason = seasonCalculator.getCurrentSeason();

        // 現在のシーズンのRateレコードが存在しない場合、初期レート1500で作成
        if (!rateRepository.existsByUserAndSeason(user, currentSeason)) {
            Rate rate = new Rate(user, currentSeason);
            rateRepository.save(rate);
        }

        // トークンを生成
        String accessToken = jwtUtil.generateAccessToken(user.getId(), user.getMailaddress());
        String refreshToken = jwtUtil.generateRefreshToken(user.getId());

        // セッションを作成（refreshTokenはSHA-256でハッシュ化）
        String refreshHash = hashWithSHA256(refreshToken);
        LocalDateTime expiresAt = LocalDateTime.now().plusDays(30);
        Session session = new Session(user, refreshHash, expiresAt, userAgent, ip);
        sessionRepository.save(session);

        // レスポンスを返す
        return new AuthResponse(
                user.getId(),
                user.getUsername(),
                user.getMailaddress(),
                accessToken,
                refreshToken,
                jwtUtil.getAccessTokenExpiration()
        );
    }

    /**
     * リフレッシュトークンを使用して新しいアクセストークンを生成
     * @param refreshToken リフレッシュトークン
     * @return 認証レスポンス
     * @throws IllegalArgumentException リフレッシュトークンが無効な場合
     */
    @Transactional
    public AuthResponse refreshAccessToken(String refreshToken) {
        // トークンを検証
        if (!jwtUtil.validateToken(refreshToken)) {
            throw new IllegalArgumentException("無効なリフレッシュトークンです");
        }

        // トークンタイプを確認
        if (!"refresh".equals(jwtUtil.getTokenType(refreshToken))) {
            throw new IllegalArgumentException("リフレッシュトークンではありません");
        }

        // ユーザーIDを取得
        Long userId = jwtUtil.getUserIdFromToken(refreshToken);

        // ユーザーを検索
        Optional<User> userOpt = userRepository.findById(userId);
        if (userOpt.isEmpty()) {
            throw new IllegalArgumentException("ユーザーが見つかりません");
        }

        User user = userOpt.get();

        // セッションを検証（リフレッシュトークンのSHA-256ハッシュで検索）
        String refreshHash = hashWithSHA256(refreshToken);
        boolean sessionValid = sessionRepository.findValidSessionsByUser(user, LocalDateTime.now())
                .stream()
                .anyMatch(session -> refreshHash.equals(session.getRefreshHash()));

        if (!sessionValid) {
            throw new IllegalArgumentException("セッションが無効です");
        }

        // 新しいアクセストークンを生成
        String newAccessToken = jwtUtil.generateAccessToken(user.getId(), user.getMailaddress());

        // セッションの有効期限を延長
        sessionRepository.findValidSessionsByUser(user, LocalDateTime.now())
                .stream()
                .filter(session -> refreshHash.equals(session.getRefreshHash()))
                .findFirst()
                .ifPresent(session -> {
                    session.extendExpiration();
                    sessionRepository.save(session);
                });

        // レスポンスを返す
        return new AuthResponse(
                user.getId(),
                user.getUsername(),
                user.getMailaddress(),
                newAccessToken,
                refreshToken,
                jwtUtil.getAccessTokenExpiration()
        );
    }

    // /**
    //  * MARK:ログアウト（セッションを無効化）
    //  * @param userId ユーザーID
    //  */
    // @Transactional
    // public void logout(Long userId) {
    //     sessionRepository.revokeAllUserSessionsById(userId);
    // }

    /**
     * ログアウト（セッションを無効化）
     * @param user ユーザー
     */
    @Transactional
    public void logout(User user) {
        if (user == null || user.getId() == null || !userRepository.existsById(user.getId())) {
            throw new IllegalArgumentException("ユーザーが見つかりません");
        }
        sessionRepository.revokeAllUserSessions(user);
    }


    /**
     * 退会（セッションを無効化→退会）
     * @param user ユーザー
     */
    @Transactional
    public void withdraw(User user) {
        // 論理削除フラグを立てる
        user.setDeleteFlag(true);
        // 退会日時を記録(offlineAtを退会日時として使用)
        user.setOfflineAt(LocalDateTime.now());
        // リフレッシュトークンの削除
        // refreshTokenRepository.deleteByUser(user);
        sessionRepository.revokeAllUserSessions(user);
        // ユーザー情報を保存
        userRepository.save(user);
    }

    /**
     * 期限切れセッションのクリーンアップ
     */
    @Transactional
    public void cleanupExpiredSessions() {
        sessionRepository.deleteExpiredSessions(LocalDateTime.now());
    }
}
