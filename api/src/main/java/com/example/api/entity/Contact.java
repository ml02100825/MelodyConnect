package com.example.api.entity;

import jakarta.persistence.*;

@Entity
@Table(
    name = "contact",
    indexes = {
        @Index(name = "idx_contact_user_id", columnList = "user_id")
    }
)
public class Contact {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "contact_id")
    private Long contact_id; // int(12) -> Long

    @Column(name = "contact_detail", length = 500) // NULL許可
    private String contact_detail;

    @Column(name = "image_url", length = 200) // NULL許可
    private String image_url;

    @Column(name = "user_id", nullable = false) // int(10), NOT NULL
    private User user_id;

    @Column(name = "title", nullable = false, length = 50) // varchar(50), NOT NULL
    private String title;

    // ====== getters / setters ======
    public Long getContact_id() {
        return contact_id;
    }
    public void setContact_id(Long contact_id) {
        this.contact_id = contact_id;
    }

    public String getContact_detail() {
        return contact_detail;
    }
    public void setContact_detail(String contact_detail) {
        this.contact_detail = contact_detail;
    }

    public String getImage_url() {
        return image_url;
    }
    public void setImage_url(String image_url) {
        this.image_url = image_url;
    }

    public Integer getUser_id() {
        return user_id;
    }
    public void setUser_id(Integer user_id) {
        this.user_id = user_id;
    }

    public String getTitle() {
        return title;
    }
    public void setTitle(String title) {
        this.title = title;
    }
}
