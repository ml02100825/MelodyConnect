package com.example.api.config;

import com.example.api.service.ImageUploadService;
import com.example.api.service.LocalImageUploadService;
import com.example.api.service.S3ImageUploadService;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;

/**
 * 画像アップロード設定
 * 環境に応じてローカルストレージまたはS3を使用
 */
@Configuration
public class ImageUploadConfig {

    @Value("${upload.storage.type:local}")
    private String storageType;

    /**
     * 環境に応じた画像アップロードサービスを提供
     * @param localImageUploadService ローカルストレージサービス
     * @param s3ImageUploadService S3ストレージサービス
     * @return 選択された画像アップロードサービス
     */
    @Bean
    @Primary
    public ImageUploadService imageUploadService(
            LocalImageUploadService localImageUploadService,
            S3ImageUploadService s3ImageUploadService) {

        if ("s3".equalsIgnoreCase(storageType)) {
            return s3ImageUploadService;
        } else {
            return localImageUploadService;
        }
    }
}
