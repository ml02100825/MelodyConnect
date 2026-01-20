package com.example.api.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import software.amazon.awssdk.auth.credentials.AwsBasicCredentials;
import software.amazon.awssdk.auth.credentials.AwsSessionCredentials;
import software.amazon.awssdk.auth.credentials.StaticCredentialsProvider;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.*;

import jakarta.annotation.PostConstruct;
import java.util.UUID;

/**
 * AWS S3への画像アップロード実装
 * 本番環境で使用
 */
@Service
public class S3ImageUploadService implements ImageUploadService {

    @Value("${aws.s3.bucket-name:}")
    private String bucketName;

    @Value("${aws.s3.region:ap-northeast-1}")
    private String region;

    @Value("${aws.access-key-id:}")
    private String accessKeyId;

    @Value("${aws.secret-access-key:}")
    private String secretAccessKey;

    @Value("${aws.session-token:}")
    private String sessionToken;
    

    @Value("${aws.s3.folder:uploads/images}")
    private String s3Folder;

    private S3Client s3Client;

    @PostConstruct
    public void init() {
        // S3クライアントの初期化（認証情報が設定されている場合のみ）
        if (accessKeyId != null && !accessKeyId.isEmpty() &&
            secretAccessKey != null && !secretAccessKey.isEmpty()) {

            StaticCredentialsProvider credentialsProvider;

            // AWS Academy Learner Lab用: セッショントークンがある場合は一時認証情報を使用
            if (sessionToken != null && !sessionToken.isEmpty()) {
                AwsSessionCredentials credentials = AwsSessionCredentials.create(
                    accessKeyId, secretAccessKey, sessionToken);
                credentialsProvider = StaticCredentialsProvider.create(credentials);
            } else {
                AwsBasicCredentials credentials = AwsBasicCredentials.create(accessKeyId, secretAccessKey);
                credentialsProvider = StaticCredentialsProvider.create(credentials);
            }

            this.s3Client = S3Client.builder()
                    .region(Region.of(region))
                    .credentialsProvider(credentialsProvider)
                    .build();
        }
    }

    @Override
    public String uploadImage(MultipartFile file) throws Exception {
        if (s3Client == null) {
            throw new Exception("S3クライアントが初期化されていません。AWS認証情報を確認してください。");
        }

        try {
            // ユニークなファイル名を生成
            String originalFilename = file.getOriginalFilename();
            String fileExtension = getFileExtension(originalFilename);
            String uniqueFilename = UUID.randomUUID().toString() + "." + fileExtension;
            String s3Key = s3Folder + "/" + uniqueFilename;

            // ファイルのContent-Typeを設定
            String contentType = file.getContentType();
            if (contentType == null || contentType.isEmpty()) {
                contentType = "image/" + fileExtension;
            }

            // S3にアップロード
            PutObjectRequest putObjectRequest = PutObjectRequest.builder()
                    .bucket(bucketName)
                    .key(s3Key)
                    .contentType(contentType)
                    .build();

            s3Client.putObject(putObjectRequest,
                    RequestBody.fromBytes(file.getBytes()));

            // S3のURLを返す
            return String.format("https://%s.s3.%s.amazonaws.com/%s",
                    bucketName, region, s3Key);

        } catch (Exception e) {
            throw new Exception("S3への画像アップロードに失敗しました: " + e.getMessage(), e);
        }
    }

    @Override
    public void deleteImage(String imageUrl) throws Exception {
        if (s3Client == null) {
            throw new Exception("S3クライアントが初期化されていません。");
        }

        try {
            // URLからS3キーを抽出
            String s3Key = extractS3KeyFromUrl(imageUrl);

            DeleteObjectRequest deleteObjectRequest = DeleteObjectRequest.builder()
                    .bucket(bucketName)
                    .key(s3Key)
                    .build();

            s3Client.deleteObject(deleteObjectRequest);

        } catch (Exception e) {
            throw new Exception("S3からの画像削除に失敗しました: " + e.getMessage(), e);
        }
    }

    /**
     * ファイル拡張子を取得
     */
    private String getFileExtension(String filename) {
        if (filename == null) {
            return "";
        }
        int lastDotIndex = filename.lastIndexOf('.');
        if (lastDotIndex == -1) {
            return "";
        }
        return filename.substring(lastDotIndex + 1);
    }

    /**
     * S3 URLからキーを抽出
     */
    private String extractS3KeyFromUrl(String imageUrl) {
        // https://bucket-name.s3.region.amazonaws.com/folder/filename.jpg
        // から folder/filename.jpg を抽出
        String[] parts = imageUrl.split(".amazonaws.com/");
        if (parts.length == 2) {
            return parts[1];
        }
        throw new IllegalArgumentException("無効なS3 URL: " + imageUrl);
    }
}
