package com.example.api.security;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

/**
 * Spring Security設定クラス
 * JWT認証を使用したセキュリティ設定を行います
 */
@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Autowired
    private JwtAuthenticationFilter jwtAuthenticationFilter;

    /**
     * セキュリティフィルターチェーンの設定
     * @param http HttpSecurityオブジェクト
     * @return SecurityFilterChain
     * @throws Exception 設定エラー
     */
    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
                // CSRF保護を無効化（JWTを使用するため）
                .csrf(csrf -> csrf.disable())

                // セッションを使用しない（ステートレス認証）
                .sessionManagement(session ->
                        session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))

                // エンドポイントのアクセス権限設定
                .authorizeHttpRequests(auth -> auth
                        // 認証不要のエンドポイント
                        .requestMatchers("/api/auth/register").permitAll()
                        .requestMatchers("/api/auth/login").permitAll()
                        .requestMatchers("/api/auth/refresh").permitAll()
                        .requestMatchers("/actuator/**").permitAll()
                        .requestMatchers("/hello").permitAll()
                        .requestMatchers("/samples/**").permitAll()
                        // その他のエンドポイントは認証が必要
                        .anyRequest().authenticated()
                )

                // JWTフィルターをUsernamePasswordAuthenticationFilterの前に追加
                .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }
}
