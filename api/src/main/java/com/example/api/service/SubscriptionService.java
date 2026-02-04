package com.example.api.service;

import com.example.api.entity.Item;
import com.example.api.entity.ItemStatus;
import com.example.api.entity.User;
import com.example.api.entity.UserItem;
import com.example.api.repository.ItemRepository;
import com.example.api.repository.UserItemRepository;
import com.example.api.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Optional;

@Service
public class SubscriptionService {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private ItemRepository itemRepository;

    @Autowired
    private UserItemRepository userItemRepository;

    // 回復アイテムのID（データベースのitemテーブルにこのIDが存在する必要があります）
    private static final int RECOVERY_ITEM_ID = 1;
    // 付与する個数
    private static final int BONUS_ITEM_AMOUNT = 10;

    /**
     * サブスクリプション登録・更新処理
     * ・有効期限の延長
     * ・特典アイテムの付与
     */
    @Transactional
    public void activateSubscription(User user) {
        System.out.println("--- サブスクリプション処理開始: UserID=" + user.getId() + " ---");

        // 1. ユーザーのサブスク情報を更新
        user.setSubscribeFlag(1);
        user.setCancellationFlag(0);
        
        // 有効期限の計算（現在時刻 or 現在の期限 の遅い方から +31日）
        LocalDateTime now = LocalDateTime.now();
        LocalDateTime baseTime = (user.getExpiresAt() != null && user.getExpiresAt().isAfter(now)) 
                               ? user.getExpiresAt() 
                               : now;
        user.setExpiresAt(baseTime.plusDays(31));
        
        userRepository.save(user);
        System.out.println("ユーザー情報を更新しました。期限: " + user.getExpiresAt());

        // 2. 特典アイテム付与
        grantRecoveryItem(user);
        
        System.out.println("--- サブスクリプション処理完了 ---");
    }

    /**
     * 回復アイテムを付与する内部メソッド
     */
    private void grantRecoveryItem(User user) {
        // アイテムマスタから取得
        Item recoveryItem = itemRepository.findByItemIdAndStatus(RECOVERY_ITEM_ID, ItemStatus.ACTIVE)
                .orElseThrow(() -> new RuntimeException(
                        "致命的エラー: アイテム(ID:" + RECOVERY_ITEM_ID + ")がDBに存在しません。itemテーブルを確認してください。"));

        // ユーザーの所持情報を検索
        Optional<UserItem> existingUserItem = userItemRepository.findByUserAndItem(user, recoveryItem);

        UserItem userItem;
        if (existingUserItem.isPresent()) {
            // 既に持っている場合
            userItem = existingUserItem.get();
            System.out.println("既存のアイテム所持データを発見: 現在" + userItem.getQuantity() + "個");
        } else {
            // 持っていない場合、新規作成
            userItem = new UserItem();
            userItem.setUser(user);
            userItem.setItem(recoveryItem);
            userItem.setQuantity(0);
            System.out.println("アイテム所持データを新規作成します");
        }

        // 個数を加算
        userItem.addQuantity(BONUS_ITEM_AMOUNT);

        // 強制的にDBへ反映 (saveAndFlush)
        userItemRepository.saveAndFlush(userItem);
        System.out.println("アイテムを付与しました。合計: " + userItem.getQuantity() + "個 (Saved to DB)");
    }
}
