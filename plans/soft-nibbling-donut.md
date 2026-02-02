# 登録画面から画面遷移しない問題の調査・修正プラン

## 問題概要
`register_screen.dart` から `profile_setup_screen.dart` への画面遷移が発生せず、開発者コンソールに403エラーが表示される。

---

## 発見された問題

### 問題1: 登録APIのステータスコード不一致 ⭐ 主要原因（遷移しない原因）
| 箇所 | 期待値 | 実際 |
|------|--------|------|
| フロント | `201` (Created) | - |
| バック ([AuthController.java:31](api/src/main/java/com/example/api/controller/AuthController.java#L31)) | - | `200` (OK) |

**影響**: 登録APIは成功しているが、フロントは201を期待しているため「登録に失敗しました」とエラー処理され、`profile_setup_screen` への遷移が実行されない。

### 問題2: トークンリフレッシュのエンドポイント不一致（403の原因）
| 箇所 | パス |
|------|------|
| フロント | `/api/auth/refresh` |
| バック ([AuthController.java:43](api/src/main/java/com/example/api/controller/AuthController.java#L43)) | `/api/auth/refresh-token` |
| SecurityConfig ([SecurityConfig.java:75](api/src/main/java/com/example/api/security/SecurityConfig.java#L75)) | `/api/auth/refresh` (permitAll) |

**影響**: `/api/auth/refresh` はSecurityConfigで許可されているが、バックエンドに実装がないため404。一方 `/api/auth/refresh-token` は実装があるが認証が必要なため403。

---

## 修正方針

**バックエンドをフロントエンドに合わせて修正する**（フロントエンドは変更しない）

---

## 修正内容

### 1. AuthController.java の修正

#### 1.1 register メソッドのレスポンス (行31)
```java
// 変更前
return ResponseEntity.ok(authService.register(request, userAgent, ip));

// 変更後
return ResponseEntity.status(HttpStatus.CREATED)
    .body(authService.register(request, userAgent, ip));
```
※ `import org.springframework.http.HttpStatus;` を追加

#### 1.2 refreshToken メソッドのエンドポイント (行43)
```java
// 変更前
@PostMapping("/refresh-token")

// 変更後
@PostMapping("/refresh")
```

---

## 修正対象ファイル

1. [api/src/main/java/com/example/api/controller/AuthController.java](api/src/main/java/com/example/api/controller/AuthController.java)

---

---

## 追加で発見された問題

### 問題3: 例外ハンドラーが存在しない ⭐ JSONパースエラーの原因

**症状**: 新規登録ボタンを押すと「FormatSyntaxError: Unexpected end of JSON input」

**原因**:
- `@RestControllerAdvice` や `GlobalExceptionHandler` が存在しない
- バリデーション失敗時やビジネスロジック例外時に、空のボディまたはHTMLエラーページが返される
- フロントの `jsonDecode()` がパースに失敗

---

## 追加の修正内容

### 2. GlobalExceptionHandler.java の新規作成

ファイル: `api/src/main/java/com/example/api/exception/GlobalExceptionHandler.java`

```java
package com.example.api.exception;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.util.Map;

@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Map<String, String>> handleValidationException(MethodArgumentNotValidException ex) {
        String message = ex.getBindingResult().getFieldErrors().stream()
            .map(e -> e.getDefaultMessage())
            .findFirst()
            .orElse("バリデーションエラー");
        return ResponseEntity.badRequest().body(Map.of("error", message));
    }

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<Map<String, String>> handleIllegalArgumentException(IllegalArgumentException ex) {
        return ResponseEntity.badRequest().body(Map.of("error", ex.getMessage()));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<Map<String, String>> handleGenericException(Exception ex) {
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
            .body(Map.of("error", "サーバーエラーが発生しました"));
    }
}
```

---

## 修正対象ファイル（更新）

1. [api/src/main/java/com/example/api/controller/AuthController.java](api/src/main/java/com/example/api/controller/AuthController.java) ✅ 完了
2. **新規作成**: `api/src/main/java/com/example/api/exception/GlobalExceptionHandler.java`

---

## 検証方法

1. バックエンドサーバーを再起動
2. フロントエンドを起動 (`flutter run -d chrome`)
3. 登録画面で新規ユーザーを登録
4. 登録成功後、`profile_setup_screen` に遷移することを確認
5. 開発者コンソールにエラーが出ないことを確認
