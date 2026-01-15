package com.example.api.repository;

import com.example.api.entity.Friend;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface FriendRepository extends JpaRepository<Friend, Long> {
    @Query(value = "SELECT CASE WHEN f.user_id_high = :userId THEN f.user_id_low ELSE f.user_id_high END " +
                   "FROM friend f " +
                   "WHERE (f.user_id_high = :userId OR f.user_id_low = :userId) " +
                   "AND ( (f.friend_flag IS NOT NULL AND f.friend_flag = 1) OR f.accepted_at IS NOT NULL )", nativeQuery = true)
    List<Long> findAcceptedFriendIdsByUserId(@Param("userId") Long userId);

    List<Friend> findByRequesterId(Long requesterId);
}