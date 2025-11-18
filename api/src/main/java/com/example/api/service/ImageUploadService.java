package com.example.api.service;

import org.springframework.web.multipart.MultipartFile;

/**
 * 画像アップロードサービスのインターフェース
 * ローカルストレージまたはS3への保存を抽象化
 */
public interface ImageUploadService {

    /**
     * 画像をアップロード
     * @param file アップロードするファイル
     * @return 画像のURL（アクセス可能なパス）
     * @throws Exception アップロード失敗時
     */
    String uploadImage(MultipartFile file) throws Exception;

    /**
     * 画像を削除
     * @param imageUrl 削除する画像のURL
     * @throws Exception 削除失敗時
     */
    void deleteImage(String imageUrl) throws Exception;
}
