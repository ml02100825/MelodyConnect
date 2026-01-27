package com.example.api.service;

import com.example.api.dto.AuthResponse;
import com.example.api.dto.LoginRequest;
import com.example.api.dto.RegisterRequest;
import com.example.api.entity.*;
import com.example.api.repository.*;
import com.example.api.util.JwtUtil;
import com.example.api.util.SeasonCalculator;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.MailException; // ★追加
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import java.util.regex.Pattern;

/**
 * 認証サービスクラス
 * ユーザー登録、ログイン、セッション管理、パスワードリセットのビジネスロジックを提供します
 */
@Service
public class AuthService {

    private static final Logger logger = LoggerFactory.getLogger(AuthService.class);

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private SessionRepository sessionRepository;

    @Autowired
    private RateRepository rateRepository;

    @Autowired
    private WeeklyLessonsRepository weeklyLessonsRepository;

    @Autowired
    private PasswordResetTokenRepository passwordResetTokenRepository;

    @Autowired
    private JwtUtil jwtUtil;

    @Autowired
    private SeasonCalculator seasonCalculator;

    @Autowired
    private JavaMailSender mailSender;

    // application.propertiesから取得 (設定がない場合はデフォルト値)
    @Value("${spring.mail.username:noreply@example.com}")
    private String fromEmail;

    private final BCryptPasswordEncoder passwordEncoder = new BCryptPasswordEncoder();

    /**
     * SHA-256でハッシュ化
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
     * パスワードポリシーの検証 (共通メソッド)
     */
    private void validatePasswordPolicy(String password) {
        if (password == null || password.isBlank()) {
            throw new IllegalArgumentException("パスワードを入力してください");
        }
        // 1. バイト長チェック (Bcryptの制限 72byte)
        if (password.getBytes(StandardCharsets.UTF_8).length > 72) {
            throw new IllegalArgumentException("パスワードは72バイト以下である必要があります");
        }
        // 2. 文字数チェック (8文字以上)
        if (password.length() < 8) {
            throw new IllegalArgumentException("パスワードは8文字以上である必要があります");
        }
        // 3. 複雑性チェック (半角英数字記号のみ許可)
        if (!Pattern.matches("^[a-zA-Z0-9!@#$%^&*()_+\\-=\\[\\]{};':\"\\\\|,.<>\\/?]+$", password)) {
            throw new IllegalArgumentException("パスワードに使用できない文字が含まれています");
        }
    }

    /**
     * 共通処理: セッション作成とレスポンス生成
     */
    private AuthResponse createSessionAndResponse(User user, String userAgent, String ip) {
        String accessToken = jwtUtil.generateAccessToken(user.getId(), user.getMailaddress());
        String refreshToken = jwtUtil.generateRefreshToken(user.getId());

        String refreshHash = hashWithSHA256(refreshToken);
        LocalDateTime expiresAt = LocalDateTime.now().plusDays(30);
        Session session = new Session(user, refreshHash, expiresAt, userAgent, ip);
        sessionRepository.save(session);

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
     * ユーザー登録
     */
    @Transactional
    public AuthResponse register(RegisterRequest request, String userAgent, String ip) {
        if (userRepository.existsByMailaddress(request.getEmail())) {
            throw new IllegalArgumentException("このメールアドレスは既に登録されています");
        }

        // パスワードポリシー検証
        validatePasswordPolicy(request.getPassword());

        String passwordHash = passwordEncoder.encode(request.getPassword());

        User user = new User();
        user.setMailaddress(request.getEmail());
        user.setPassword(passwordHash);
        user.setUsername("user_" + System.currentTimeMillis());
        user = userRepository.save(user);

        Integer currentSeason = seasonCalculator.getCurrentSeason();
        Rate rate = new Rate(user, currentSeason);
        rateRepository.save(rate);

        WeeklyLessons weeklyLessons = new WeeklyLessons(user);
        weeklyLessonsRepository.save(weeklyLessons);

        logger.info("新規ユーザー登録: ID {}", user.getId());

        return createSessionAndResponse(user, userAgent, ip);
    }

    /**
     * ログイン
     */
    @Transactional
    public AuthResponse login(LoginRequest request, String userAgent, String ip) {
        byte[] passwordBytes = request.getPassword().getBytes(StandardCharsets.UTF_8);
        if (passwordBytes.length > 72) {
            throw new IllegalArgumentException("パスワードは72バイト以下である必要があります");
        }

        User user = userRepository.findByMailaddress(request.getEmail())
                .orElseThrow(() -> new IllegalArgumentException("メールアドレスまたはパスワードが正しくありません"));

        if (!passwordEncoder.matches(request.getPassword(), user.getPassword())) {
            throw new IllegalArgumentException("メールアドレスまたはパスワードが正しくありません");
        }

        Integer currentSeason = seasonCalculator.getCurrentSeason();
        if (!rateRepository.existsByUserAndSeason(user, currentSeason)) {
            Rate rate = new Rate(user, currentSeason);
            rateRepository.save(rate);
        }

        int loginCount = user.getLoginCount() == null ? 0 : user.getLoginCount();
        user.setLoginCount(loginCount + 1);
        userRepository.save(user);

        logger.info("ログイン成功: ID {}", user.getId());

        return createSessionAndResponse(user, userAgent, ip);
    }

    /**
     * トークンリフレッシュ
     */
    @Transactional
    public AuthResponse refreshAccessToken(String refreshToken) {
        // 1. 基本的なJWT検証
        if (!jwtUtil.validateToken(refreshToken)) {
            throw new IllegalArgumentException("無効なリフレッシュトークンです");
        }
        
        // 2. トークンタイプが "refresh" であることを確認
        if (!"refresh".equals(jwtUtil.getTokenType(refreshToken))) {
            throw new IllegalArgumentException("リフレッシュトークンではありません");
        }

        Long userId = jwtUtil.getUserIdFromToken(refreshToken);
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("ユーザーが見つかりません"));

        if (user.isDeleteFlag() || user.isBanFlag()) {
            throw new IllegalArgumentException("アカウントが利用できません");
        }

        // 3. DB上のセッション有効性チェック
        String refreshHash = hashWithSHA256(refreshToken);
        Optional<Session> sessionOpt = sessionRepository.findValidSessionsByUser(user, LocalDateTime.now())
                .stream()
                .filter(session -> refreshHash.equals(session.getRefreshHash()))
                .findFirst();

        Session session = sessionOpt.orElseThrow(() -> {
            logger.warn("リフレッシュ失敗: セッションが無効または存在しません UserID {}", userId);
            return new IllegalArgumentException("セッションが無効です");
        });

        // 新しいアクセストークン生成
        String newAccessToken = jwtUtil.generateAccessToken(user.getId(), user.getMailaddress());

        // 有効期限延長
        session.extendExpiration();
        sessionRepository.save(session);

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
     * ログアウト（指定されたリフレッシュトークンに紐づくセッションを削除）
     */
    @Transactional
    public void logout(String refreshToken) {
        if (refreshToken == null || refreshToken.isEmpty()) return;

        try {
            String refreshHash = hashWithSHA256(refreshToken);
            Long userId = jwtUtil.getUserIdFromToken(refreshToken);
            User user = userRepository.getReferenceById(userId);
            
            // DBから該当セッションを検索して物理削除
            sessionRepository.findValidSessionsByUser(user, LocalDateTime.now().plusYears(1))
                    .stream()
                    .filter(s -> refreshHash.equals(s.getRefreshHash()))
                    .findFirst()
                    .ifPresent(session -> {
                        sessionRepository.delete(session);
                        logger.info("ログアウト(セッション削除): UserID {}", userId);
                    });
            
        } catch (Exception e) {
            logger.warn("ログアウト処理中にエラー（無視します）: {}", e.getMessage());
        }
    }

    /**
     * 期限切れセッションのクリーンアップ（DB）
     */
    @Transactional
    public void cleanupExpiredSessions() {
        sessionRepository.deleteExpiredSessions(LocalDateTime.now());
        logger.info("期限切れセッションを削除しました");
    }

    // ==========================================
    // パスワードリセット (DB管理版)
    // ==========================================

    /**
     * DB上の期限切れリセットトークンを定期削除
     * 1時間(3600000ms)ごとに実行
     */
    @Scheduled(fixedRate = 3600000)
    @Transactional
    public void cleanupExpiredResetTokens() {
        passwordResetTokenRepository.deleteAllExpiredSince(LocalDateTime.now());
        logger.debug("期限切れリセットトークンのDBクリーンアップ完了");
    }

    /**
     * パスワードリセット要求
     */
    @Transactional
    public void requestPasswordReset(String email) {
        Optional<User> userOpt = userRepository.findByMailaddress(email);
        if (userOpt.isEmpty()) {
            logger.info("パスワードリセット要求: 存在しないメールアドレス {}", email);
            return;
        }

        User user = userOpt.get();

        // 既存のトークンがあれば削除（常に最新のみ有効にする）
        passwordResetTokenRepository.deleteByUser(user);

        // 新しいトークンを生成してDBに保存
        String tokenStr = UUID.randomUUID().toString();
        PasswordResetToken resetToken = new PasswordResetToken(
                tokenStr, 
                user, 
                LocalDateTime.now().plusHours(1)
        );
        passwordResetTokenRepository.save(resetToken);

        try {
            SimpleMailMessage message = new SimpleMailMessage();
            message.setFrom(fromEmail);
            message.setTo(email);
            message.setSubject("【MelodyConnect】パスワードリセット");
            message.setText(
                    "パスワードリセットのリクエストを受け付けました。\n" +
                    "以下のコードをアプリに入力して、新しいパスワードを設定してください。\n\n" +
                    "リセットコード: " + tokenStr + "\n\n" +
                    "※このコードの有効期限は1時間です。\n" +
                    "※心当たりがない場合はこのメールを無視してください。"
            );
            
            mailSender.send(message);
            logger.info("リセットメール送信完了: {}", email);
            
        } catch (MailException e) { // ★修正: 具体的な例外(MailException)をキャッチ
            logger.error("メール送信失敗: {}", e.getMessage(), e);
            throw new RuntimeException("メールの送信に失敗しました。しばらく待ってから再試行してください。");
        }
    }

    /**
     * パスワード更新実行
     */
    @Transactional
    public void resetPassword(String tokenStr, String newPassword) {
        // DBからトークンを検索
        PasswordResetToken resetToken = passwordResetTokenRepository.findByToken(tokenStr)
                .orElseThrow(() -> new IllegalArgumentException("無効なリセットコードです"));

        if (resetToken.getExpiryDate().isBefore(LocalDateTime.now())) {
            passwordResetTokenRepository.delete(resetToken);
            throw new IllegalArgumentException("リセットコードの有効期限が切れています");
        }

        User user = resetToken.getUser();

        // パスワードポリシーの検証
        validatePasswordPolicy(newPassword);

        // パスワード更新
        user.setPassword(passwordEncoder.encode(newPassword));
        userRepository.save(user);

        // 既存セッションの無効化（強制ログアウト）
        revokeAllUserSessions(user);

        // 使用済みトークンを削除
        passwordResetTokenRepository.delete(resetToken);
        
        logger.info("パスワードリセット完了: UserID {}", user.getId());
    }

    /**
     * 指定ユーザーの全アクティブセッションを無効化（削除）
     */
    private void revokeAllUserSessions(User user) {
        try {
            List<Session> sessions = sessionRepository.findValidSessionsByUser(user, LocalDateTime.now());
            if (!sessions.isEmpty()) {
                sessionRepository.deleteAll(sessions);
                logger.info("パスワード変更に伴い全セッションを破棄: UserID {}", user.getId());
            }
        } catch (Exception e) {
            logger.error("セッション破棄中にエラー（処理は続行）", e);
        }
    }
}