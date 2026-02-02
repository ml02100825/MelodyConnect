package com.example.api.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;

/**
 * メールアドレス変更トークンエンティティ
 * ユーザーのメールアドレス変更要求を管理します
 */
@Entity
@Table(name = "email_change_token")
public class EmailChangeToken {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String token;

    @OneToOne(targetEntity = User.class, fetch = FetchType.EAGER)
    @JoinColumn(nullable = false, name = "user_id")
    private User user;

    @Column(nullable = false)
    private LocalDateTime expiryDate;

    @Column(nullable = false)
    private String newEmail;

    public EmailChangeToken() {}

    public EmailChangeToken(String token, User user, LocalDateTime expiryDate, String newEmail) {
        this.token = token;
        this.user = user;
        this.expiryDate = expiryDate;
        this.newEmail = newEmail;
    }

    // Getters and Setters
    public Long getId() {
        return id;
    }

    public String getToken() {
        return token;
    }

    public User getUser() {
        return user;
    }

    public LocalDateTime getExpiryDate() {
        return expiryDate;
    }

    public String getNewEmail() {
        return newEmail;
    }

    public void setNewEmail(String newEmail) {
        this.newEmail = newEmail;
    }
}
