package com.example.api.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * 回復アイテム情報レスポンスDTO
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class RecoveryItemResponse {

    /** アイテムID */
    private Integer itemId;

    /** アイテム名 */
    private String name;

    /** 説明文 */
    private String description;

    /** 回復量 */
    private Integer healAmount;

    /** ユーザーの所持数 */
    private Integer quantity;
}
