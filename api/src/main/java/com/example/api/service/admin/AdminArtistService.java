package com.example.api.service.admin;

import com.example.api.dto.admin.AdminArtistRequest;
import com.example.api.dto.admin.AdminArtistResponse;
import com.example.api.entity.Artist;
import com.example.api.repository.ArtistGenreRepository;
import com.example.api.repository.ArtistRepository;
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
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class AdminArtistService {

    private static final Logger logger = LoggerFactory.getLogger(AdminArtistService.class);

    @Autowired
    private ArtistRepository artistRepository;

    @Autowired
    private ArtistGenreRepository artistGenreRepository;

    public AdminArtistResponse.ListResponse getArtists(
            int page, int size, String idSearch, String artistName, String genreName, Boolean isActive,
            LocalDateTime createdFrom, LocalDateTime createdTo, String sortDirection) {
        Sort.Direction direction = parseSortDirection(sortDirection);
        Pageable pageable = PageRequest.of(page, size, Sort.by(direction, "artistId"));

        Specification<Artist> spec = (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();
            predicates.add(cb.equal(root.get("isDeleted"), false));

            if (artistName != null && !artistName.isEmpty()) {
                predicates.add(cb.like(root.get("artistName"), "%" + artistName + "%"));
            }
            if (idSearch != null && !idSearch.isEmpty()) {
                predicates.add(cb.equal(root.get("artistId").as(String.class), idSearch));
            }
            if (genreName != null && !genreName.isEmpty()) {
                List<Long> artistIds = artistGenreRepository.findArtistIdsByGenreName(genreName);
                if (artistIds.isEmpty()) {
                    predicates.add(cb.disjunction());
                } else {
                    predicates.add(root.get("artistId").in(artistIds));
                }
            }
            if (isActive != null) {
                predicates.add(cb.equal(root.get("isActive"), isActive));
            }
            if (createdFrom != null) {
                predicates.add(cb.greaterThanOrEqualTo(root.get("createdAt"), createdFrom));
            }
            if (createdTo != null) {
                predicates.add(cb.lessThanOrEqualTo(root.get("createdAt"), createdTo));
            }

            return cb.and(predicates.toArray(new Predicate[0]));
        };

        Page<Artist> artistPage = artistRepository.findAll(spec, pageable);

        List<AdminArtistResponse> artists = artistPage.getContent().stream()
                .map(this::toResponse)
                .collect(Collectors.toList());

        return new AdminArtistResponse.ListResponse(artists, page, size, artistPage.getTotalElements(), artistPage.getTotalPages());
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
