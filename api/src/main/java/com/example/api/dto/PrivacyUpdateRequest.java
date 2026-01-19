package com.example.api.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;

/**
 * プライバシー設定更新リクエストDTO
 */
public class PrivacyUpdateRequest {

    /**
     * プライバシー設定値
     * 0: 公開
     * 1: フレンドのみ公開
     * 2: 非公開
     */
    @Min(value = 0, message = "プライバシー設定の値が不正です")
    @Max(value = 2, message = "プライバシー設定の値が不正です")
    private int privacy;

    // コンストラクタ
    public PrivacyUpdateRequest() {}

    public PrivacyUpdateRequest(int privacy) {
        this.privacy = privacy;
    }

    // Getters / Setters
    public int getPrivacy() { return privacy; }
    public void setPrivacy(int privacy) { this.privacy = privacy; }
}