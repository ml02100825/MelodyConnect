package com.example.api.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * アイテム使用リクエストDTO
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class UseItemRequest {

    /** ユーザーID */
    private Long userId;

    /** 使用するアイテムID */
    private Integer itemId;
}
