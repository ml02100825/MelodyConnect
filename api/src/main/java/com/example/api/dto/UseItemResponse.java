package com.example.api.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * アイテム使用レスポンスDTO
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class UseItemResponse {

    /** 成功フラグ */
    private boolean success;

    /** メッセージ */
    private String message;

    /** 回復後のライフ */
    private int newLife;

    /** 使用後の所持数 */
    private int newQuantity;
}
