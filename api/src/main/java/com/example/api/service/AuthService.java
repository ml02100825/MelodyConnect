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
import org.springframework.mail.MailException;
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
    private EmailChangeTokenRepository emailChangeTokenRepository;

    @Autowired
    private JwtUtil jwtUtil;

    @Autowired
    private SeasonCalculator seasonCalculator;

    @Autowired
    private JavaMailSender mailSender;

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
     * パスワードポリシーの検証
     */
    private void validatePasswordPolicy(String password) {
        if (password == null || password.isBlank()) {
            throw new IllegalArgumentException("パスワードを入力してください");
        }
        if (password.getBytes(StandardCharsets.UTF_8).length > 72) {
            throw new IllegalArgumentException("パスワードは72バイト以下である必要があります");
        }
        if (password.length() < 8) {
            throw new IllegalArgumentException("パスワードは8文字以上である必要があります");
        }
        if (!Pattern.matches("^[a-zA-Z0-9!@#$%^&*()_+\\-=\\[\\]{};':\"\\\\|,.<>\\/?]+$", password)) {
            throw new IllegalArgumentException("パスワードに使用できない文字が含まれています");
        }
    }

    /**
     * 共通処理: セッション作成とレスポンス生成
     */
    private AuthResponse createSessionAndResponse(User user, String userAgent, String ip) {
        // トークンを生成
        String accessToken = jwtUtil.generateAccessToken(user.getId(), user.getMailaddress());
        String refreshToken = jwtUtil.generateRefreshToken(user.getId());

        // セッションを作成
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

        validatePasswordPolicy(request.getPassword());

        String passwordHash = passwordEncoder.encode(request.getPassword());

        User user = new User();
        user.setMailaddress(request.getEmail());
        user.setPassword(passwordHash);
        user.setUsername("user_" + System.currentTimeMillis());

        // サブスク初期状態設定
        user.setSubscribeFlag(0);    // 未契約
        user.setCancellationFlag(0); // 未解約

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

        // ユーザーを検索
        Optional<User> userOpt = userRepository.findByMailaddress(request.getEmail());
        if (userOpt.isEmpty()) {
            throw new IllegalArgumentException("メールアドレスまたはパスワードが正しくありません");
        }

        User user = userOpt.get();

        if (!passwordEncoder.matches(request.getPassword(), user.getPassword())) {
            throw new IllegalArgumentException("メールアドレスまたはパスワードが正しくありません");
        }

        // 現在のシーズンを取得
        Integer currentSeason = seasonCalculator.getCurrentSeason();

        // Rateレコードが存在しない場合作成
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
        if (!jwtUtil.validateToken(refreshToken)) {
            throw new IllegalArgumentException("無効なリフレッシュトークンです");
        }
        if (!"refresh".equals(jwtUtil.getTokenType(refreshToken))) {
            throw new IllegalArgumentException("リフレッシュトークンではありません");
        }

        Long userId = jwtUtil.getUserIdFromToken(refreshToken);
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("ユーザーが見つかりません"));

        if (user.isDeleteFlag() || user.isBanFlag()) {
            throw new IllegalArgumentException("アカウントが利用できません");
        }

        String refreshHash = hashWithSHA256(refreshToken);
        Optional<Session> sessionOpt = sessionRepository.findValidSessionsByUser(user, LocalDateTime.now())
                .stream()
                .filter(session -> refreshHash.equals(session.getRefreshHash()))
                .findFirst();

        Session session = sessionOpt.orElseThrow(() -> {
            logger.warn("リフレッシュ失敗: セッションが無効または存在しません UserID {}", userId);
            return new IllegalArgumentException("セッションが無効です");
        });

        String newAccessToken = jwtUtil.generateAccessToken(user.getId(), user.getMailaddress());

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
     * 通常のログアウト用
     */
    @Transactional
    public void logout(String refreshToken) {
        if (refreshToken == null || refreshToken.isEmpty()) return;

        try {
            String refreshHash = hashWithSHA256(refreshToken);
            Long userId = jwtUtil.getUserIdFromToken(refreshToken);
            User user = userRepository.getReferenceById(userId);

            sessionRepository.findValidSessionsByUser(user, LocalDateTime.now().plusYears(1))
                    .stream()
                    .filter(s -> refreshHash.equals(s.getRefreshHash()))
                    .findFirst()
                    .ifPresent(session -> {
                        sessionRepository.delete(session);
                        logger.info("ログアウト(セッション削除): UserID {}", userId);
                    });

            updateOfflineAtIfNoActiveSessions(user);

        } catch (Exception e) {
            logger.warn("ログアウト処理中にエラー（無視します）: {}", e.getMessage());
        }
    }

    /**
     * ログアウト（ユーザーの全セッションを削除）
     * パスワードリセット時や強制ログアウトで使用
     */
    @Transactional
    public void logout(User user) {
        if (user == null || user.getId() == null || !userRepository.existsById(user.getId())) {
            throw new IllegalArgumentException("ユーザーが見つかりません");
        }
        sessionRepository.revokeAllUserSessions(user);
        updateOfflineAtIfNoActiveSessions(user);
    }

    /**
     * 退会処理
     */
    @Transactional
    public void withdraw(User user) {
        user.setDeleteFlag(true);
        user.setOfflineAt(LocalDateTime.now());
        sessionRepository.revokeAllUserSessions(user);
        userRepository.save(user);
    }

    /**
     * 期限切れセッションのクリーンアップ（1時間ごとに自動実行）
     */
    @Transactional
    @Scheduled(fixedRate = 3600000)
    public void cleanupExpiredSessions() {
        LocalDateTime now = LocalDateTime.now();

        // 期限切れセッションを持つユーザーを事前に取得（効率化）
        List<User> affectedUsers = sessionRepository.findUsersWithExpiredSessions(now);

        // 期限切れセッションを削除
        sessionRepository.deleteExpiredSessions(now);
        logger.info("期限切れセッションを削除しました: 影響を受けたユーザー数={}", affectedUsers.size());

        // 影響を受けたユーザーの offlineAt を更新
        for (User user : affectedUsers) {
            updateOfflineAtIfNoActiveSessions(user);
        }
    }

    /**
     * ユーザーの offlineAt を更新（有効なセッションが存在しない場合のみ）
     */
    private void updateOfflineAtIfNoActiveSessions(User user) {
        LocalDateTime now = LocalDateTime.now();
        List<Session> validSessions = sessionRepository.findValidSessionsByUser(user, now);

        if (validSessions.isEmpty()) {
            user.setOfflineAt(now);
            userRepository.save(user);
            logger.info("ユーザーの offlineAt を更新: userId={}, offlineAt={}", user.getId(), now);
        } else {
            logger.debug("有効なセッションが存在するため、offlineAt は更新しません: userId={}, activeSessions={}",
                    user.getId(), validSessions.size());
        }
    }

    // ==========================================
    // パスワードリセット (DB管理版)
    // ==========================================

    /**
     * DB上の期限切れリセットトークンを定期削除
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

        passwordResetTokenRepository.deleteByUser(user);

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
            
        } catch (MailException e) {
            logger.error("メール送信失敗: {}", e.getMessage(), e);
            throw new RuntimeException("メールの送信に失敗しました。しばらく待ってから再試行してください。");
        }
    }

    /**
     * パスワード更新実行
     */
    @Transactional
    public void resetPassword(String tokenStr, String newPassword) {
        PasswordResetToken resetToken = passwordResetTokenRepository.findByToken(tokenStr)
                .orElseThrow(() -> new IllegalArgumentException("無効なリセットコードです"));

        if (resetToken.getExpiryDate().isBefore(LocalDateTime.now())) {
            passwordResetTokenRepository.delete(resetToken);
            throw new IllegalArgumentException("リセットコードの有効期限が切れています");
        }

        User user = resetToken.getUser();

        validatePasswordPolicy(newPassword);

        user.setPassword(passwordEncoder.encode(newPassword));
        userRepository.save(user);

        // ★修正: ユーザー指定のlogoutメソッド（全セッション削除）を使用
        logout(user);

        passwordResetTokenRepository.delete(resetToken);

        logger.info("パスワードリセット完了: UserID {}", user.getId());
    }

    /**
     * メールアドレス変更要求（現在のメールアドレスにコード送信）
     */
    @Transactional
    public void requestEmailChange(User user) {
        // 既存のトークンをチェック
        Optional<EmailChangeToken> existingTokenOpt = emailChangeTokenRepository.findByUser(user);

        if (existingTokenOpt.isPresent()) {
            EmailChangeToken existingToken = existingTokenOpt.get();
            LocalDateTime now = LocalDateTime.now();

            // トークンが有効期限内かつnewEmailが空の場合は再利用
            if (existingToken.getExpiryDate().isAfter(now) &&
                (existingToken.getNewEmail() == null || existingToken.getNewEmail().isEmpty())) {
                logger.info("既にトークンが存在し有効期限内のため再利用します: UserID {}", user.getId());
                return; // メールを再送信せず、正常終了
            }

            // 期限切れまたはnewEmailが設定済みの場合は削除
            logger.info("既存トークンを削除して新しいトークンを作成します: UserID {}", user.getId());
            emailChangeTokenRepository.deleteByUser(user);
        }

        // トークン生成（有効期限1時間）
        String tokenStr = UUID.randomUUID().toString();
        EmailChangeToken token = new EmailChangeToken(
                tokenStr,
                user,
                LocalDateTime.now().plusHours(1),
                "" // 新しいメールアドレスは後で設定
        );
        emailChangeTokenRepository.save(token);

        try {
            SimpleMailMessage message = new SimpleMailMessage();
            message.setFrom(fromEmail);
            message.setTo(user.getMailaddress());
            message.setSubject("【MelodyConnect】メールアドレス変更");
            message.setText(
                    "メールアドレス変更のリクエストを受け付けました。\n" +
                    "以下のコードをアプリに入力して、新しいメールアドレスを設定してください。\n\n" +
                    "変更コード: " + tokenStr + "\n\n" +
                    "※このコードの有効期限は1時間です。\n" +
                    "※心当たりがない場合はこのメールを無視してください。"
            );

            mailSender.send(message);
            logger.info("メールアドレス変更メール送信完了: {}", user.getMailaddress());

        } catch (MailException e) {
            logger.error("メール送信失敗: {}", e.getMessage(), e);
            throw new RuntimeException("メールの送信に失敗しました。しばらく待ってから再試行してください。");
        }
    }

    /**
     * メールアドレス変更実行
     */
    @Transactional
    public void confirmEmailChange(String tokenStr, String newEmail) {
        EmailChangeToken token = emailChangeTokenRepository.findByToken(tokenStr)
                .orElseThrow(() -> new IllegalArgumentException("無効な変更コードです"));

        if (token.getExpiryDate().isBefore(LocalDateTime.now())) {
            emailChangeTokenRepository.delete(token);
            throw new IllegalArgumentException("変更コードの有効期限が切れています");
        }

        // 新しいメールアドレスが既に使用されていないかチェック
        Optional<User> existingUser = userRepository.findByMailaddress(newEmail);
        if (existingUser.isPresent() && !existingUser.get().getId().equals(token.getUser().getId())) {
            throw new IllegalArgumentException("このメールアドレスは既に使用されています");
        }

        User user = token.getUser();
        user.setMailaddress(newEmail);
        userRepository.save(user);

        // 全セッションを無効化（セキュリティのため）
        logout(user);

        emailChangeTokenRepository.delete(token);

        logger.info("メールアドレス変更完了: UserID {}, 新メール {}", user.getId(), newEmail);
    }
}