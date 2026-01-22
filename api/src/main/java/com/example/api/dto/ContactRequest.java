package com.example.api.dto;

public class ContactRequest {
    private String title;
    private String contactDetail;
    private String imageUrl;

    // Getters and Setters
    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }

    public String getContactDetail() { return contactDetail; }
    public void setContactDetail(String contactDetail) { this.contactDetail = contactDetail; }

    public String getImageUrl() { return imageUrl; }
    public void setImageUrl(String imageUrl) { this.imageUrl = imageUrl; }
}