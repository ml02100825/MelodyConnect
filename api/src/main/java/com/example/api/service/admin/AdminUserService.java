package com.example.api.service.admin;

import com.example.api.dto.admin.AdminUserDetailResponse;
import com.example.api.dto.admin.AdminUserListResponse;
import com.example.api.dto.admin.AdminUserListResponse.AdminUserSummary;
import com.example.api.entity.User;
import com.example.api.repository.UserRepository;
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

/**
 * 管理者用ユーザー管理サービス
 */
@Service
public class AdminUserService {

    private static final Logger logger = LoggerFactory.getLogger(AdminUserService.class);

    @Autowired
    private UserRepository userRepository;

    /**
     * ユーザー一覧取得（検索・ページング対応）
     */
    public AdminUserListResponse getUsers(
            int page, int size,
            Long id, String userUuid, String username, String email,
            Boolean banFlag, Boolean subscribeFlag,
            LocalDateTime createdFrom, LocalDateTime createdTo,
            LocalDateTime offlineFrom, LocalDateTime offlineTo,
            LocalDateTime expiresFrom, LocalDateTime expiresTo,
            LocalDateTime canceledFrom, LocalDateTime canceledTo,
            String sortDirection) {

        Sort.Direction direction = parseSortDirection(sortDirection);
        Pageable pageable = PageRequest.of(page, size, Sort.by(direction, "id"));

        Specification<User> spec = (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();

            if (id != null) {
                predicates.add(cb.equal(root.get("id"), id));
            }
            if (userUuid != null && !userUuid.isEmpty()) {
                predicates.add(cb.like(root.get("userUuid"), "%" + userUuid + "%"));
            }
            if (username != null && !username.isEmpty()) {
                predicates.add(cb.like(root.get("username"), "%" + username + "%"));
            }
            if (email != null && !email.isEmpty()) {
                predicates.add(cb.like(root.get("mailaddress"), "%" + email + "%"));
            }
            if (banFlag != null) {
                predicates.add(cb.equal(root.get("banFlag"), banFlag));
            }
            if (subscribeFlag != null) {
                predicates.add(cb.equal(root.get("subscribeFlag"), subscribeFlag));
            }
            if (createdFrom != null) {
                predicates.add(cb.greaterThanOrEqualTo(root.get("createdAt"), createdFrom));
            }
            if (createdTo != null) {
                predicates.add(cb.lessThanOrEqualTo(root.get("createdAt"), createdTo));
            }
            if (offlineFrom != null) {
                predicates.add(cb.greaterThanOrEqualTo(root.get("offlineAt"), offlineFrom));
            }
            if (offlineTo != null) {
                predicates.add(cb.lessThanOrEqualTo(root.get("offlineAt"), offlineTo));
            }
            if (expiresFrom != null) {
                predicates.add(cb.greaterThanOrEqualTo(root.get("expiresAt"), expiresFrom));
            }
            if (expiresTo != null) {
                predicates.add(cb.lessThanOrEqualTo(root.get("expiresAt"), expiresTo));
            }
            if (canceledFrom != null) {
                predicates.add(cb.greaterThanOrEqualTo(root.get("canceledAt"), canceledFrom));
            }
            if (canceledTo != null) {
                predicates.add(cb.lessThanOrEqualTo(root.get("canceledAt"), canceledTo));
            }

            return cb.and(predicates.toArray(new Predicate[0]));
        };

        Page<User> userPage = userRepository.findAll(spec, pageable);

        List<AdminUserSummary> users = userPage.getContent().stream()
                .map(this::toUserSummary)
                .collect(Collectors.toList());

        return new AdminUserListResponse(
                users,
                page,
                size,
                userPage.getTotalElements(),
                userPage.getTotalPages()
        );
    }

    /**
     * ユーザー詳細取得
     */
    public AdminUserDetailResponse getUserDetail(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("ユーザーが見つかりません: " + userId));

        return toUserDetail(user);
    }

    /**
     * ユーザー一括停止
     */
    @Transactional
    public int freezeUsers(List<Long> userIds) {
        int count = 0;
        for (Long userId : userIds) {
            userRepository.findById(userId).ifPresent(user -> {
                user.setBanFlag(true);
                userRepository.save(user);
            });
            count++;
        }
        logger.info("ユーザー一括停止: {} 件", count);
        return count;
    }

    /**
     * ユーザー一括解除
     */
    @Transactional
    public int unfreezeUsers(List<Long> userIds) {
        int count = 0;
        for (Long userId : userIds) {
            userRepository.findById(userId).ifPresent(user -> {
                user.setBanFlag(false);
                userRepository.save(user);
            });
            count++;
        }
        logger.info("ユーザー一括解除: {} 件", count);
        return count;
    }

    private AdminUserSummary toUserSummary(User user) {
        AdminUserSummary summary = new AdminUserSummary();
        summary.setId(user.getId());
        summary.setUserUuid(user.getUserUuid());
        summary.setUsername(user.getUsername());
        summary.setEmail(user.getMailaddress());
        summary.setBanFlag(user.isBanFlag());
        summary.setSubscribeFlag(user.getSubscribeFlag() == 1 && user.getCancellationFlag() == 0);
        summary.setCreatedAt(user.getCreatedAt());
        summary.setOfflineAt(user.getOfflineAt());
        summary.setExpiresAt(user.getExpiresAt());
        summary.setCanceledAt(user.getCanceledAt());
        return summary;
    }

    private AdminUserDetailResponse toUserDetail(User user) {
        AdminUserDetailResponse detail = new AdminUserDetailResponse();
        detail.setId(user.getId());
        detail.setUserUuid(user.getUserUuid());
        detail.setUsername(user.getUsername());
        detail.setEmail(user.getMailaddress());
        detail.setBanFlag(user.isBanFlag());
        detail.setSubscribeFlag(user.getSubscribeFlag() == 1 && user.getCancellationFlag() == 0);
        detail.setCreatedAt(user.getCreatedAt());
        detail.setOfflineAt(user.getOfflineAt());
        detail.setAcceptedAt(user.getAcceptedAt());
        detail.setCanceledAt(user.getCanceledAt());
        return detail;
    }

    private Sort.Direction parseSortDirection(String sortDirection) {
        if ("asc".equalsIgnoreCase(sortDirection)) {
            return Sort.Direction.ASC;
        }
        return Sort.Direction.DESC;
    }
}
