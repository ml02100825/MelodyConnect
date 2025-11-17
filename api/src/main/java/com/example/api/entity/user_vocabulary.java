package com.example.api.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;
import lombok.*;

@Entity
@Table(name = "user_vocabulary")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class user_vocabulary {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "user_vocab_id", nullable = false)
    private Integer user_vocab_id;

    @Column(name = "user_id", nullable = false)
    private Integer user_id;

    @Column(name = "vocab_id", nullable = false)
    private Integer vocab_id;

    @Column(name = "question_id", nullable = false)
    private Integer question_id;

    @Column(name = "first_learned_at")
    private LocalDateTime first_learned_at;

    @Column(name = "last_reviewed_at")
    private LocalDateTime last_reviewed_at;

    // マスタリー値（初期値 1）
    @Column(name = "mastary_level", nullable = false)
    private Integer mastary_level;

    // 正解回数（初期値 0）
    @Column(name = "times_correct", nullable = false)
    private Integer times_correct;

    // ミス回数（初期値 0）
    @Column(name = "times_incorrect", nullable = false)
    private Integer times_incorrect;

    @PrePersist
    void onCreate() {
        if (mastary_level == null) mastary_level = 1;
        if (times_correct == null) times_correct = 0;
        if (times_incorrect == null) times_incorrect = 0;
        if (first_learned_at == null) first_learned_at = LocalDateTime.now();
        if (last_reviewed_at == null) last_reviewed_at = first_learned_at;
    }

    @PreUpdate
    void onUpdate() {
        if (last_reviewed_at == null) last_reviewed_at = LocalDateTime.now();
    }
}
