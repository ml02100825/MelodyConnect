package com.example.api.entity;

import jakarta.persistence.*;

@Entity
@Table(name = "season")
public class Season {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // DB が 0/1 の場合は Integer でマッピング
    @Column(name = "active")
    private Integer active;

    @Column(name = "name", length = 64)
    private String name;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Integer getActive() { return active; }
    public void setActive(Integer active) { this.active = active; }

    public boolean isActive() { return active != null && active == 1; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
}