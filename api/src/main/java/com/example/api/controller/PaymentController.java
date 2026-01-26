package com.example.api.controller;

import com.example.api.entity.User;
import com.example.api.entity.UserPaymentMethod;
import com.example.api.repository.UserPaymentMethodRepository;
import com.example.api.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/payments")
public class PaymentController {

    @Autowired
    private UserPaymentMethodRepository paymentRepository;

    @Autowired
    private UserRepository userRepository; // 追加: ユーザー情報更新用

    // === クレジットカード関連 ===

    // 一覧取得
    @GetMapping
    public List<UserPaymentMethod> getMethods(@AuthenticationPrincipal Long userId) {
        return paymentRepository.findByUserId(userId);
    }

    // 追加
    @PostMapping
    public ResponseEntity<?> addMethod(@RequestBody Map<String, String> request, 
                                       @AuthenticationPrincipal Long userId) {
        savePaymentMethod(userId, request, new UserPaymentMethod());
        return ResponseEntity.ok(Map.of("message", "カードを追加しました"));
    }

    // 更新
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

    // 削除
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

    // === サブスクリプション関連 (新規追加) ===

    // ステータス確認
    @GetMapping("/subscription-status")
    public ResponseEntity<?> getSubscriptionStatus(@AuthenticationPrincipal Long userId) {
        return userRepository.findById(userId)
            .map(user -> ResponseEntity.ok(Map.of("isSubscribed", user.isSubscribeFlag())))
            .orElse(ResponseEntity.notFound().build());
    }

    // 登録 (カードがあればOK)
    @PostMapping("/subscribe")
    public ResponseEntity<?> subscribe(@AuthenticationPrincipal Long userId) {
        // 1. カードが登録されているかチェック
        List<UserPaymentMethod> methods = paymentRepository.findByUserId(userId);
        if (methods.isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("error", "支払い方法が登録されていません"));
        }

        // 2. ユーザーのサブスクフラグをONにする
        return userRepository.findById(userId)
            .map(user -> {
                user.setSubscribeFlag(true);
                userRepository.save(user);
                return ResponseEntity.ok(Map.of("message", "ConnectPlusに登録しました"));
            })
            .orElse(ResponseEntity.notFound().build());
    }

    // 解約
    @PostMapping("/unsubscribe")
    public ResponseEntity<?> unsubscribe(@AuthenticationPrincipal Long userId) {
        return userRepository.findById(userId)
            .map(user -> {
                user.setSubscribeFlag(false);
                userRepository.save(user);
                return ResponseEntity.ok(Map.of("message", "解約しました"));
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