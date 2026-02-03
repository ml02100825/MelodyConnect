package com.example.api.repository;

import com.example.api.entity.Item;
import com.example.api.entity.User;
import com.example.api.entity.UserItem;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;

public interface UserItemRepository extends JpaRepository<UserItem, Integer> {
    // ユーザーとアイテムで検索（フィールド名 user, item に対応）
    Optional<UserItem> findByUserAndItem(User user, Item item);
}