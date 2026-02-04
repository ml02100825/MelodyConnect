package com.example.api.repository;

import com.example.api.entity.Item;
import com.example.api.entity.ItemStatus;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ItemRepository extends JpaRepository<Item, Integer> {
    Optional<Item> findByItemIdAndStatus(Integer itemId, ItemStatus status);
}
