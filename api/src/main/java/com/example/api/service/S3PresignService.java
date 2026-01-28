package com.example.api.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import software.amazon.awssdk.auth.credentials.AwsBasicCredentials;
import software.amazon.awssdk.auth.credentials.AwsSessionCredentials;
import software.amazon.awssdk.auth.credentials.StaticCredentialsProvider;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;
import software.amazon.awssdk.services.s3.presigner.model.GetObjectPresignRequest;
import software.amazon.awssdk.services.s3.presigner.model.PresignedGetObjectRequest;
import software.amazon.awssdk.services.s3.model.GetObjectRequest;

import jakarta.annotation.PostConstruct;
import jakarta.annotation.PreDestroy;
import java.time.Duration;

/**
 * S3署名付きURL生成サービス
 * 音声ファイルの署名付きURLを生成する
 */
@Service
public class S3PresignService {

    private static final Logger logger = LoggerFactory.getLogger(S3PresignService.class);

    @Value("${aws.s3.bucket-name:}")
    private String bucketName;

    @Value("${aws.s3.region:us-east-1}")
    private String region;

    @Value("${aws.access-key-id:}")
    private String accessKeyId;

    @Value("${aws.secret-access-key:}")
    private String secretAccessKey;

    @Value("${aws.session-token:}")
    private String sessionToken;

    @Value("${aws.s3.presign-expiration-minutes:15}")
    private int presignExpirationMinutes;

    private S3Presigner s3Presigner;

    @PostConstruct
    public void init() {
        // S3Presignerの初期化（認証情報が設定されている場合のみ）
        if (accessKeyId != null && !accessKeyId.isEmpty() &&
            secretAccessKey != null && !secretAccessKey.isEmpty()) {

            StaticCredentialsProvider credentialsProvider;

            // AWS Academy Learner Lab用: セッショントークンがある場合は一時認証情報を使用
            if (sessionToken != null && !sessionToken.isEmpty()) {
                AwsSessionCredentials credentials = AwsSessionCredentials.create(
                    accessKeyId, secretAccessKey, sessionToken);
                credentialsProvider = StaticCredentialsProvider.create(credentials);
                logger.info("S3PresignService: セッショントークン使用で初期化");
            } else {
                AwsBasicCredentials credentials = AwsBasicCredentials.create(accessKeyId, secretAccessKey);
                credentialsProvider = StaticCredentialsProvider.create(credentials);
                logger.info("S3PresignService: 基本認証情報で初期化");
            }

            this.s3Presigner = S3Presigner.builder()
                    .region(Region.of(region))
                    .credentialsProvider(credentialsProvider)
                    .build();

            logger.info("S3PresignService初期化完了: bucket={}, region={}, expiration={}分",
                    bucketName, region, presignExpirationMinutes);
        } else {
            logger.warn("S3PresignService: AWS認証情報が設定されていません。署名付きURLは生成できません。");
        }
    }

    @PreDestroy
    public void cleanup() {
        if (s3Presigner != null) {
            s3Presigner.close();
        }
    }

    /**
     * S3キーから署名付きURLを生成
     *
     * @param s3Key S3オブジェクトキー（例: uploads/audio/uuid_en-US.mp3）
     * @return 署名付きURL、失敗時はnull
     */
    public String generatePresignedUrl(String s3Key) {
        if (s3Presigner == null) {
            logger.warn("S3Presignerが初期化されていません。");
            return null;
        }

        if (s3Key == null || s3Key.isEmpty()) {
            logger.warn("S3キーが空です。");
            return null;
        }

        try {
            GetObjectRequest getObjectRequest = GetObjectRequest.builder()
                    .bucket(bucketName)
                    .key(s3Key)
                    .build();

            GetObjectPresignRequest presignRequest = GetObjectPresignRequest.builder()
                    .signatureDuration(Duration.ofMinutes(presignExpirationMinutes))
                    .getObjectRequest(getObjectRequest)
                    .build();

            PresignedGetObjectRequest presignedRequest = s3Presigner.presignGetObject(presignRequest);
            String presignedUrl = presignedRequest.url().toString();

            logger.debug("署名付きURL生成: key={}, url={}", s3Key, presignedUrl);
            return presignedUrl;

        } catch (Exception e) {
            logger.error("署名付きURL生成に失敗: key={}, error={}", s3Key, e.getMessage(), e);
            return null;
        }
    }

    /**
     * audioUrlがS3キー形式かどうかを判定
     * S3キーは "uploads/" で始まる（URLではない）
     *
     * @param audioUrl 判定対象の文字列
     * @return S3キーの場合はtrue
     */
    public boolean isS3Key(String audioUrl) {
        if (audioUrl == null || audioUrl.isEmpty()) {
            return false;
        }
        // S3キーは "uploads/" で始まり、"http" で始まらない
        return audioUrl.startsWith("uploads/") && !audioUrl.startsWith("http");
    }

    /**
     * audioUrlをプレサインURLに変換（必要な場合のみ）
     * S3キーの場合は署名付きURLを生成、それ以外はそのまま返す
     *
     * @param audioUrl S3キーまたはURL
     * @return 署名付きURLまたは元のURL
     */
    public String convertToPresignedUrl(String audioUrl) {
        if (audioUrl == null || audioUrl.isEmpty()) {
            return audioUrl;
        }

        if (isS3Key(audioUrl)) {
            String presignedUrl = generatePresignedUrl(audioUrl);
            return presignedUrl != null ? presignedUrl : audioUrl;
        }

        // 既にURLの場合はそのまま返す
        return audioUrl;
    }

    /**
     * S3 Presignerが有効かどうかを確認
     */
    public boolean isPresignEnabled() {
        return s3Presigner != null;
    }
}
