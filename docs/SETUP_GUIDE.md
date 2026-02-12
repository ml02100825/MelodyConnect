# MelodyConnect セットアップ・操作手順書

---

## 1. システム概要

| 層 | 技術 |
|---|---|
| フロントエンド | Flutter (Web) |
| バックエンド | Spring Boot 3.5.0 (Java) |
| データベース | MySQL 8 |
| インフラ | Docker / Docker Compose |
| ファイルストレージ | AWS S3 |

---

## 2. 事前に必要なもの（ソフトウェア）

| ソフトウェア | 用途 | 確認コマンド |
|---|---|---|
| Docker Desktop | コンテナ実行 | `docker --version` |
| Docker Compose | 複数コンテナ管理 | `docker compose version` |
| Flutter SDK (3.x) | フロントエンドビルド | `flutter --version` |

---

## 3. 事前取得が必要なAPI・サービス一覧

### 3-1. Google Gemini API（必須）
**用途**: 問題生成・翻訳・単語原形変換

**取得手順**:
1. https://aistudio.google.com/ にアクセス
2. Googleアカウントでサインイン
3. 「Get API key」→「Create API key」をクリック
4. 生成されたキーをコピー → `.env` の `GEMINI_API_KEY` に設定

---

### 3-2. Spotify API（必須）
**用途**: 楽曲検索・アーティスト情報取得

**取得手順**:
1. https://developer.spotify.com/dashboard にアクセス
2. Spotifyアカウントでログイン（なければ無料登録）
3. 「Create app」をクリック
4. 以下を入力して作成:
   - App name: `MelodyConnect`（任意）
   - App description: 任意
   - Redirect URIs: `https://example.com/callback`
5. 作成後、「Client ID」と「Client Secret」をコピー
   → `SPOTIFY_CLIENT_ID` / `SPOTIFY_CLIENT_SECRET` に設定

---

### 3-3. Genius API（必須）
**用途**: 歌詞データ取得

**取得手順**:
1. https://genius.com/api-clients にアクセス
2. Geniusアカウントでログイン（なければ無料登録）
3. 「New API Client」をクリック
4. 以下を入力:
   - App name: `MelodyConnect`（任意）
   - Homepage URL: `http://localhost`
5. 「Generate Access Token」をクリック → トークンをコピー
   → `GENIUS_API_KEY` に設定

---

### 3-4. Wordnik API（必須）
**用途**: 英単語の定義・発音情報取得

**取得手順**:
1. https://developer.wordnik.com/ にアクセス
2. 「Get an API key」からアカウント登録
3. ダッシュボードにてAPIキーを取得
   → `WORDNIK_API_KEY` に設定

---

### 3-5. Google Cloud Text-to-Speech API（必須）
**用途**: リスニング問題の音声生成

**取得手順**:
1. https://console.cloud.google.com/ にアクセス
2. プロジェクトを作成（または既存のプロジェクトを選択）
3. 左メニュー「APIとサービス」→「ライブラリ」→ `Cloud Text-to-Speech API` を検索 → 「有効にする」
4. 「APIとサービス」→「認証情報」→「認証情報を作成」→「APIキー」
5. 生成されたキーをコピー
   → `GOOGLE_CLOUD_API_KEY` に設定
   ※ セキュリティのため「Text-to-Speech API」のみに制限することを推奨

---

### 3-6. AWS S3（必須）
**用途**: プロフィール画像・音声ファイルのストレージ

**取得手順**:
1. Learner Labを起動する
2. **S3バケット作成**:
   - AWSコンソール → S3 → 「バケットを作成」
   - バケット名を決定（例: `melodyconnect-uploads`）
   - 「任意のパブリックバケットポリシーまたはアクセスポイントポリシーを介したバケットとオブジェクトへのパブリックアクセスとクロスアカウントアクセスをブロックする」のみ許可
   - バケットポリシーを下記にし設定
      {
      "Version": "2012-10-17",
      "Statement": [
         {
               "Sid": "AllowPublicReadImages",
               "Effect": "Allow",
               "Principal": "*",
               "Action": "s3:GetObject",
               "Resource": "arn:aws:s3:::${YOUR_BUCKET_NAME}/*uploads/images/*"
         }
      ]
   }
   - CORSを下記に設定
            [
         {
            "AllowedHeaders": [
                  "*"
            ],
            "AllowedMethods": [
                  "GET",
                  "HEAD"
            ],
            "AllowedOrigins": [
                  "*"
            ],
            "ExposeHeaders": [
                  "Accept-Ranges",
                  "Content-Range",
                  "Content-Length"
            ],
            "MaxAgeSeconds": 3000
         }
      ]

3.　'AWS_S3_BUCKET_NAME'にバケット名を設定
   
    'AWS_S3_REGION'にリージョンを設定

    下記三つにはLearner Lab起動後AWSDetails→AWSCLIから設定。
    'AWS_ACCESS_KEY_ID'
    'AWS_SECRET_ACCESS_KEY'
    'AWS_SESSION_TOKEN'


---

### 3-7. Gmailアプリパスワード（必須）
**用途**: 会員登録確認・パスワードリセットのメール送信

**取得手順**:
1. 送信元として使うGoogleアカウントで **2段階認証を有効化**
   - https://myaccount.google.com/security → 「2段階認証プロセス」→ オン
2. https://myaccount.google.com/apppasswords にアクセス
3. 「アプリを選択」→「その他（カスタム名）」→ `MelodyConnect` と入力
4. 「生成」をクリック → 表示された16桁のパスワードをコピー
   → `MAIL_USERNAME` に Gmailアドレス（例: `your.email@gmail.com`）
   → `MAIL_PASSWORD` にアプリパスワード（スペースを除いた16文字）を設定

---



## 4. 環境変数ファイル（.env）の作成

プロジェクトルート（`docker-compose.yml` と同じ階層）に `.env` ファイルを作成します。

```env
# ========================================
# データベース設定
# ========================================
MYSQL_ROOT_PASSWORD=your_root_password_here
MYSQL_DATABASE=MelodyConnectdb
MYSQL_USER=appuser
MYSQL_PASSWORD=your_db_password_here

# ========================================
# JWT設定（64文字以上のランダムな文字列を推奨）
# ========================================
JWT_SECRET=your_jwt_secret_at_least_64_chars_long_random_string_here

# ========================================
# メール設定（Gmail）
# ========================================
MAIL_USERNAME=your.email@gmail.com
MAIL_PASSWORD=your_app_password_16chars

# ========================================
# Gemini API
# ========================================
GEMINI_API_KEY=your_gemini_api_key_here

# ========================================
# Spotify API
# ========================================
SPOTIFY_CLIENT_ID=your_spotify_client_id_here
SPOTIFY_CLIENT_SECRET=your_spotify_client_secret_here

# ========================================
# Wordnik API
# ========================================
WORDNIK_API_KEY=your_wordnik_api_key_here

# ========================================
# Genius API
# ========================================
GENIUS_API_KEY=your_genius_api_key_here

# ========================================
# Google Cloud TTS API
# ========================================
GOOGLE_CLOUD_API_KEY=your_google_cloud_api_key_here

# ========================================
# AWS S3
# ========================================
AWS_S3_BUCKET_NAME=your-bucket-name
AWS_S3_REGION=ap-northeast-1
AWS_ACCESS_KEY_ID=your_aws_access_key_id
AWS_SECRET_ACCESS_KEY=your_aws_secret_access_key
AWS_SESSION_TOKEN=

# ========================================
# 管理者設定（空白で全IP許可）
# ========================================
ADMIN_ALLOWED_IPS=
```

---

## 5. バックエンド起動手順（Docker Compose）

```bash
# 1. プロジェクトルートへ移動
cd /path/to/MelodyConnect

# 2. .envファイルが存在することを確認
ls .env

# 3. コンテナビルド＆起動（初回はビルドに数分かかる）
docker compose up --build -d

# 4. 起動ログを確認
docker compose logs -f api


```

**起動順序**: `db` (MySQL) がヘルスチェック通過後 → `api` (Spring Boot) が起動
**APIアクセス先**: `http://localhost:8080`
**データベースポート**: `3306`

---

## 6. フロントエンド起動手順（Flutter）

### 6-1. 依存関係のインストール
```bash
cd /path/to/MelodyConnect/web
flutter pub get
```

### 6-2. API接続先の設定
[web/assets/config.json](../web/assets/config.json) を確認・編集:
```json
{
  "apiBaseUrl": "http://localhost:8080"
}
```
※ 本番環境ではデプロイ先のURLに変更してください

### 6-3. 開発サーバー起動
```bash
# Chromeブラウザで起動
flutter run -d chrome

# または特定ポートを指定する場合
flutter run -d web-server --web-port 3000
```

---

## 7. 動作確認チェックリスト

| # | 確認項目 | 確認方法 |
|---|---|---|
| 1 | バックエンド起動 | `curl http://localhost:8080/actuator/health` → `{"status":"UP"}` |
| 2 | DB接続 | `docker compose logs api` でエラーなし |
| 3 | ユーザー登録 | メールアドレスで新規登録 → 確認メール受信 |
| 4 | ログイン | ログイン → ホーム画面表示 |
| 5 | 楽曲検索 | 学習設定でSpotify楽曲を検索・選択 |
| 6 | 問題生成 | 楽曲選択 → GeminiAPIで問題生成（数秒） |
| 7 | 音声再生 | リスニング問題の音声再生（Google TTS） |
| 8 | 画像アップロード | プロフィール画像のアップロード（S3） |
| 9 | 対戦マッチング | ランクマッチ開始 → WebSocket接続でマッチング |

---

## 8. トラブルシューティング

| 症状 | 主な原因 | 対処方法 |
|---|---|---|
| APIコンテナが起動しない | DBのヘルスチェック未通過 | `docker compose logs db` を確認 |
| メールが届かない | Gmailアプリパスワード設定ミス | 2段階認証とアプリパスワードを再確認 |
| 問題が生成されない | `GEMINI_API_KEY` 未設定 | `.env` のキーを確認（未設定時はモックデータが返る） |
| 音声が再生されない | `GOOGLE_CLOUD_API_KEY` 未設定 | GCPコンソールでTTS API有効化を確認 |
| 画像アップロード失敗 | S3設定ミス | バケット名・リージョン・IAM権限を確認 |
| 楽曲が検索できない | Spotify APIキー未設定 | `SPOTIFY_CLIENT_ID` / `SECRET` を確認 |
| DB接続エラー | パスワードの不一致 | `.env` の `MYSQL_USER`/`MYSQL_PASSWORD` を確認 |

---

## 9. アプリの使い方

### 9-1. 画面構成（ボトムナビゲーション）

| タブ | 画面名 | 主な機能 |
|---|---|---|
| ホーム | ホーム画面 | ライフ表示・バッジ確認・ランキング |
| 対戦 | バトルモード選択 | ランクマッチ・ルームマッチ |
| 学習 | 学習メニュー | クイズ・学習履歴 |
| フレンド | フレンド管理 | フレンド検索・申請・一覧 |
| メニュー | 設定・その他 | プロフィール編集・設定 |

---

### 9-2. 初回セットアップ（ユーザー登録）

1. アプリ起動 → スプラッシュ画面
2. 「新規登録」をタップ
3. メールアドレス・パスワードを入力 → 「登録」
4. プロフィール設定画面:
   - ユーザー名を入力
   - ユーザーUUID(フレンド申請に使用するもの)を入力
   - プロフィール画像を設定（任意）
5. ホーム画面へ遷移
6. 好きなアーティストを選択（任意・後で変更可）
---

### 9-3. 学習モードの使い方

1. ボトムナビ「学習」→「学習を始める」
2. 学習設定画面で以下を選択:

   | 設定項目 | 選択肢 |
   |---|---|
   | 学習言語 | 英語 / 韓国語 |
   | 問題生成方法 | `FAVORITE_ARTIST`（お気に入りアーティスト）/ `GENRE_RANDOM`（ジャンル指定）/ `COMPLETE_RANDOM`（ランダム）/ `URL_INPUT`（URL指定） |
   | 問題形式 | `ALL_RANDOM`（混合）/ `FILL_IN_BLANK_ONLY`（虫食いのみ）/ `LISTENING_ONLY`（リスニングのみ） |
   | 問題数 | スライダーで調整（5〜30問、5問単位） |

3. 「学習を開始」→ DBに問題が十分ある曲はそのまま取得、不足している場合はGemini AIが歌詞から問題を自動生成（数秒かかる）
4. 問題に回答 → 正解/不正解 + 日本語訳・解説を表示
5. 全問終了 → 結果画面（正解数・正解率）

**単語帳:**
- 穴埋め問題: 正解の単語が正誤問わず自動で単語帳に登録される
- リスニング問題: 不正解だった問題の単語が自動で単語帳に登録される
- ホーム画面「単語帳」からフラッシュカード形式で復習
- フィルター・並び替え機能あり

---

### 9-4. 対戦モードの使い方

#### ランクマッチ（1対1オンライン対戦）
1. ボトムナビ「対戦」→「ランクマッチ」
2. ライフ（音符アイコン）が1以上あることを確認
3. 「マッチング開始」→ ライフが1消費され、相手を自動検索
4. 対戦開始: 曲の一節が表示 → 穴埋め/リスニング問題に回答
5. 制限時間: 90秒/問、**先に3本先取した方が勝ち**
6. 10問終了時に3本未達 → 多得点勝ち / 同点は引き分け
7. 結果表示 → レート更新

**ライフシステム:**

| ユーザー種別 | ライフ上限 | 消費タイミング | 回復 |
|---|---|---|---|
| 通常ユーザー | 5 | ランクマッチ開始時に1消費 | 10分ごとに1回復 |
| サブスクユーザー | 10 | ランクマッチ開始時に1消費 | 10分ごとに1回復 |

- ホーム画面の音符アイコンで現在のライフを確認
- ライフ不足時は次の回復までのカウントダウンを表示
- **アイテムによる即時回復**: ライフが0のときホーム画面に「+」ボタンが表示される
  → タップするとライフ回復アイテムを使用できる（ショップで購入: ¥120×1 / ¥450×5）

#### ルームマッチ（フレンドとのプライベート対戦）
**ライフ消費なし**（カジュアル対戦）

**ホストとして部屋を作成する場合:**
1. ボトムナビ「対戦」→「ルームマッチ」→「ルーム作成」
2. フレンドに招待を送信
3. ゲストが招待を承諾して部屋に参加
4. ゲストが「準備完了」ボタンを押す
5. ゲストの準備完了後、ホストに「対戦設定へ」ボタンが表示される
6. ホストが対戦設定を選択して「対戦開始！」を押す:
   - **先取数**: 5本 / 7本 / 9本
   - **言語**: 英語 / 韓国語
   - **問題形式**: すべてランダム / リスニングのみ / 虫食いのみ
   - **出題方法**: 完全ランダム / お気に入りアーティストから
7. 対戦終了後は「再戦する」で同じメンバーで再挑戦可能

**ゲストとして参加する場合:**
1. フレンドから届いた招待通知をタップ → 「参加」
2. 部屋に入ったら「準備完了」ボタンを押す
3. ホストが設定を確定すると対戦開始

**部屋が崩れる条件:**
- ホストが「部屋を解散」ボタンを押す → ゲストに「ホストが部屋を解散しました」と表示され強制退出
- ゲストが「退出」ボタンを押す → ゲストのみ退出（部屋はWAITING状態に戻りホストはそのまま待機）

---

### 9-5. フレンド機能の使い方

1. ボトムナビ「フレンド」→ フレンド一覧を表示
2. 「ユーザー検索」でユーザー名またはメールアドレスで検索
3. 対象ユーザーのプロフィールを開いて「フレンド申請」
4. 相手が承認するとフレンドリストに追加される
5. フレンドからできること:
   - プロフィールの閲覧
   - ルームマッチへの招待送信

---

### 9-6. ランキング・バッジ

**ランキング:**
- ホーム画面「ランキング」→ 全ユーザーのスコアランキングを確認

**バッジ:**
- ホーム画面「バッジ」→ 取得済み/未取得バッジの一覧
- 以下の実績でバッジを取得:
  - 対戦勝利数（例: 初勝利、10勝、50勝...）
  - 連勝記録
  - 学習完了数

---

### 9-7. 設定・その他

ボトムナビ「メニュー」から各種設定にアクセス:

| メニュー項目 | 内容 |
|---|---|
| クレジットカード管理 | 支払い用クレジットカードの登録・変更 |
| サブスクリプション | 登録でライフ上限2倍・機能拡張 |
| プロフィール編集 | アイコン・ユーザー名（UUID）の変更 |
| アーティスト編集 | 好きなアーティストの追加・削除 |
| プライバシー設定 | プロフィールの公開範囲設定 |
| メールアドレス変更 | ログイン用メールアドレスの変更（確認メール送信） |
| パスワードリセット | パスワードの更新 |
| お問い合わせ | サポートへの問い合わせフォーム |

---

### 9-8. 通報機能

設定画面からではなく、各コンテンツ画面から直接通報します。

| 通報の種類 | 通報できる画面 |
|---|---|
| **単語の通報** | 単語帳画面 → 該当単語の通報ボタン |
| **問題の通報** | 学習結果画面 → 問題一覧から該当問題の通報ボタン |
| **問題の通報** | 学習履歴詳細画面 → 該当問題の通報ボタン |
| **問題の通報** | 対戦画面 → 問題ごとの通報ボタン |

---

## 10. 関連ファイルパス

| ファイル | 用途 |
|---|---|
| [docker-compose.yml](../docker-compose.yml) | コンテナ構成定義 |
| `.env` | 環境変数（要作成・Gitにコミット不可） |
| [api/src/main/resources/application.properties](../api/src/main/resources/application.properties) | Spring Boot設定 |
| [web/assets/config.json](../web/assets/config.json) | Flutter APIエンドポイント設定 |
| [web/pubspec.yaml](../web/pubspec.yaml) | Flutter依存関係 |
| [api/pom.xml](../api/pom.xml) | Java依存関係 |
