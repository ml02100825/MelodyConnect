package com.example.api.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.stream.Collectors;

/**
 * 管理者IP制限フィルター
 * /api/admin/** と /admin/** へのアクセスを許可されたIPのみに制限します
 */
@Component
public class AdminIpAllowlistFilter extends OncePerRequestFilter {

    private static final Logger logger = LoggerFactory.getLogger(AdminIpAllowlistFilter.class);

    private final List<String> allowedIps;

    public AdminIpAllowlistFilter(@Value("${admin.allowed-ips:}") String allowedIpsConfig) {
        if (allowedIpsConfig == null || allowedIpsConfig.trim().isEmpty()) {
            this.allowedIps = Collections.emptyList();
            logger.info("管理者IP制限は設定されていません（全IP許可）");
        } else {
            this.allowedIps = Arrays.stream(allowedIpsConfig.split(","))
                    .map(String::trim)
                    .filter(ip -> !ip.isEmpty())
                    .collect(Collectors.toList());
            logger.info("管理者許可IPリスト: {}", this.allowedIps);
        }
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {

        String requestUri = request.getRequestURI();

        // 管理者エンドポイントへのアクセスかチェック
        if (isAdminEndpoint(requestUri)) {
            // IP制限が設定されている場合のみチェック
            if (!allowedIps.isEmpty()) {
                String clientIp = getClientIp(request);
                logger.debug("管理者エンドポイントへのアクセス: URI={}, IP={}", requestUri, clientIp);

                if (!isIpAllowed(clientIp)) {
                    logger.warn("IP制限によりアクセス拒否: URI={}, IP={}", requestUri, clientIp);
                    response.setStatus(HttpServletResponse.SC_FORBIDDEN);
                    response.setContentType("application/json;charset=UTF-8");
                    response.getWriter().write("{\"error\": \"アクセスが許可されていません\"}");
                    return;
                }

                logger.debug("IP許可: {}", clientIp);
            }
        }

        filterChain.doFilter(request, response);
    }

    /**
     * 管理者エンドポイントかどうかを判定
     * @param uri リクエストURI
     * @return 管理者エンドポイントの場合true
     */
    private boolean isAdminEndpoint(String uri) {
        return uri.startsWith("/api/admin/") || uri.startsWith("/admin/");
    }

    /**
     * クライアントIPアドレスを取得
     * X-Forwarded-Forヘッダーを優先（プロキシ対応）
     * @param request HTTPリクエスト
     * @return クライアントIPアドレス
     */
    private String getClientIp(HttpServletRequest request) {
        String ip = request.getHeader("X-Forwarded-For");
        if (ip == null || ip.isEmpty() || "unknown".equalsIgnoreCase(ip)) {
            ip = request.getHeader("Proxy-Client-IP");
        }
        if (ip == null || ip.isEmpty() || "unknown".equalsIgnoreCase(ip)) {
            ip = request.getHeader("WL-Proxy-Client-IP");
        }
        if (ip == null || ip.isEmpty() || "unknown".equalsIgnoreCase(ip)) {
            ip = request.getHeader("HTTP_X_FORWARDED_FOR");
        }
        if (ip == null || ip.isEmpty() || "unknown".equalsIgnoreCase(ip)) {
            ip = request.getRemoteAddr();
        }

        // 複数のIPがある場合は最初のものを使用
        if (ip != null && ip.contains(",")) {
            ip = ip.split(",")[0].trim();
        }

        return ip;
    }

    /**
     * IPが許可されているかチェック
     * @param clientIp クライアントIP
     * @return 許可されている場合true
     */
    private boolean isIpAllowed(String clientIp) {
        if (clientIp == null) {
            return false;
        }

        // ローカルホストは常に許可
        if ("127.0.0.1".equals(clientIp) || "0:0:0:0:0:0:0:1".equals(clientIp) || "localhost".equals(clientIp)) {
            return true;
        }

        return allowedIps.contains(clientIp);
    }
}
