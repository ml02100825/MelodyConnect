package com.example.api.controller;

import com.example.api.entity.Genre;
import com.example.api.repository.GenreRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * ジャンル関連のAPIエンドポイントを提供するコントローラー
 */
@RestController
@RequestMapping("/api/genres")
public class GenreController {

    @Autowired
    private GenreRepository genreRepository;

    /**
     * 有効なアーティストが登録されているジャンル一覧を取得します。
     * * <p>単純な全件取得ではなく、以下の条件を満たすもののみを返します：</p>
     * <ul>
     * <li>紐付いているアーティストが1名以上存在する</li>
     * <li>そのアーティストが有効(active=1)かつ削除されていない(deleted=0)</li>
     * <li>ジャンル自体が有効である</li>
     * <li>システム用ジャンル('other')ではない</li>
     * </ul>
     * * @return フィルタリング済みのジャンルリスト
     */
    @GetMapping
    public List<Genre> getAllGenres() {
        return genreRepository.findGenresWithArtists();
    }
}