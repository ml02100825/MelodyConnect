package com.example.api.service;

import com.example.api.dto.ShopPurchaseRequest;
import com.example.api.dto.ShopPurchaseResponse;
import com.example.api.entity.Item;
import com.example.api.entity.User;
import com.example.api.entity.UserItem;
import com.example.api.entity.UserPaymentMethod;
import com.example.api.repository.ItemRepository;
import com.example.api.repository.UserItemRepository;
import com.example.api.repository.UserPaymentMethodRepository;
import com.example.api.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Optional;

@Service
public class ShopService {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private ItemRepository itemRepository;

    @Autowired
    private UserItemRepository userItemRepository;

    @Autowired
    private UserPaymentMethodRepository paymentMethodRepository;

    @Transactional
    public ShopPurchaseResponse purchase(Long userId, ShopPurchaseRequest request) {
        if (request.getItemId() == null || request.getQuantity() == null || request.getPaymentMethodId() == null) {
            throw new IllegalArgumentException("itemId, quantity, paymentMethodId are required.");
        }
        if (request.getQuantity() <= 0) {
            throw new IllegalArgumentException("quantity must be positive.");
        }

        Item item = itemRepository.findById(request.getItemId())
                .orElseThrow(() -> new IllegalArgumentException("item not found: " + request.getItemId()));
        if (!Boolean.TRUE.equals(item.getIsActive())) {
            throw new IllegalArgumentException("item is inactive: " + request.getItemId());
        }

        UserPaymentMethod paymentMethod = paymentMethodRepository.findById(request.getPaymentMethodId())
                .orElseThrow(() -> new IllegalArgumentException("payment method not found: " + request.getPaymentMethodId()));
        if (!paymentMethod.getUserId().equals(userId)) {
            throw new IllegalArgumentException("payment method does not belong to user.");
        }

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("user not found: " + userId));

        Optional<UserItem> existingUserItem = userItemRepository.findByUserAndItem(user, item);

        UserItem userItem;
        if (existingUserItem.isPresent()) {
            userItem = existingUserItem.get();
        } else {
            userItem = new UserItem();
            userItem.setUser(user);
            userItem.setItem(item);
            userItem.setQuantity(0);
        }

        userItem.addQuantity(request.getQuantity());
        userItemRepository.saveAndFlush(userItem);

        return new ShopPurchaseResponse(true, "購入が完了しました。", request.getQuantity());
    }
}
