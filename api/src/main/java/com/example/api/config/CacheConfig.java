package com.example.api.config;

import com.github.benmanes.caffeine.cache.Caffeine;
import org.springframework.cache.CacheManager;
import org.springframework.cache.caffeine.CaffeineCacheManager;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.concurrent.TimeUnit;

/**
 * キャッシュ設定
 * Vocabulary検索のキャッシュ用
 */
@Configuration
public class CacheConfig {

    @Bean
    public CacheManager cacheManager() {
        CaffeineCacheManager cacheManager = new CaffeineCacheManager("vocabularyCache");
        cacheManager.setCaffeine(Caffeine.newBuilder()
                .maximumSize(1000)           // 最大1000単語をキャッシュ
                .expireAfterWrite(30, TimeUnit.MINUTES)  // 30分で期限切れ
                .recordStats());             // 統計情報を記録
        return cacheManager;
    }
}
