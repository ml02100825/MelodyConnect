package com.example.api.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "question")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class question {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "question_id", nullable = false)
    private Integer question_id;

    // 楽曲名ID（外部サービス由来想定）— 必須ではなさそうなのでnullable許可
    @Column(name = "songname_id")
    private Integer songname_id;

    // アーティスト名ID（外部サービス由来想定）
    @Column(name = "artistname_id")
    private Integer artistname_id;

    @Column(name = "text", nullable = false, length = 100)
    private String text;

    @Column(name = "answer", nullable = false, length = 100)
    private String answer;

    @Column(name = "adding_at", nullable = false)
    private LocalDateTime adding_at;

    // 問題形式（ENUMは文字列で保存）
    public enum Question_format {
        LISTENING
        // 必要に応じて以降を追加: READING, WRITING, SPEAKING, ... など
    }

    @Enumerated(EnumType.STRING)
    @Column(name = "question_format", nullable = false, length = 50)
    private Question_format question_format;

    // システム内の曲ID
    @Column(name = "song_id", nullable = false)
    private Integer song_id;

    // 難易度
    @Column(name = "difficulty_level", nullable = false)
    private Integer difficulty_level;

    @PrePersist
    void onCreate() {
        if (adding_at == null) adding_at = LocalDateTime.now();
    }
}
