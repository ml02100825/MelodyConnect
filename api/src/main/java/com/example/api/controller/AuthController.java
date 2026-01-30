package com.example.api.controller;

import com.example.api.dto.AuthResponse;
import com.example.api.dto.LoginRequest;
import com.example.api.dto.RefreshTokenRequest;
import com.example.api.dto.RegisterRequest;
import com.example.api.entity.User;
import com.example.api.service.AuthService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    @Autowired
    private AuthService authService;

    // 新規登録
    @PostMapping("/register")
    public ResponseEntity<AuthResponse> register(@Valid @RequestBody RegisterRequest request, 
                                                 HttpServletRequest servletRequest) {
        String userAgent = servletRequest.getHeader("User-Agent");
        String ip = servletRequest.getRemoteAddr();
        return ResponseEntity.ok(authService.register(request, userAgent, ip));
    }

    // ログイン
    @PostMapping("/login")
    public ResponseEntity<AuthResponse> login(@Valid @RequestBody LoginRequest request, 
                                              HttpServletRequest servletRequest) {
        String userAgent = servletRequest.getHeader("User-Agent");
        String ip = servletRequest.getRemoteAddr();
        return ResponseEntity.ok(authService.login(request, userAgent, ip));
    }

    @PostMapping("/refresh-token")
    public ResponseEntity<AuthResponse> refreshToken(@RequestBody RefreshTokenRequest request) {
        return ResponseEntity.ok(authService.refreshAccessToken(request.getRefreshToken()));
    }

    @PostMapping("/logout")
    public ResponseEntity<?> logout(@AuthenticationPrincipal User user) {
        authService.logout(user);
        return ResponseEntity.ok(Map.of("message", "ログアウトしました"));
    }

    @PostMapping("/withdraw")
    public ResponseEntity<?> withdraw(@AuthenticationPrincipal User user) {
        authService.withdraw(user);
        return ResponseEntity.ok(Map.of("message", "退会しました"));
    }
}