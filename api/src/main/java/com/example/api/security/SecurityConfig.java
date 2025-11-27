package com.example.api.security;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configuration.WebSecurityCustomizer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.Arrays;

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
     * Securityフィルタの対象外にするパス設定
     * ここに指定したパスは Spring Security 自体を通らない
     */
    @Bean
    public WebSecurityCustomizer webSecurityCustomizer() {
        return (web) -> web.ignoring()
                // アップロード画像は完全にセキュリティの外に出す
                .requestMatchers("/uploads/**");
    }

    /**
     * CORS設定
     */
    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();
        configuration.setAllowedOriginPatterns(Arrays.asList("*"));
        configuration.setAllowedMethods(Arrays.asList("GET", "POST", "PUT", "DELETE", "OPTIONS"));
        configuration.setAllowedHeaders(Arrays.asList("*"));
        configuration.setAllowCredentials(true);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", configuration);
        return source;
    }

    /**
     * セキュリティフィルターチェーンの設定
     */
    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
                // CSRF保護を無効化（JWTを使用するため）
                .csrf(csrf -> csrf.disable())

                // CORS設定を有効化
                .cors(cors -> cors.configurationSource(corsConfigurationSource()))

                // セッションを使用しない（ステートレス認証）
                .sessionManagement(session ->
                        session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))

                // エンドポイントのアクセス権限設定
                .authorizeHttpRequests(auth -> auth
                        // CORSプリフライトリクエストを許可
                        .requestMatchers(org.springframework.http.HttpMethod.OPTIONS, "/**").permitAll()

                        // 認証不要のエンドポイント（認証API）
                        .requestMatchers("/api/auth/register").permitAll()
                        .requestMatchers("/api/auth/login").permitAll()
                        .requestMatchers("/api/auth/refresh").permitAll()

                        // ファイルアップロードAPI
                        .requestMatchers("/api/upload/**").permitAll()

                        // 画像本体（実際は webSecurityCustomizer で ignore 済み）
                        .requestMatchers("/uploads/**").permitAll()

                        // TTS音声ファイル
                        .requestMatchers("/audio/**").permitAll()

                        // WebSocket関連
                        .requestMatchers("/ws/**").permitAll()
                        .requestMatchers("/app/**").permitAll()
                        .requestMatchers("/topic/**").permitAll()
                        .requestMatchers("/queue/**").permitAll()

                        // その他公開エンドポイント
                        .requestMatchers("/actuator/**").permitAll()
                        .requestMatchers("/hello").permitAll()
                        .requestMatchers("/samples/**").permitAll()
                        .requestMatchers("/api/dev/**").permitAll()

                        // ★ デバッグ用：フレンド承認APIはいったん誰でもOK（403切り分け用）
                        .requestMatchers("/api/friend/accept").permitAll()

                        // それ以外の friend API は認証必須
                        .requestMatchers("/api/friend/**").authenticated()

                        // その他は全部認証必須
                        .anyRequest().authenticated()
                )

                // JWTフィルターをUsernamePasswordAuthenticationFilterの前に追加
                .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }
}
