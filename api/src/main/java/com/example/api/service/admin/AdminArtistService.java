package com.example.api.service.admin;

import com.example.api.dto.admin.AdminArtistRequest;
import com.example.api.dto.admin.AdminArtistResponse;
import com.example.api.entity.Artist;
import com.example.api.repository.ArtistGenreRepository;
import com.example.api.repository.ArtistRepository;
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
public class AdminArtistService {

    private static final Logger logger = LoggerFactory.getLogger(AdminArtistService.class);

    @Autowired
    private ArtistRepository artistRepository;

    @Autowired
    private ArtistGenreRepository artistGenreRepository;

    @PersistenceContext
    private EntityManager entityManager;

    public AdminArtistResponse.ListResponse getArtists(
            int page, int size, String idSearch, String artistName, String genreName, Boolean isActive,
            LocalDateTime createdFrom, LocalDateTime createdTo, String sortDirection) {
        Sort.Direction direction = parseSortDirection(sortDirection);

        StringBuilder fromClause = new StringBuilder(" FROM artist a WHERE 1=1");
        Map<String, Object> params = new HashMap<>();

        if (artistName != null && !artistName.isEmpty()) {
            fromClause.append(" AND a.artist_name LIKE :artistName");
            params.put("artistName", "%" + artistName + "%");
        }
        if (idSearch != null && !idSearch.isEmpty()) {
            fromClause.append(" AND CAST(a.artist_id AS CHAR) = :artistId");
            params.put("artistId", idSearch);
        }
        if (genreName != null && !genreName.isEmpty()) {
            List<Long> artistIds = artistGenreRepository.findArtistIdsByGenreName(genreName);
            if (artistIds.isEmpty()) {
                return new AdminArtistResponse.ListResponse(List.of(), page, size, 0, 0);
            }
            fromClause.append(" AND a.artist_id IN (:artistIds)");
            params.put("artistIds", artistIds);
        }
        if (isActive != null) {
            fromClause.append(" AND a.is_active = :isActive");
            params.put("isActive", isActive);
        }
        if (createdFrom != null) {
            fromClause.append(" AND a.created_at >= :createdFrom");
            params.put("createdFrom", createdFrom);
        }
        if (createdTo != null) {
            fromClause.append(" AND a.created_at <= :createdTo");
            params.put("createdTo", createdTo);
        }

        String orderBy = " ORDER BY a.artist_id " + (direction == Sort.Direction.ASC ? "ASC" : "DESC");
        String selectSql = "SELECT a.*" + fromClause + orderBy;
        String countSql = "SELECT COUNT(*)" + fromClause;

        Query dataQuery = entityManager.createNativeQuery(selectSql, Artist.class);
        Query countQuery = entityManager.createNativeQuery(countSql);
        params.forEach((key, value) -> {
            dataQuery.setParameter(key, value);
            countQuery.setParameter(key, value);
        });
        dataQuery.setFirstResult(page * size);
        dataQuery.setMaxResults(size);

        List<Artist> artists = dataQuery.getResultList();
        List<AdminArtistResponse> responses = artists.stream()
                .map(this::toResponse)
                .collect(Collectors.toList());

        long totalElements = ((Number) countQuery.getSingleResult()).longValue();
        int totalPages = (int) Math.ceil((double) totalElements / size);

        return new AdminArtistResponse.ListResponse(responses, page, size, totalElements, totalPages);
    }

    public AdminArtistResponse getArtist(Long artistId) {
        Artist artist = artistRepository.findById(artistId)
                .orElseThrow(() -> new IllegalArgumentException("アーティストが見つかりません: " + artistId));
        return toResponse(artist);
    }

    @Transactional
    public AdminArtistResponse createArtist(AdminArtistRequest request) {
        Artist artist = new Artist();
        updateFromRequest(artist, request);
        artist = artistRepository.save(artist);
        logger.info("アーティスト作成: {}", artist.getArtistId());
        return toResponse(artist);
    }

    @Transactional
    public AdminArtistResponse updateArtist(Long artistId, AdminArtistRequest request) {
        Artist artist = artistRepository.findById(artistId)
                .orElseThrow(() -> new IllegalArgumentException("アーティストが見つかりません: " + artistId));
        updateFromRequest(artist, request);
        artist = artistRepository.save(artist);
        logger.info("アーティスト更新: {}", artistId);
        return toResponse(artist);
    }

    @Transactional
    public void deleteArtist(Long artistId) {
        Artist artist = artistRepository.findById(artistId)
                .orElseThrow(() -> new IllegalArgumentException("アーティストが見つかりません: " + artistId));
        artist.setIsDeleted(true);
        artistRepository.save(artist);
        logger.info("アーティスト削除: {}", artistId);
    }

    @Transactional
    public int enableArtists(List<Long> ids) {
        int count = 0;
        for (Long id : ids) {
            artistRepository.findById(id).ifPresent(a -> {
                a.setIsActive(true);
                artistRepository.save(a);
            });
            count++;
        }
        return count;
    }

    @Transactional
    public int disableArtists(List<Long> ids) {
        int count = 0;
        for (Long id : ids) {
            artistRepository.findById(id).ifPresent(a -> {
                a.setIsActive(false);
                artistRepository.save(a);
            });
            count++;
        }
        return count;
    }

    private void updateFromRequest(Artist artist, AdminArtistRequest request) {
        artist.setArtistName(request.getArtistName());
        artist.setImageUrl(request.getImageUrl());
        artist.setArtistApiId(request.getArtistApiId());
        artist.setIsActive(request.getIsActive());
    }

    private AdminArtistResponse toResponse(Artist artist) {
        AdminArtistResponse response = new AdminArtistResponse();
        response.setArtistId(artist.getArtistId());
        response.setArtistName(artist.getArtistName());
        response.setGenreName(
                artistGenreRepository.findFirstGenreNameByArtistId(artist.getArtistId()).orElse(null));
        response.setImageUrl(artist.getImageUrl());
        response.setArtistApiId(artist.getArtistApiId());
        response.setIsActive(artist.getIsActive());
        response.setCreatedAt(artist.getCreatedAt());
        response.setLastSyncedAt(artist.getLastSyncedAt());
        return response;
    }

    private Sort.Direction parseSortDirection(String sortDirection) {
        if ("asc".equalsIgnoreCase(sortDirection)) {
            return Sort.Direction.ASC;
        }
        return Sort.Direction.DESC;
    }
}
