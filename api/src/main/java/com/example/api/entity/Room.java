package com.example.api.entity;

import java.time.LocalDateTime;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;

/**
 * room テーブル Entity
 * 物理名とカラム名は定義書に合わせています。
 */
@Entity
@Table(name = "room")
public class Room {

    public enum Status {
        WAITING, READY, PLAYING, FINISHED, CANCELED
    }

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "room_id")
    private Long room_id;

    @Column(name = "host_id", nullable = false)
    private Long host_id;

    @Column(name = "guest_id")
    private Long guest_id;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 20)
    private Status status;

    @Column(name = "host_ready", nullable = false)
    private boolean host_ready;

    @Column(name = "guest_ready", nullable = false)
    private boolean guest_ready;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime created_at;

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updated_at;

    @Column(name = "match_type", nullable = false)
    private Integer match_type;

    @Column(name = "selected_language",  length = 20)
    private String selected_language;

    @Column(name = "problem_type", length = 50)
    private String problem_type;

    @Column(name = "question_format", length = 50)
    private String question_format;

    // ---- lifecycle ----
    @PrePersist
    void onCreate() {
        LocalDateTime now = LocalDateTime.now();
        if (this.created_at == null) this.created_at = now;
        this.updated_at = now;

        if (this.status == null) this.status = Status.WAITING; // 既定: 待機
        if (this.match_type == null) this.match_type = 3;      // 既定: 3（定義書の初期値に合わせる）
        // host_ready / guest_ready は boolean 既定 false のままでOK
    }

    @PreUpdate
    void onUpdate() {
        this.updated_at = LocalDateTime.now();
    }

    // ---- getters / setters ----
    public Long getRoom_id() {
        return room_id;
    }

    public void setRoom_id(Long room_id) {
        this.room_id = room_id;
    }

    public Long getHost_id() {
        return host_id;
    }

    public void setHost_id(Long host_id) {
        this.host_id = host_id;
    }

    public Long getGuest_id() {
        return guest_id;
    }

    public void setGuest_id(Long guest_id) {
        this.guest_id = guest_id;
    }

    public Status getStatus() {
        return status;
    }

    public void setStatus(Status status) {
        this.status = status;
    }

    public boolean isHost_ready() {
        return host_ready;
    }

    public void setHost_ready(boolean host_ready) {
        this.host_ready = host_ready;
    }

    public boolean isGuest_ready() {
        return guest_ready;
    }

    public void setGuest_ready(boolean guest_ready) {
        this.guest_ready = guest_ready;
    }

    public LocalDateTime getCreated_at() {
        return created_at;
    }

    public void setCreated_at(LocalDateTime created_at) {
        this.created_at = created_at;
    }

    public LocalDateTime getUpdated_at() {
        return updated_at;
    }

    public void setUpdated_at(LocalDateTime updated_at) {
        this.updated_at = updated_at;
    }

    public Integer getMatch_type() {
        return match_type;
    }

    public void setMatch_type(Integer match_type) {
        this.match_type = match_type;
    }

    public String getSelected_language() {
        return selected_language;
    }

    public void setSelected_language(String selected_language) {
        this.selected_language = selected_language;
    }

    public String getProblem_type() {
        return problem_type;
    }

    public void setProblem_type(String problem_type) {
        this.problem_type = problem_type;
    }

    public String getQuestion_format() {
        return question_format;
    }

    public void setQuestion_format(String question_format) {
        this.question_format = question_format;
    }
}
