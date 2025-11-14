package com.example.api.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.UUID;

/**
 * ローカルファイルシステムへの画像アップロード実装
 * 開発環境で使用
 */
@Service
public class LocalImageUploadService implements ImageUploadService {

    @Value("${upload.local.directory:src/main/resources/static/uploads}")
    private String uploadDirectory;

    @Value("${upload.local.url-prefix:/uploads}")
    private String urlPrefix;

    @Override
    public String uploadImage(MultipartFile file) throws Exception {
        try {
            // アップロードディレクトリを作成（存在しない場合）
            Path uploadPath = Paths.get(uploadDirectory);
            if (!Files.exists(uploadPath)) {
                Files.createDirectories(uploadPath);
            }

            // ユニークなファイル名を生成
            String originalFilename = file.getOriginalFilename();
            String fileExtension = getFileExtension(originalFilename);
            String uniqueFilename = UUID.randomUUID().toString() + "." + fileExtension;

            // ファイルを保存
            Path filePath = uploadPath.resolve(uniqueFilename);
            Files.copy(file.getInputStream(), filePath, StandardCopyOption.REPLACE_EXISTING);

            // 画像URLを返す（相対パス）
            return urlPrefix + "/" + uniqueFilename;

        } catch (IOException e) {
            throw new Exception("画像のアップロードに失敗しました: " + e.getMessage(), e);
        }
    }

    @Override
    public void deleteImage(String imageUrl) throws Exception {
        try {
            // URLからファイル名を抽出
            String filename = imageUrl.substring(imageUrl.lastIndexOf('/') + 1);
            Path filePath = Paths.get(uploadDirectory, filename);

            // ファイルが存在する場合のみ削除
            if (Files.exists(filePath)) {
                Files.delete(filePath);
            }
        } catch (IOException e) {
            throw new Exception("画像の削除に失敗しました: " + e.getMessage(), e);
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
}
