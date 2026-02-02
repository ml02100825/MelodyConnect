package com.example.api.entity;

import jakarta.persistence.*;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.time.LocalDateTime;

@Entity
@Table(
    name = "contact",
    indexes = {
        @Index(name = "idx_contact_user_id", columnList = "user_id"),
        @Index(name = "idx_contact_status", columnList = "status")
    }
)
public class Contact {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "contact_id")
    private Long contactId;

    @NotBlank
    @Column(name = "contact_detail", nullable = false, columnDefinition = "TEXT")
    private String contactDetail;

    @Column(name = "image_url")
    private String imageUrl;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(name = "title", nullable = false, length = 50)
    private String title;

    @Column(name = "status", length = 20)
    private String status = "未対応";

    @Column(name = "admin_memo", columnDefinition = "TEXT")
    private String adminMemo;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        if (createdAt == null) {
            createdAt = LocalDateTime.now();
        }
        if (status == null) {
            status = "未対応";
        }
    }

    // ====== コンストラクタ ======
    public Contact() {
    }

    public Contact(User user, String title, String contactDetail, String imageUrl) {
        this.user = user;
        this.title = title;
        this.contactDetail = contactDetail;
        this.imageUrl = imageUrl;
    }

    // ====== getters / setters ======
    public Long getContactId() {
        return contactId;
    }
    public void setContactId(Long contactId) {
        this.contactId = contactId;
    }

    public String getContactDetail() {
        return contactDetail;
    }
    public void setContactDetail(String contactDetail) {
        this.contactDetail = contactDetail;
    }

    public String getImageUrl() {
        return imageUrl;
    }
    public void setImageUrl(String imageUrl) {
        this.imageUrl = imageUrl;
    }

    public User getUser() {
        return user;
    }
    public void setUser(User user) {
        this.user = user;
    }

    public String getTitle() {
        return title;
    }
    public void setTitle(String title) {
        this.title = title;
    }

    public String getStatus() {
        return status;
    }
    public void setStatus(String status) {
        this.status = status;
    }

    public String getAdminMemo() {
        return adminMemo;
    }
    public void setAdminMemo(String adminMemo) {
        this.adminMemo = adminMemo;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }
    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
}
