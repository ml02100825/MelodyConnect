package com.example.api.dto.admin;

import jakarta.validation.constraints.NotBlank;

public class AdminGenreRequest {

    @NotBlank(message = "ジャンル名は必須です")
    private String name;

    private Boolean isActive = true;

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public Boolean getIsActive() { return isActive; }
    public void setIsActive(Boolean isActive) { this.isActive = isActive; }
}
