package com.example.api.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ShopPurchaseRequest {
    private Integer itemId;
    private Integer quantity;
    private Long paymentMethodId;
}
