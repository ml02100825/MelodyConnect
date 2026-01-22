package com.example.api.controller;

import com.example.api.entity.UserPaymentMethod;
import com.example.api.repository.UserPaymentMethodRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/payments")
public class PaymentController {

    @Autowired
    private UserPaymentMethodRepository paymentRepository;

    // 一覧取得
    @GetMapping
    public List<UserPaymentMethod> getMethods(@AuthenticationPrincipal UserDetails userDetails) {
        Long userId = Long.parseLong(userDetails.getUsername());
        return paymentRepository.findByUserId(userId);
    }

    // 追加
    @PostMapping
    public ResponseEntity<?> addMethod(@RequestBody Map<String, String> request, 
                                       @AuthenticationPrincipal UserDetails userDetails) {
        Long userId = Long.parseLong(userDetails.getUsername());
        savePaymentMethod(userId, request, new UserPaymentMethod());
        return ResponseEntity.ok(Map.of("message", "カードを追加しました"));
    }

    // 更新（Edit画面用）
    @PutMapping("/{id}")
    public ResponseEntity<?> updateMethod(@PathVariable Long id,
                                          @RequestBody Map<String, String> request,
                                          @AuthenticationPrincipal UserDetails userDetails) {
        Long userId = Long.parseLong(userDetails.getUsername());
        
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
    public ResponseEntity<?> deleteMethod(@PathVariable Long id, @AuthenticationPrincipal UserDetails userDetails) {
        Long userId = Long.parseLong(userDetails.getUsername());
        
        // 自分のカードかチェックして削除
        return paymentRepository.findById(id)
            .filter(method -> method.getUserId().equals(userId))
            .map(method -> {
                paymentRepository.delete(method);
                return ResponseEntity.ok(Map.of("message", "削除しました"));
            })
            .orElse(ResponseEntity.notFound().build());
    }

    // 保存・更新の共通処理
    private void savePaymentMethod(Long userId, Map<String, String> request, UserPaymentMethod method) {
        String cardNumber = request.get("cardNumber");
        // 下4桁のみ抽出（入力値が短い場合はそのまま）
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