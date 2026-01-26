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
import org.springframework.beans.factory.annotation.Value; // 追加
import org.springframework.mail.SimpleMailMessage; // 追加
import org.springframework.mail.javamail.JavaMailSender; // 追加
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
    
    // ★追加: メール送信機能
    @Autowired
    private JavaMailSender mailSender;

    // application.propertiesから送信元アドレスを取得 (設定がない場合はデフォルト値)
    @Value("${spring.mail.username:noreply@example.com}")
    private String fromEmail;

    private final BCryptPasswordEncoder passwordEncoder = new BCryptPasswordEncoder();

    // ... (内部クラス ResetTokenInfo や hashWithSHA256 などはそのまま) ...
    private static class ResetTokenInfo {
        String email;
        LocalDateTime expiry;

        ResetTokenInfo(String email, LocalDateTime expiry) {
            this.email = email;
            this.expiry = expiry;
        }
    }
    private final Map<String, ResetTokenInfo> resetTokenStore = new ConcurrentHashMap<>();

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

    // ... (createSessionAndResponse, register, login, refreshAccessToken, logout, cleanupExpiredSessions は変更なし) ...
    // 長くなるため省略しますが、既存のコードをそのまま残してください。

    private AuthResponse createSessionAndResponse(User user, String userAgent, String ip) {
        // ... (省略: 既存のまま) ...
        String accessToken = jwtUtil.generateAccessToken(user.getId(), user.getMailaddress());
        String refreshToken = jwtUtil.generateRefreshToken(user.getId());
        String refreshHash = hashWithSHA256(refreshToken);
        LocalDateTime expiresAt = LocalDateTime.now().plusDays(30);
        Session session = new Session(user, refreshHash, expiresAt, userAgent, ip);
        sessionRepository.save(session);
        return new AuthResponse(user.getId(), user.getUsername(), user.getMailaddress(), accessToken, refreshToken, jwtUtil.getAccessTokenExpiration());
    }

    @Transactional
    public AuthResponse register(RegisterRequest request, String userAgent, String ip) {
        // ... (省略: 既存のまま) ...
        if (userRepository.existsByMailaddress(request.getEmail())) throw new IllegalArgumentException("このメールアドレスは既に登録されています");
        // ...
        User user = new User();
        user.setMailaddress(request.getEmail());
        user.setPassword(passwordEncoder.encode(request.getPassword()));
        user.setUsername("user_" + System.currentTimeMillis());
        user = userRepository.save(user);
        // ...
        rateRepository.save(new Rate(user, seasonCalculator.getCurrentSeason()));
        weeklyLessonsRepository.save(new WeeklyLessons(user));
        return createSessionAndResponse(user, userAgent, ip);
    }
    
    @Transactional
    public AuthResponse login(LoginRequest request, String userAgent, String ip) {
        // ... (省略: 既存のまま) ...
        User user = userRepository.findByMailaddress(request.getEmail())
                .orElseThrow(() -> new IllegalArgumentException("メールアドレスまたはパスワードが正しくありません"));
        if (!passwordEncoder.matches(request.getPassword(), user.getPassword())) {
            throw new IllegalArgumentException("メールアドレスまたはパスワードが正しくありません");
        }
        // ...
        return createSessionAndResponse(user, userAgent, ip);
    }
    
    @Transactional
    public AuthResponse refreshAccessToken(String refreshToken) {
        // ... (省略: 既存のまま) ...
        if (!jwtUtil.validateToken(refreshToken)) throw new IllegalArgumentException("無効なリフレッシュトークンです");
        // ...
        Long userId = jwtUtil.getUserIdFromToken(refreshToken);
        User user = userRepository.findById(userId).orElseThrow();
        // ...
        return new AuthResponse(user.getId(), user.getUsername(), user.getMailaddress(), jwtUtil.generateAccessToken(user.getId(), user.getMailaddress()), refreshToken, jwtUtil.getAccessTokenExpiration());
    }
    
    @Transactional
    public void logout(String refreshToken) {
        // ... (省略: 既存のまま) ...
        if (refreshToken == null) return;
        try {
            // ...
             sessionRepository.deleteExpiredSessions(LocalDateTime.now()); // ダミー呼び出し（本来はハッシュ検索削除）
        } catch(Exception e) {}
    }

    @Transactional
    public void cleanupExpiredSessions() {
        sessionRepository.deleteExpiredSessions(LocalDateTime.now());
    }


    // ==========================================
    // ★修正: パスワードリセット (メール送信)
    // ==========================================

    /**
     * パスワードリセット要求（トークン発行 & メール送信）
     */
    public void requestPasswordReset(String email) {
        // ユーザー存在確認
        Optional<User> userOpt = userRepository.findByMailaddress(email);
        if (userOpt.isEmpty()) {
            logger.info("パスワードリセット要求: 存在しないメールアドレス {}", email);
            return;
        }

        // トークン生成
        String token = UUID.randomUUID().toString();

        // メモリに保存 (有効期限 1時間)
        resetTokenStore.put(token, new ResetTokenInfo(email, LocalDateTime.now().plusHours(1)));

        // ★修正: 実際にメールを送信する
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
            // メール送信失敗をユーザーに通知するかは要件によりますが、
            // ここではエラーをスローしてフロントエンドに伝えます
            throw new RuntimeException("メールの送信に失敗しました。しばらく待ってから再試行してください。");
        }
    }

    /**
     * パスワード更新実行
     * (ここは変更なし)
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