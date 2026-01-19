package com.example.api.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;

public class VolumeUpdateRequest {

    @Min(0)
    @Max(100)
    private int volume;

    public int getVolume() { return volume; }
    public void setVolume(int volume) { this.volume = volume; }
}