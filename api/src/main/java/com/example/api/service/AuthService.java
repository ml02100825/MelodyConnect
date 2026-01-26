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
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
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
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

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
    private JwtUtil jwtUtil;

    @Autowired
    private SeasonCalculator seasonCalculator;

    @Autowired
    private JavaMailSender mailSender;

    // application.propertiesから取得 (設定がない場合はデフォルト値)
    @Value("${spring.mail.username:noreply@example.com}")
    private String fromEmail;

    private final BCryptPasswordEncoder passwordEncoder = new BCryptPasswordEncoder();

    // パスワードリセット用トークンの一時保存 (DBカラム変更なしで対応)
    // メモリリーク対策として @Scheduled で定期的に掃除します
    private static class ResetTokenInfo {
        String email;
        LocalDateTime expiry;

        ResetTokenInfo(String email, LocalDateTime expiry) {
            this.email = email;
            this.expiry = expiry;
        }
    }
    // トークン(UUID) -> 情報
    private final Map<String, ResetTokenInfo> resetTokenStore = new ConcurrentHashMap<>();

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

        byte[] passwordBytes = request.getPassword().getBytes(StandardCharsets.UTF_8);
        if (passwordBytes.length > 72) {
            throw new IllegalArgumentException("パスワードは72バイト以下である必要があります");
        }

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
     * (トークン種別チェックとDBセッション検証を追加済み)
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
    // パスワードリセット (メール送信 & 定期掃除)
    // ==========================================

    /**
     * ★追加: メモリ上の期限切れリセットトークンを定期削除
     * 1時間(3600000ms)ごとに実行
     */
    @Scheduled(fixedRate = 3600000)
    public void cleanupExpiredResetTokens() {
        LocalDateTime now = LocalDateTime.now();
        // 期限切れのエントリを一括削除
        resetTokenStore.entrySet().removeIf(entry -> entry.getValue().expiry.isBefore(now));
        logger.debug("期限切れリセットトークンのクリーンアップ完了");
    }

    /**
     * パスワードリセット要求
     */
    public void requestPasswordReset(String email) {
        Optional<User> userOpt = userRepository.findByMailaddress(email);
        if (userOpt.isEmpty()) {
            logger.info("パスワードリセット要求: 存在しないメールアドレス {}", email);
            return;
        }

        String token = UUID.randomUUID().toString();
        resetTokenStore.put(token, new ResetTokenInfo(email, LocalDateTime.now().plusHours(1)));

        try {
            SimpleMailMessage message = new SimpleMailMessage();
            message.setFrom(fromEmail);
            message.setTo(email);
            message.setSubject("【MelodyConnect】パスワードリセット");
            message.setText(
                    "パスワードリセットのリクエストを受け付けました。\n" +
                    "以下のコードをアプリに入力して、新しいパスワードを設定してください。\n\n" +
                    "リセットコード: " + token + "\n\n" +
                    "※このコードの有効期限は1時間です。\n" +
                    "※心当たりがない場合はこのメールを無視してください。"
            );
            
            mailSender.send(message);
            logger.info("リセットメール送信完了: {}", email);
            
        } catch (Exception e) {
            logger.error("メール送信失敗: {}", e.getMessage(), e);
            throw new RuntimeException("メールの送信に失敗しました。しばらく待ってから再試行してください。");
        }
    }

    /**
     * パスワード更新実行
     */
    @Transactional
    public void resetPassword(String token, String newPassword) {
        ResetTokenInfo info = resetTokenStore.get(token);

        if (info == null) {
            throw new IllegalArgumentException("無効なリセットコードです");
        }
        if (info.expiry.isBefore(LocalDateTime.now())) {
            resetTokenStore.remove(token);
            throw new IllegalArgumentException("リセットコードの有効期限が切れています");
        }

        User user = userRepository.findByMailaddress(info.email)
                .orElseThrow(() -> new IllegalArgumentException("ユーザーが見つかりません"));

        byte[] passwordBytes = newPassword.getBytes(StandardCharsets.UTF_8);
        if (passwordBytes.length > 72) {
            throw new IllegalArgumentException("パスワードは72バイト以下である必要があります");
        }

        user.setPassword(passwordEncoder.encode(newPassword));
        userRepository.save(user);

        resetTokenStore.remove(token);
        
        logger.info("パスワードリセット完了: UserID {}", user.getId());
    }
}