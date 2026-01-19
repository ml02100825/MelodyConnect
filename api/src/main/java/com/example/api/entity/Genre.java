package com.example.api.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import org.hibernate.annotations.Where;

@Entity
@Table(
    name = "genre",
    indexes = @Index(name = "idx_genre_name", columnList = "name"),
    uniqueConstraints = @UniqueConstraint(name = "uk_genre_name", columnNames = "name")
)
@Where(clause = "is_active = true AND is_deleted = false")
public class Genre {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "genre_id", nullable = false)
    private Long id;

    @Column(name = "name", length = 20, nullable = false)
    private String name;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

      /**
     * 有効フラグ
     */
    @Column(name = "is_active", nullable = false)
    private Boolean isActive = true;

    /**
     * 削除フラグ
     */
    @Column(name = "is_deleted", nullable = false)
    private Boolean isDeleted = false;

    /**

    /* ===== lifecycle ===== */
    @PrePersist
    void onCreate() {
        if (createdAt == null) {
            createdAt = LocalDateTime.now().truncatedTo(ChronoUnit.SECONDS);
        }
    }

    /* ===== getters / setters ===== */
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
}
