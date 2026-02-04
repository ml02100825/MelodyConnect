package com.example.api.controller;

import com.example.api.dto.ShopPurchaseRequest;
import com.example.api.dto.ShopPurchaseResponse;
import com.example.api.service.ShopService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/shop")
public class ShopController {

    @Autowired
    private ShopService shopService;

    @PostMapping("/purchase")
    public ResponseEntity<ShopPurchaseResponse> purchase(@RequestBody ShopPurchaseRequest request, @AuthenticationPrincipal Long userId) {
        try {
            ShopPurchaseResponse response = shopService.purchase(userId, request);
            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(new ShopPurchaseResponse(false, e.getMessage(), 0));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(new ShopPurchaseResponse(false, "処理中にエラーが発生しました。", 0));
        }
    }
}
