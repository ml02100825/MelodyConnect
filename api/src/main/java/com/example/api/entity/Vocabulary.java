package com.example.api.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;
import lombok.*;

@Entity
@Table(name = "vocabulary")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Vocabulary {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "vocab_id", nullable = false)
    private Integer vocab_id;

    @Column(name = "word", nullable = false, length = 50)
    private String word;

    // TEXT カラムは length を付けない。DB 方言に合わせるため columnDefinition を明示
    @Column(name = "meaning_ja", nullable = false, columnDefinition = "TEXT")
    private String meaning_ja;

    @Column(name = "pronunciation", length = 100)
    private String pronunciation;

    @Column(name = "part_of_speech", length = 50)
    private String part_of_speech;

    @Column(name = "example_sentence", columnDefinition = "TEXT")
    private String example_sentence;

    @Column(name = "example_translate", columnDefinition = "TEXT")
    private String example_translate;

    @Column(name = "audio_url", length = 500)
    private String audio_url;

    @Column(name = "created_at")
    private LocalDateTime created_at;

    @Column(name = "updated_at")
    private LocalDateTime updated_at;
}
