package com.example.api.service.admin;

import com.example.api.dto.admin.AdminBadgeRequest;
import com.example.api.dto.admin.AdminBadgeResponse;
import com.example.api.entity.Badge;
import com.example.api.repository.BadgeRepository;
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
public class AdminBadgeService {

    private static final Logger logger = LoggerFactory.getLogger(AdminBadgeService.class);

    @Autowired
    private BadgeRepository badgeRepository;

    public AdminBadgeResponse.ListResponse getBadges(
            int page, int size, String idSearch, String badgeName, String acquisitionCondition,
            Integer mode, Boolean isActive, LocalDateTime createdFrom, LocalDateTime createdTo, String sortDirection) {
        Sort.Direction direction = parseSortDirection(sortDirection);
        Pageable pageable = PageRequest.of(page, size, Sort.by(direction, "id"));

        Specification<Badge> spec = (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();
            predicates.add(cb.equal(root.get("isDeleted"), false));

            if (badgeName != null && !badgeName.isEmpty()) {
                predicates.add(cb.like(root.get("badgeName"), "%" + badgeName + "%"));
            }
            if (acquisitionCondition != null && !acquisitionCondition.isEmpty()) {
                predicates.add(cb.like(root.get("acquisitionCondition"), "%" + acquisitionCondition + "%"));
            }
            if (idSearch != null && !idSearch.isEmpty()) {
                predicates.add(cb.equal(root.get("id").as(String.class), idSearch));
            }
            String modeValue = convertModeToValue(mode);
            if (modeValue != null) {
                predicates.add(cb.equal(root.get("mode"), modeValue));
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

        Page<Badge> badgePage = badgeRepository.findAll(spec, pageable);

        List<AdminBadgeResponse> badges = badgePage.getContent().stream()
                .map(this::toResponse)
                .collect(Collectors.toList());

        return new AdminBadgeResponse.ListResponse(badges, page, size, badgePage.getTotalElements(), badgePage.getTotalPages());
    }

    public AdminBadgeResponse getBadge(Long badgeId) {
        Badge badge = badgeRepository.findById(badgeId)
                .orElseThrow(() -> new IllegalArgumentException("バッジが見つかりません: " + badgeId));
        return toResponse(badge);
    }

    @Transactional
    public AdminBadgeResponse createBadge(AdminBadgeRequest request) {
        Badge badge = new Badge();
        updateFromRequest(badge, request);
        badge = badgeRepository.save(badge);
        logger.info("バッジ作成: {}", badge.getId());
        return toResponse(badge);
    }

    @Transactional
    public AdminBadgeResponse updateBadge(Long badgeId, AdminBadgeRequest request) {
        Badge badge = badgeRepository.findById(badgeId)
                .orElseThrow(() -> new IllegalArgumentException("バッジが見つかりません: " + badgeId));
        updateFromRequest(badge, request);
        badge = badgeRepository.save(badge);
        logger.info("バッジ更新: {}", badgeId);
        return toResponse(badge);
    }

    @Transactional
    public void deleteBadge(Long badgeId) {
        Badge badge = badgeRepository.findById(badgeId)
                .orElseThrow(() -> new IllegalArgumentException("バッジが見つかりません: " + badgeId));
        badge.setIsDeleted(true);
        badgeRepository.save(badge);
        logger.info("バッジ削除: {}", badgeId);
    }

    @Transactional
    public int enableBadges(List<Long> ids) {
        int count = 0;
        for (Long id : ids) {
            badgeRepository.findById(id).ifPresent(b -> {
                b.setActiveFlag(true);
                badgeRepository.save(b);
            });
            count++;
        }
        return count;
    }

    @Transactional
    public int disableBadges(List<Long> ids) {
        int count = 0;
        for (Long id : ids) {
            badgeRepository.findById(id).ifPresent(b -> {
                b.setActiveFlag(false);
                badgeRepository.save(b);
            });
            count++;
        }
        return count;
    }

    private void updateFromRequest(Badge badge, AdminBadgeRequest request) {
        badge.setBadgeName(request.getBadgeName());
        badge.setAcquisitionCondition(request.getAcquisitionCondition());
        badge.setImageUrl(request.getImageUrl());
        badge.setMode(convertModeToValue(request.getMode()));
        badge.setActiveFlag(request.getIsActive());
    }

    private AdminBadgeResponse toResponse(Badge badge) {
        AdminBadgeResponse response = new AdminBadgeResponse();
        response.setId(badge.getId());
        response.setBadgeName(badge.getBadgeName());
        response.setAcquisitionCondition(badge.getAcquisitionCondition());
        response.setImageUrl(badge.getImageUrl());
        response.setMode(convertModeToNumber(badge.getMode()));
        response.setIsActive(badge.isActiveFlag());
        response.setCreatedAt(badge.getCreatedAt());
        return response;
    }

    private String convertModeToValue(Integer mode) {
        if (mode == null) {
            return null;
        }
        return switch (mode) {
            case 1 -> "CONTINUE";
            case 2 -> "BATTLE";
            case 3 -> "RANKING";
            case 4 -> "COLLECT";
            case 5 -> "SPECIAL";
            default -> null;
        };
    }

    private Integer convertModeToNumber(String mode) {
        if (mode == null) {
            return null;
        }
        return switch (mode) {
            case "CONTINUE" -> 1;
            case "BATTLE" -> 2;
            case "RANKING" -> 3;
            case "COLLECT" -> 4;
            case "SPECIAL" -> 5;
            default -> null;
        };
    }

    private Sort.Direction parseSortDirection(String sortDirection) {
        if ("asc".equalsIgnoreCase(sortDirection)) {
            return Sort.Direction.ASC;
        }
        return Sort.Direction.DESC;
    }
}
