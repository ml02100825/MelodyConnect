package com.example.api.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;

public class PrivacyUpdateRequest {
    @Min(0)
    @Max(2)
    private int privacy; // 0:公開, 1:フレンドのみ, 2:非公開

    public int getPrivacy() { return privacy; }
    public void setPrivacy(int privacy) { this.privacy = privacy; }
}