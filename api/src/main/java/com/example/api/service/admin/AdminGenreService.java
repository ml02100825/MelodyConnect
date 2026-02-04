package com.example.api.service.admin;

import com.example.api.dto.admin.AdminGenreRequest;
import com.example.api.dto.admin.AdminGenreResponse;
import com.example.api.entity.Genre;
import com.example.api.repository.GenreRepository;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import jakarta.persistence.Query;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
public class AdminGenreService {

    private static final Logger logger = LoggerFactory.getLogger(AdminGenreService.class);

    @Autowired
    private GenreRepository genreRepository;

    @PersistenceContext
    private EntityManager entityManager;

    public AdminGenreResponse.ListResponse getGenres(
            int page, int size, String idSearch, String name, Boolean isActive,
            LocalDateTime createdFrom, LocalDateTime createdTo, String sortDirection) {
        
        Sort.Direction direction = parseSortDirection(sortDirection);
        StringBuilder fromClause = new StringBuilder(" FROM genre g WHERE 1=1");
        Map<String, Object> params = new HashMap<>();

        if (name != null && !name.isEmpty()) {
            fromClause.append(" AND g.name LIKE :name");
            params.put("name", "%" + name + "%");
        }
        if (idSearch != null && !idSearch.isEmpty()) {
            fromClause.append(" AND CAST(g.genre_id AS CHAR) = :genreId");
            params.put("genreId", idSearch);
        }
        if (isActive != null) {
            fromClause.append(" AND g.is_active = :isActive");
            params.put("isActive", isActive);
        }
        if (createdFrom != null) {
            fromClause.append(" AND g.created_at >= :createdFrom");
            params.put("createdFrom", createdFrom);
        }
        if (createdTo != null) {
            fromClause.append(" AND g.created_at <= :createdTo");
            params.put("createdTo", createdTo);
        }

        String orderBy = " ORDER BY g.genre_id " + (direction == Sort.Direction.ASC ? "ASC" : "DESC");
        String selectSql = "SELECT g.*" + fromClause + orderBy;
        String countSql = "SELECT COUNT(*)" + fromClause;

        Query dataQuery = entityManager.createNativeQuery(selectSql, Genre.class);
        Query countQuery = entityManager.createNativeQuery(countSql);
        params.forEach((key, value) -> {
            dataQuery.setParameter(key, value);
            countQuery.setParameter(key, value);
        });
        dataQuery.setFirstResult(page * size);
        dataQuery.setMaxResults(size);

        List<Genre> genres = dataQuery.getResultList();
        List<AdminGenreResponse> responses = genres.stream()
                .map(this::toResponse)
                .collect(Collectors.toList());

        long totalElements = ((Number) countQuery.getSingleResult()).longValue();
        int totalPages = (int) Math.ceil((double) totalElements / size);

        return new AdminGenreResponse.ListResponse(responses, page, size, totalElements, totalPages);
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
        
        // ★修正: getId() -> getGenreId()
        logger.info("ジャンル作成: {}", genre.getGenreId());
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
        // ★修正: getId() -> getGenreId()
        response.setId(genre.getGenreId());
        response.setName(genre.getName());
        response.setIsActive(genre.getIsActive());
        response.setCreatedAt(genre.getCreatedAt());
        return response;
    }

    private Sort.Direction parseSortDirection(String sortDirection) {
        if ("asc".equalsIgnoreCase(sortDirection)) {
            return Sort.Direction.ASC;
        }
        return Sort.Direction.DESC;
    }
}
