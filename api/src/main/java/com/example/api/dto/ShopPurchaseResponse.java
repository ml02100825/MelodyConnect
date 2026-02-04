package com.example.api.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ShopPurchaseResponse {
    private boolean success;
    private String message;
    private Integer purchasedQuantity;
}
