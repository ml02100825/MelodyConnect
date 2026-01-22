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
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class AdminBadgeService {

    private static final Logger logger = LoggerFactory.getLogger(AdminBadgeService.class);

    @Autowired
    private BadgeRepository badgeRepository;

    public AdminBadgeResponse.ListResponse getBadges(int page, int size, String badgeName, Boolean isActive) {
        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "id"));

        Specification<Badge> spec = (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();
            predicates.add(cb.equal(root.get("isDeleted"), false));

            if (badgeName != null && !badgeName.isEmpty()) {
                predicates.add(cb.like(root.get("badgeName"), "%" + badgeName + "%"));
            }
            if (isActive != null) {
                predicates.add(cb.equal(root.get("isActive"), isActive));
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
        badge.setMode(request.getMode());
        badge.setActiveFlag(request.getIsActive());
    }

    private AdminBadgeResponse toResponse(Badge badge) {
        AdminBadgeResponse response = new AdminBadgeResponse();
        response.setId(badge.getId());
        response.setBadgeName(badge.getBadgeName());
        response.setAcquisitionCondition(badge.getAcquisitionCondition());
        response.setImageUrl(badge.getImageUrl());
        response.setMode(badge.getMode());
        response.setIsActive(badge.isActiveFlag());
        response.setCreatedAt(badge.getCreatedAt());
        return response;
    }
}
