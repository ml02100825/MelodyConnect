# AWS S3 画像アップロード設定ガイド

## 概要
このアプリケーションは、画像アップロードに2つのストレージオプションをサポートしています：
- **ローカルストレージ**（開発環境）: `src/main/resources/static/uploads/`
- **AWS S3**（本番環境）: AWS S3バケット

## ローカルストレージ（開発環境）

デフォルト設定です。特別な設定は不要です。

```properties
upload.storage.type=local
upload.local.directory=src/main/resources/static/uploads
```

## AWS S3設定（本番環境）

### 1. S3バケットの作成

1. AWS Management Consoleにログイン
2. S3サービスに移動
3. 「バケットを作成」をクリック
4. バケット名を入力（例: `melodyconnect-uploads`）
5. リージョンを選択（例: `ap-northeast-1`）
6. パブリックアクセス設定:
   - 「パブリックアクセスをすべてブロック」のチェックを外す
   - 警告を確認してチェック

### 2. バケットポリシーの設定

バケットに移動 → 「アクセス許可」 → 「バケットポリシー」

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::melodyconnect-uploads/uploads/images/*"
        }
    ]
}
```

### 3. CORSの設定

バケットに移動 → 「アクセス許可」 → 「CORS設定」

```json
[
    {
        "AllowedHeaders": ["*"],
        "AllowedMethods": ["GET", "PUT", "POST", "DELETE"],
        "AllowedOrigins": ["*"],
        "ExposeHeaders": ["ETag"]
    }
]
```

### 4. IAMユーザーの作成

1. IAM → ユーザー → 「ユーザーを追加」
2. ユーザー名を入力（例: `melodyconnect-upload`）
3. 「プログラムによるアクセス」を選択
4. アクセス許可:
   - 「既存のポリシーを直接アタッチ」
   - 「AmazonS3FullAccess」を選択（または以下のカスタムポリシー）

カスタムポリシー例:
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:DeleteObject"
            ],
            "Resource": "arn:aws:s3:::melodyconnect-uploads/uploads/images/*"
        }
    ]
}
```

5. アクセスキーIDとシークレットアクセスキーを保存

### 5. 環境変数の設定

`application.properties`または環境変数で設定:

```properties
# ストレージタイプをS3に変更
upload.storage.type=s3

# AWS S3設定
aws.s3.bucket-name=melodyconnect-uploads
aws.s3.region=ap-northeast-1
aws.access-key-id=AKIA...
aws.secret-access-key=...
aws.s3.folder=uploads/images
```

または、環境変数:
```bash
export UPLOAD_STORAGE_TYPE=s3
export AWS_S3_BUCKET_NAME=melodyconnect-uploads
export AWS_S3_REGION=ap-northeast-1
export AWS_ACCESS_KEY_ID=AKIA...
export AWS_SECRET_ACCESS_KEY=...
export AWS_S3_FOLDER=uploads/images
```

### 6. Dockerでの設定

`docker-compose.yml`:
```yaml
services:
  api:
    environment:
      - UPLOAD_STORAGE_TYPE=s3
      - AWS_S3_BUCKET_NAME=melodyconnect-uploads
      - AWS_S3_REGION=ap-northeast-1
      - AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
      - AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
      - AWS_S3_FOLDER=uploads/images
```

## セキュリティのベストプラクティス

1. **IAMユーザーの最小権限**: 必要な権限のみを付与
2. **アクセスキーの管理**: 環境変数で管理し、コードにハードコードしない
3. **バケットポリシー**: 特定のフォルダのみ公開
4. **定期的なキーのローテーション**: アクセスキーを定期的に更新
5. **CloudWatch監視**: S3アクセスログを有効化して監視

## トラブルシューティング

### エラー: Access Denied
- IAMユーザーの権限を確認
- バケットポリシーを確認
- アクセスキーが正しいか確認

### エラー: NoSuchBucket
- バケット名が正しいか確認
- リージョンが正しいか確認

### 画像が表示されない
- バケットポリシーでパブリック読み取りが許可されているか確認
- CORS設定が正しいか確認
- 画像URLが正しいか確認
