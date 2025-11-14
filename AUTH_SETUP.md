# 認証システムセットアップガイド

このドキュメントでは、MelodyConnectの認証システム（ユーザー登録・ログイン機能）について説明します。

## 技術スタック

- **フロントエンド**: Flutter
- **バックエンド**: Java Spring Boot 3.5.0
- **データベース**: MySQL
- **認証方式**: JWT (JSON Web Token)
- **パスワードハッシュ**: BCrypt

## システム構成

### バックエンド (Spring Boot)

#### 1. エンティティクラス

##### User エンティティ (`/api/src/main/java/com/example/api/entity/User.java`)
- `user_id`: ユーザーID (主キー)
- `email`: メールアドレス (ユニーク)
- `password_hash`: ハッシュ化されたパスワード
- `created_at`: 作成日時
- `updated_at`: 更新日時

##### Session エンティティ (`/api/src/main/java/com/example/api/entity/Session.java`)
- `session_id`: セッションID (主キー)
- `user_id`: ユーザーID (外部キー)
- `refresh_hash`: ハッシュ化されたリフレッシュトークン
- `expires_at`: 有効期限 (30日間)
- `user_agent`: デバイス/ブラウザ情報
- `ip`: IPアドレス
- `revoked_flag`: 無効化フラグ
- `created_at`: 作成日時

#### 2. API エンドポイント

##### POST `/api/auth/register`
ユーザー登録

**リクエスト:**
```json
{
  "email": "user@example.com",
  "password": "Password123!"
}
```

**レスポンス (201 Created):**
```json
{
  "userId": 1,
  "email": "user@example.com",
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expiresIn": 3600000
}
```

**バリデーション:**
- メールアドレス形式チェック
- パスワード要件:
  - 8文字以上100文字以下
  - 大文字を1文字以上含む
  - 小文字を1文字以上含む
  - 数字を1文字以上含む
  - 特殊文字(@$!%*?&#)を1文字以上含む

##### POST `/api/auth/login`
ログイン

**リクエスト:**
```json
{
  "email": "user@example.com",
  "password": "Password123!"
}
```

**レスポンス (200 OK):**
```json
{
  "userId": 1,
  "email": "user@example.com",
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expiresIn": 3600000
}
```

##### POST `/api/auth/refresh`
トークンリフレッシュ

**リクエスト:**
```json
{
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**レスポンス (200 OK):**
```json
{
  "userId": 1,
  "email": "user@example.com",
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expiresIn": 3600000
}
```

##### POST `/api/auth/logout/{userId}`
ログアウト

**ヘッダー:**
```
Authorization: Bearer {accessToken}
```

**レスポンス (200 OK):**
```json
{
  "message": "ログアウトしました"
}
```

#### 3. セキュリティ設定

- CSRF保護は無効化（JWTを使用するため）
- セッション管理はステートレス（STATELESS）
- 認証が不要なエンドポイント:
  - `/api/auth/register`
  - `/api/auth/login`
  - `/api/auth/refresh`
  - `/actuator/**`
  - `/hello`
  - `/samples/**`
- その他のエンドポイントは認証が必要

#### 4. JWT トークン

##### アクセストークン
- 有効期限: 1時間 (3,600,000ミリ秒)
- 用途: API リクエストの認証
- ヘッダーに含める: `Authorization: Bearer {token}`

##### リフレッシュトークン
- 有効期限: 30日 (2,592,000,000ミリ秒)
- 用途: アクセストークンの更新
- データベースにハッシュ化して保存

### フロントエンド (Flutter)

#### 1. サービスクラス

##### TokenStorageService (`/web/lib/services/token_storage_service.dart`)
- アクセストークン、リフレッシュトークン、ユーザー情報をローカルストレージに保存
- SharedPreferences を使用

##### AuthApiService (`/web/lib/services/auth_api_service.dart`)
- バックエンドAPIとの通信を担当
- 登録、ログイン、トークンリフレッシュ、ログアウト機能を提供

#### 2. 画面

##### LoginScreen (`/web/lib/screens/login_screen.dart`)
- メールアドレスとパスワードでログイン
- 新規登録画面への遷移
- 日本語UI

##### RegisterScreen (`/web/lib/screens/register_screen.dart`)
- メールアドレス、パスワード、パスワード確認入力
- リアルタイムバリデーション
- 日本語UI

## セットアップ手順

### 1. データベース初期化

データベースにテーブルを作成するSQLスクリプトは以下に配置されています:
- `/db/init/02_auth_schema.sql`

Docker Composeを使用している場合、自動的に実行されます。

### 2. バックエンド設定

#### application.properties

JWT秘密鍵は環境変数で設定できます:
```properties
jwt.secret=${JWT_SECRET:デフォルト秘密鍵}
```

**本番環境では必ず環境変数を設定してください:**
```bash
export JWT_SECRET="your-super-secret-key-here"
```

#### 依存関係

pom.xmlに以下の依存関係が追加されています:
- spring-boot-starter-data-jpa
- spring-boot-starter-security
- spring-boot-starter-validation
- jjwt (JSON Web Token)

### 3. フロントエンド設定

#### pubspec.yaml

以下の依存関係が追加されています:
- http: ^1.2.2
- shared_preferences: ^2.2.2
- provider: ^6.1.1

#### API Base URL

開発環境では `http://localhost:8080` を使用します。
本番環境では `/web/lib/services/auth_api_service.dart` の `baseUrl` を変更してください。

### 4. アプリケーション起動

#### バックエンド
```bash
cd api
./mvnw spring-boot:run
```

#### フロントエンド
```bash
cd web
flutter pub get
flutter run
```

## セキュリティ考慮事項

1. **JWT秘密鍵**: 本番環境では強力な秘密鍵を使用し、環境変数で管理してください
2. **HTTPS**: 本番環境では必ずHTTPSを使用してください
3. **CORS**: 本番環境では適切なオリジンを指定してください（現在は `*` を許可）
4. **パスワードハッシュ**: BCryptを使用して安全にハッシュ化されています
5. **セッション管理**: リフレッシュトークンはハッシュ化してデータベースに保存されています
6. **トークン有効期限**: アクセストークンは1時間、リフレッシュトークンは30日で期限切れになります

## トラブルシューティング

### データベース接続エラー
- docker-compose.ymlでMySQLが起動しているか確認
- application.propertiesのデータベース設定を確認

### JWT検証エラー
- アクセストークンの有効期限を確認
- JWT秘密鍵が正しく設定されているか確認

### CORS エラー
- バックエンドのCORS設定を確認
- フロントエンドのAPIベースURLを確認

## 今後の拡張案

1. メールアドレス確認機能
2. パスワードリセット機能
3. 二要素認証 (2FA)
4. ソーシャルログイン (Google, Facebookなど)
5. セッション管理画面（アクティブなセッションの表示・無効化）
6. パスワード変更機能
7. ユーザープロフィール管理
