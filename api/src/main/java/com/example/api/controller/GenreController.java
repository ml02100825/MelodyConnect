package com.example.api.controller;

import com.example.api.entity.Genre;
import com.example.api.repository.GenreRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/genres")
public class GenreController {

    @Autowired
    private GenreRepository genreRepository;

    @GetMapping
    public List<Genre> getAllGenres() {
        // ★ここです！ここが findByIsActiveTrue() だと失敗します。
        // 必ず findGenresWithArtists() に書き換えてください。
        return genreRepository.findGenresWithArtists();
    }
}