package com.example.api.service.admin;

import com.example.api.dto.admin.AdminBadgeRequest;
import com.example.api.dto.admin.AdminBadgeResponse;
import com.example.api.entity.Badge;
import com.example.api.repository.BadgeRepository;
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
import java.time.ZoneId;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
public class AdminBadgeService {

    private static final Logger logger = LoggerFactory.getLogger(AdminBadgeService.class);

    @Autowired
    private BadgeRepository badgeRepository;

    @PersistenceContext
    private EntityManager entityManager;

    public AdminBadgeResponse.ListResponse getBadges(
            int page, int size, String idSearch, String badgeName, String acquisitionCondition,
            Integer mode, Boolean isActive, LocalDateTime createdFrom, LocalDateTime createdTo, String sortDirection) {
        Sort.Direction direction = parseSortDirection(sortDirection);

        StringBuilder fromClause = new StringBuilder(" FROM badge b WHERE 1=1");
        Map<String, Object> params = new HashMap<>();

        if (badgeName != null && !badgeName.isEmpty()) {
            fromClause.append(" AND b.badge_name LIKE :badgeName");
            params.put("badgeName", "%" + badgeName + "%");
        }
        if (acquisitionCondition != null && !acquisitionCondition.isEmpty()) {
            fromClause.append(" AND b.acq_cond LIKE :acquisitionCondition");
            params.put("acquisitionCondition", "%" + acquisitionCondition + "%");
        }
        if (idSearch != null && !idSearch.isEmpty()) {
            fromClause.append(" AND CAST(b.badge_id AS CHAR) = :badgeId");
            params.put("badgeId", idSearch);
        }
        if (mode != null) {
            fromClause.append(" AND b.mode = :mode");
            params.put("mode", mode);
        }
        if (isActive != null) {
            fromClause.append(" AND b.is_active = :isActive");
            params.put("isActive", isActive);
        }
        if (createdFrom != null) {
            fromClause.append(" AND b.created_at >= :createdFrom");
            params.put("createdFrom", createdFrom);
        }
        if (createdTo != null) {
            fromClause.append(" AND b.created_at <= :createdTo");
            params.put("createdTo", createdTo);
        }

        String orderBy = " ORDER BY b.badge_id " + (direction == Sort.Direction.ASC ? "ASC" : "DESC");
        String selectSql = "SELECT b.badge_id, b.badge_name, b.acq_cond, b.image_url, b.mode, " +
                "b.is_active, b.is_deleted, b.created_at" + fromClause + orderBy;
        String countSql = "SELECT COUNT(*)" + fromClause;

        Query dataQuery = entityManager.createNativeQuery(selectSql);
        Query countQuery = entityManager.createNativeQuery(countSql);
        params.forEach((key, value) -> {
            dataQuery.setParameter(key, value);
            countQuery.setParameter(key, value);
        });
        dataQuery.setFirstResult(page * size);
        dataQuery.setMaxResults(size);

        List<Object[]> rows = dataQuery.getResultList();
        List<AdminBadgeResponse> badges = rows.stream()
                .map(this::toResponse)
                .collect(Collectors.toList());

        long totalElements = ((Number) countQuery.getSingleResult()).longValue();
        int totalPages = (int) Math.ceil((double) totalElements / size);

        return new AdminBadgeResponse.ListResponse(badges, page, size, totalElements, totalPages);
    }

    public AdminBadgeResponse getBadge(Long badgeId) {
        Query dataQuery = entityManager.createNativeQuery(
                "SELECT * FROM badge WHERE badge_id = :badgeId", Badge.class);
        dataQuery.setParameter("badgeId", badgeId);
        @SuppressWarnings("unchecked")
        List<Badge> badges = dataQuery.getResultList();
        if (badges.isEmpty()) {
            throw new IllegalArgumentException("バッジが見つかりません: " + badgeId);
        }
        return toResponse(badges.get(0));
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
        int updated = entityManager.createNativeQuery(
                "UPDATE badge SET is_deleted = true WHERE badge_id = :badgeId")
            .setParameter("badgeId", badgeId)
            .executeUpdate();
        if (updated == 0) {
            throw new IllegalArgumentException("バッジが見つかりません: " + badgeId);
        }
        logger.info("バッジ削除: {}", badgeId);
    }

    @Transactional
    public void restoreBadge(Long badgeId) {
        int updated = entityManager.createNativeQuery(
                "UPDATE badge SET is_deleted = false WHERE badge_id = :badgeId")
            .setParameter("badgeId", badgeId)
            .executeUpdate();
        if (updated == 0) {
            throw new IllegalArgumentException("バッジが見つかりません: " + badgeId);
        }
        logger.info("バッジ削除解除: {}", badgeId);
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
        response.setIsDeleted(badge.getIsDeleted());
        response.setCreatedAt(badge.getCreatedAt());
        return response;
    }

    private AdminBadgeResponse toResponse(Object[] row) {
        AdminBadgeResponse response = new AdminBadgeResponse();
        response.setId(row[0] != null ? ((Number) row[0]).longValue() : null);
        response.setBadgeName((String) row[1]);
        response.setAcquisitionCondition((String) row[2]);
        response.setImageUrl((String) row[3]);
        response.setMode(row[4] != null ? ((Number) row[4]).intValue() : null);
        response.setIsActive(row[5] != null ? (Boolean) row[5] : null);
        response.setIsDeleted(row[6] != null ? (Boolean) row[6] : null);
        response.setCreatedAt(toLocalDateTime(row[7]));
        return response;
    }

    private LocalDateTime toLocalDateTime(Object value) {
        if (value == null) {
            return null;
        }
        if (value instanceof LocalDateTime) {
            return (LocalDateTime) value;
        }
        if (value instanceof java.sql.Timestamp) {
            return ((java.sql.Timestamp) value).toLocalDateTime();
        }
        if (value instanceof java.util.Date) {
            return ((java.util.Date) value).toInstant().atZone(ZoneId.systemDefault()).toLocalDateTime();
        }
        throw new IllegalArgumentException("Unsupported date type: " + value.getClass());
    }

    private Sort.Direction parseSortDirection(String sortDirection) {
        if ("asc".equalsIgnoreCase(sortDirection)) {
            return Sort.Direction.ASC;
        }
        return Sort.Direction.DESC;
    }
}
