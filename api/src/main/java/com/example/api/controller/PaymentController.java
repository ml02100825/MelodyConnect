package com.example.api.controller;

import com.example.api.entity.User;
import com.example.api.entity.UserPaymentMethod;
import com.example.api.repository.UserPaymentMethodRepository;
import com.example.api.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/payments")
public class PaymentController {

    @Autowired
    private UserPaymentMethodRepository paymentRepository;

    @Autowired
    private UserRepository userRepository;

    // === クレジットカード関連 ===
    @GetMapping
    public List<UserPaymentMethod> getMethods(@AuthenticationPrincipal Long userId) {
        return paymentRepository.findByUserId(userId);
    }

    @PostMapping
    public ResponseEntity<?> addMethod(@RequestBody Map<String, String> request, 
                                       @AuthenticationPrincipal Long userId) {
        savePaymentMethod(userId, request, new UserPaymentMethod());
        return ResponseEntity.ok(Map.of("message", "カードを追加しました"));
    }

    @PutMapping("/{id}")
    public ResponseEntity<?> updateMethod(@PathVariable Long id,
                                          @RequestBody Map<String, String> request,
                                          @AuthenticationPrincipal Long userId) {
        return paymentRepository.findById(id)
            .filter(method -> method.getUserId().equals(userId))
            .map(method -> {
                savePaymentMethod(userId, request, method);
                return ResponseEntity.ok(Map.of("message", "カード情報を更新しました"));
            })
            .orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteMethod(@PathVariable Long id, @AuthenticationPrincipal Long userId) {
        return paymentRepository.findById(id)
            .filter(method -> method.getUserId().equals(userId))
            .map(method -> {
                paymentRepository.delete(method);
                return ResponseEntity.ok(Map.of("message", "削除しました"));
            })
            .orElse(ResponseEntity.notFound().build());
    }

    // === サブスクリプション関連 ===

    @GetMapping("/subscription-status")
    public ResponseEntity<?> getSubscriptionStatus(@AuthenticationPrincipal Long userId) {
        return userRepository.findById(userId)
            .map(user -> {
                // 有効期限切れチェック
                // 1(契約中)または2(解約予約)で、かつ期限を過ぎている場合
                if (user.getSubscribeFlag() > 0 && 
                    user.getExpiresAt() != null && 
                    user.getExpiresAt().isBefore(LocalDateTime.now())) {
                    
                    // 期限切れなら 0 (未契約) に戻す
                    user.setSubscribeFlag(0);
                    userRepository.save(user);
                }
                
                return ResponseEntity.ok(Map.of(
                    "status", user.getSubscribeFlag(), // 0, 1, 2
                    "expiresAt", user.getExpiresAt() != null ? user.getExpiresAt().toString() : ""
                ));
            })
            .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping("/subscribe")
    public ResponseEntity<?> subscribe(@AuthenticationPrincipal Long userId) {
        List<UserPaymentMethod> methods = paymentRepository.findByUserId(userId);
        if (methods.isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("error", "支払い方法が登録されていません"));
        }

        return userRepository.findById(userId)
            .map(user -> {
                // ▼▼▼ 修正: 契約中は 1 ▼▼▼
                user.setSubscribeFlag(1); 
                user.setExpiresAt(LocalDateTime.now().plusDays(31));
                
                userRepository.save(user);
                return ResponseEntity.ok(Map.of(
                    "message", "ConnectPlusに登録しました",
                    "status", 1,
                    "expiresAt", user.getExpiresAt().toString()
                ));
            })
            .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping("/unsubscribe")
    public ResponseEntity<?> unsubscribe(@AuthenticationPrincipal Long userId) {
        return userRepository.findById(userId)
            .map(user -> {
                // ▼▼▼ 修正: 契約中(1)なら解約予約(2)へ変更 ▼▼▼
                if (user.getSubscribeFlag() == 1) {
                    user.setSubscribeFlag(2); 
                    userRepository.save(user);
                    return ResponseEntity.ok(Map.of("message", "自動更新を停止しました", "status", 2));
                } else if (user.getSubscribeFlag() == 2) {
                    return ResponseEntity.ok(Map.of("message", "既に解約予約済みです", "status", 2));
                } else {
                    return ResponseEntity.badRequest().body(Map.of("error", "契約していません"));
                }
            })
            .orElse(ResponseEntity.notFound().build());
    }

    // === 内部メソッド ===
    private void savePaymentMethod(Long userId, Map<String, String> request, UserPaymentMethod method) {
        String cardNumber = request.get("cardNumber");
        String last4 = (cardNumber != null && cardNumber.length() > 4) 
                ? cardNumber.substring(cardNumber.length() - 4) 
                : (cardNumber != null ? cardNumber : "0000");

        method.setUserId(userId);
        method.setBrand(request.get("brand"));
        method.setLast4(last4);
        method.setExpiry(request.get("expiry"));
        method.setHolderName(request.get("cardHolder"));
        
        paymentRepository.save(method);
    }
}