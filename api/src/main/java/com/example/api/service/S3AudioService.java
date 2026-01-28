package com.example.api.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import software.amazon.awssdk.auth.credentials.AwsBasicCredentials;
import software.amazon.awssdk.auth.credentials.AwsSessionCredentials;
import software.amazon.awssdk.auth.credentials.StaticCredentialsProvider;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;

import jakarta.annotation.PostConstruct;
import java.util.UUID;

/**
 * S3音声ファイルアップロードサービス
 * TTS生成した音声をS3にアップロードし、S3キーを返す
 * （署名付きURLはS3PresignServiceで生成）
 */
@Service
public class S3AudioService {

    private static final Logger logger = LoggerFactory.getLogger(S3AudioService.class);

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

    @Value("${aws.s3.audio-folder:uploads/audio}")
    private String audioFolder;

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
                logger.info("S3AudioService: セッショントークン使用で初期化");
            } else {
                AwsBasicCredentials credentials = AwsBasicCredentials.create(accessKeyId, secretAccessKey);
                credentialsProvider = StaticCredentialsProvider.create(credentials);
                logger.info("S3AudioService: 基本認証情報で初期化");
            }

            this.s3Client = S3Client.builder()
                    .region(Region.of(region))
                    .credentialsProvider(credentialsProvider)
                    .build();

            logger.info("S3AudioService初期化完了: bucket={}, region={}, folder={}",
                    bucketName, region, audioFolder);
        } else {
            logger.warn("S3AudioService: AWS認証情報が設定されていません。ローカルファイルシステムにフォールバックします。");
        }
    }

    /**
     * 音声データをS3にアップロードしてS3キーを返す
     *
     * @param audioBytes 音声データ（MP3形式）
     * @param languageCode 言語コード（ファイル名に使用）
     * @return S3キー（例: uploads/audio/uuid_en-US.mp3）、失敗時はnull
     */
    public String uploadAudio(byte[] audioBytes, String languageCode) {
        if (s3Client == null) {
            logger.warn("S3クライアントが初期化されていません。S3へのアップロードをスキップします。");
            return null;
        }

        if (audioBytes == null || audioBytes.length == 0) {
            logger.warn("音声データが空です。");
            return null;
        }

        try {
            // ユニークなファイル名を生成
            String fileName = String.format("%s_%s.mp3", UUID.randomUUID(), languageCode);
            String s3Key = audioFolder + "/" + fileName;

            // S3にアップロード（プライベートアクセス、署名付きURLで配信）
            PutObjectRequest putObjectRequest = PutObjectRequest.builder()
                    .bucket(bucketName)
                    .key(s3Key)
                    .contentType("audio/mpeg")
                    .build();

            s3Client.putObject(putObjectRequest, RequestBody.fromBytes(audioBytes));

            logger.info("音声ファイルをS3にアップロード: key={}", s3Key);
            return s3Key;

        } catch (Exception e) {
            logger.error("S3への音声アップロードに失敗: {}", e.getMessage(), e);
            return null;
        }
    }

    /**
     * S3が有効かどうかを確認
     */
    public boolean isS3Enabled() {
        return s3Client != null;
    }

    /**
     * バケット名を取得
     */
    public String getBucketName() {
        return bucketName;
    }

    /**
     * リージョンを取得
     */
    public String getRegion() {
        return region;
    }
}
