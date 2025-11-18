package com.example.api.entity;

import jakarta.persistence.*;

@Entity
@Table(
    name = "l_history",
    indexes = {
        @Index(name = "idx_l_history_user_id", columnList = "user_id")
    }
)
public class LHistory {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "l_history_id")
    private Long l_history_id;

    @Column(name = "user_id", nullable = false)
    private User user_id;

    // 仕様上は varchar(30)。日時文字列で保持する想定。
    @Column(name = "learning_at", length = 30, nullable = false)
    private String learning_at;

    // MySQL8のJSON型。アプリ側では文字列で扱う（必要なら後でJsonNode等に変更可）
    @Column(name = "questions", columnDefinition = "json", nullable = false)
    private String questions;

    @Column(name = "test_format", columnDefinition = "json", nullable = false)
    private String test_format;

    @Column(name = "questions_format", columnDefinition = "json", nullable = false)
    private String questions_format;

    @Column(name = "result", columnDefinition = "json", nullable = false)
    private String result;

    @Column(name = "learning_lang", length = 20, nullable = false)
    private String learning_lang;

    // ===== getters / setters =====
    public Long getL_history_id() { return l_history_id; }
    public void setL_history_id(Long l_history_id) { this.l_history_id = l_history_id; }

    public Long getUser_id() { return user_id; }
    public void setUser_id(Long user_id) { this.user_id = user_id; }

    public String getLearning_at() { return learning_at; }
    public void setLearning_at(String learning_at) { this.learning_at = learning_at; }

    public String getQuestions() { return questions; }
    public void setQuestions(String questions) { this.questions = questions; }

    public String getTest_format() { return test_format; }
    public void setTest_format(String test_format) { this.test_format = test_format; }

    public String getQuestions_format() { return questions_format; }
    public void setQuestions_format(String questions_format) { this.questions_format = questions_format; }

    public String getResult() { return result; }
    public void setResult(String result) { this.result = result; }

    public String getLearning_lang() { return learning_lang; }
    public void setLearning_lang(String learning_lang) { this.learning_lang = learning_lang; }
}
