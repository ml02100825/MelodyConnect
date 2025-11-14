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

    @Value("${upload.directory:./uploads}")
    private String uploadDirectory;

    /**
     * CORS設定
     */
    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/**")
                .allowedOrigins("*")
                .allowedMethods("GET", "POST", "PUT", "DELETE", "OPTIONS")
                .allowedHeaders("*");
    }

    /**
     * 静的リソース設定
     * アップロードされた画像を提供できるようにします
     */
    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        // アップロードディレクトリを静的リソースとして公開
        registry.addResourceHandler("/uploads/**")
                .addResourceLocations("file:" + uploadDirectory + "/");
    }
}
