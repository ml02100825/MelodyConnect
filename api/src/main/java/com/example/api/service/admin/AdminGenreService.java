package com.example.api.service.admin;

import com.example.api.dto.admin.AdminGenreRequest;
import com.example.api.dto.admin.AdminGenreResponse;
import com.example.api.entity.Genre;
import com.example.api.repository.GenreRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import jakarta.persistence.criteria.Predicate;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class AdminGenreService {

    private static final Logger logger = LoggerFactory.getLogger(AdminGenreService.class);

    @Autowired
    private GenreRepository genreRepository;

    public AdminGenreResponse.ListResponse getGenres(int page, int size, String name, Boolean isActive) {
        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "id"));

        Specification<Genre> spec = (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();
            predicates.add(cb.equal(root.get("isDeleted"), false));

            if (name != null && !name.isEmpty()) {
                predicates.add(cb.like(root.get("name"), "%" + name + "%"));
            }
            if (isActive != null) {
                predicates.add(cb.equal(root.get("isActive"), isActive));
            }

            return cb.and(predicates.toArray(new Predicate[0]));
        };

        Page<Genre> genrePage = genreRepository.findAll(spec, pageable);

        List<AdminGenreResponse> genres = genrePage.getContent().stream()
                .map(this::toResponse)
                .collect(Collectors.toList());

        return new AdminGenreResponse.ListResponse(genres, page, size, genrePage.getTotalElements(), genrePage.getTotalPages());
    }

    public AdminGenreResponse getGenre(Long genreId) {
        Genre genre = genreRepository.findById(genreId)
                .orElseThrow(() -> new IllegalArgumentException("ジャンルが見つかりません: " + genreId));
        return toResponse(genre);
    }

    @Transactional
    public AdminGenreResponse createGenre(AdminGenreRequest request) {
        Genre genre = new Genre();
        genre.setName(request.getName());
        genre.setIsActive(request.getIsActive());
        genre = genreRepository.save(genre);
        logger.info("ジャンル作成: {}", genre.getId());
        return toResponse(genre);
    }

    @Transactional
    public AdminGenreResponse updateGenre(Long genreId, AdminGenreRequest request) {
        Genre genre = genreRepository.findById(genreId)
                .orElseThrow(() -> new IllegalArgumentException("ジャンルが見つかりません: " + genreId));
        genre.setName(request.getName());
        genre.setIsActive(request.getIsActive());
        genre = genreRepository.save(genre);
        logger.info("ジャンル更新: {}", genreId);
        return toResponse(genre);
    }

    @Transactional
    public void deleteGenre(Long genreId) {
        Genre genre = genreRepository.findById(genreId)
                .orElseThrow(() -> new IllegalArgumentException("ジャンルが見つかりません: " + genreId));
        genre.setIsDeleted(true);
        genreRepository.save(genre);
        logger.info("ジャンル削除: {}", genreId);
    }

    @Transactional
    public int enableGenres(List<Long> ids) {
        int count = 0;
        for (Long id : ids) {
            genreRepository.findById(id).ifPresent(g -> {
                g.setIsActive(true);
                genreRepository.save(g);
            });
            count++;
        }
        return count;
    }

    @Transactional
    public int disableGenres(List<Long> ids) {
        int count = 0;
        for (Long id : ids) {
            genreRepository.findById(id).ifPresent(g -> {
                g.setIsActive(false);
                genreRepository.save(g);
            });
            count++;
        }
        return count;
    }

    private AdminGenreResponse toResponse(Genre genre) {
        AdminGenreResponse response = new AdminGenreResponse();
        response.setId(genre.getId());
        response.setName(genre.getName());
        response.setIsActive(genre.getIsActive());
        response.setCreatedAt(genre.getCreatedAt());
        return response;
    }
}
