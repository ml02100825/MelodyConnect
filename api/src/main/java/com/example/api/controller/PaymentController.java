package com.example.api.controller;

import com.example.api.entity.UserPaymentMethod;
import com.example.api.repository.UserPaymentMethodRepository;
import com.example.api.repository.UserRepository;
import com.example.api.service.SubscriptionService; // 作成したサービス
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

    @Autowired
    private SubscriptionService subscriptionService; // ここでサービスを注入

    // ... (getMethods, addMethod, updateMethod, deleteMethod は変更なしのため省略) ...
    @GetMapping
    public List<UserPaymentMethod> getMethods(@AuthenticationPrincipal Long userId) {
        return paymentRepository.findByUserId(userId);
    }
    
    @PostMapping
    public ResponseEntity<?> addMethod(@RequestBody Map<String, String> request, @AuthenticationPrincipal Long userId) {
        savePaymentMethod(userId, request, new UserPaymentMethod());
        return ResponseEntity.ok(Map.of("message", "カードを追加しました"));
    }

    @PutMapping("/{id}")
    public ResponseEntity<?> updateMethod(@PathVariable Long id, @RequestBody Map<String, String> request, @AuthenticationPrincipal Long userId) {
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
                if (user.getSubscribeFlag() == 1 && 
                    user.getExpiresAt() != null && 
                    user.getExpiresAt().isBefore(LocalDateTime.now())) {
                    user.setSubscribeFlag(0);
                    user.setCancellationFlag(0);
                    userRepository.save(user);
                }
                return ResponseEntity.ok(Map.of(
                    "subscribeFlag", user.getSubscribeFlag(),
                    "cancellationFlag", user.getCancellationFlag(),
                    "expiresAt", user.getExpiresAt() != null ? user.getExpiresAt().toString() : ""
                ));
            })
            .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping("/subscribe")
    public ResponseEntity<?> subscribe(@AuthenticationPrincipal Long userId) {
        // 支払い方法チェック
        List<UserPaymentMethod> methods = paymentRepository.findByUserId(userId);
        if (methods.isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("error", "支払い方法が登録されていません"));
        }

        return userRepository.findById(userId)
            .map(user -> {
                // サービス層のメソッドを呼び出す（ここで登録・更新・アイテム付与を一括実行）
                try {
                    subscriptionService.activateSubscription(user);
                    
                    return ResponseEntity.ok(Map.of(
                        "message", "ConnectPlusに登録しました。特典アイテム(10個)を付与しました！",
                        "subscribeFlag", 1
                    ));
                } catch (Exception e) {
                    e.printStackTrace();
                    return ResponseEntity.status(500).body(Map.of("error", "処理中にエラーが発生しました: " + e.getMessage()));
                }
            })
            .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping("/unsubscribe")
    public ResponseEntity<?> unsubscribe(@AuthenticationPrincipal Long userId) {
        return userRepository.findById(userId)
            .map(user -> {
                if (user.getSubscribeFlag() == 1 && user.getCancellationFlag() == 0) {
                    user.setCancellationFlag(1);
                    userRepository.save(user);
                    return ResponseEntity.ok(Map.of("message", "自動更新を停止しました"));
                } else if (user.getCancellationFlag() == 1) {
                    return ResponseEntity.ok(Map.of("message", "既に解約予約済みです"));
                } else {
                    return ResponseEntity.badRequest().body(Map.of("error", "契約していません"));
                }
            })
            .orElse(ResponseEntity.notFound().build());
    }

    private void savePaymentMethod(Long userId, Map<String, String> request, UserPaymentMethod method) {
        String cardNumber = request.get("cardNumber");
        String last4 = (cardNumber != null && cardNumber.length() > 4) ? cardNumber.substring(cardNumber.length() - 4) : "0000";
        method.setUserId(userId);
        method.setBrand(request.get("brand"));
        method.setLast4(last4);
        method.setExpiry(request.get("expiry"));
        method.setHolderName(request.get("cardHolder"));
        paymentRepository.save(method);
    }
}