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

        // セッションを作成
        String refreshHash = passwordEncoder.encode(refreshToken);
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

        // トークンを生成
        String accessToken = jwtUtil.generateAccessToken(user.getId(), user.getMailaddress());
        String refreshToken = jwtUtil.generateRefreshToken(user.getId());

        // セッションを作成
        String refreshHash = passwordEncoder.encode(refreshToken);
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

        // セッションを検証（リフレッシュトークンのハッシュで検索）
        // 注意: BCryptは同じ入力でも異なるハッシュを生成するため、
        // 既存のセッションを全て取得して個別に検証する必要があります
        boolean sessionValid = sessionRepository.findValidSessionsByUser(user, LocalDateTime.now())
                .stream()
                .anyMatch(session -> passwordEncoder.matches(refreshToken, session.getRefreshHash()));

        if (!sessionValid) {
            throw new IllegalArgumentException("セッションが無効です");
        }

        // 新しいアクセストークンを生成
        String newAccessToken = jwtUtil.generateAccessToken(user.getId(), user.getMailaddress());

        // セッションの有効期限を延長
        sessionRepository.findValidSessionsByUser(user, LocalDateTime.now())
                .stream()
                .filter(session -> passwordEncoder.matches(refreshToken, session.getRefreshHash()))
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

    /**
     * ログアウト（セッションを無効化）
     * @param userId ユーザーID
     */
    @Transactional
    public void logout(Long userId) {
        sessionRepository.revokeAllUserSessionsById(userId);
    }

    /**
     * 期限切れセッションのクリーンアップ
     */
    @Transactional
    public void cleanupExpiredSessions() {
        sessionRepository.deleteExpiredSessions(LocalDateTime.now());
    }
}
