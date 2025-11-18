package com.example.api.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

/**
 * Web MVC設定
 * CORSと静的リソースの設定を行います
 */
@Configuration
public class WebConfig implements WebMvcConfigurer {

    @Value("${upload.storage.type:local}")
    private String storageType;

    @Value("${upload.local.directory:src/main/resources/static/uploads}")
    private String uploadDirectory;

    /**
     * CORS設定
     */
    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/**")
                .allowedOriginPatterns("*") // allowedOrigins("*")は動作しないため変更
                .allowedMethods("GET", "POST", "PUT", "DELETE", "OPTIONS")
                .allowedHeaders("*")
                .allowCredentials(true);
    }

    /**
     * 静的リソース設定
     * アップロードされた画像を提供できるようにします（ローカルストレージの場合のみ）
     */
    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        if ("local".equalsIgnoreCase(storageType)) {
            // クラスパスとファイルシステムの両方をサポート
            registry.addResourceHandler("/uploads/**")
                    .addResourceLocations(
                            "classpath:/static/uploads/",
                            "file:" + uploadDirectory + "/"
                    );
        }
    }
}
