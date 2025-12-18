package com.example.api.service;

import com.example.api.client.GeminiApiClient;
import com.example.api.entity.Vocabulary;
import com.example.api.repository.VocabularyRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * Vocabularyバッチ更新サービス
 * 既存の単語データにbase_formとtranslation_jaを追加します
 */
@Service
public class VocabularyBatchService {

    private static final Logger logger = LoggerFactory.getLogger(VocabularyBatchService.class);

    @Autowired
    private VocabularyRepository vocabularyRepository;

    @Autowired
    private GeminiApiClient geminiApiClient;

    /**
     * base_formまたはtranslation_jaがnullの単語を更新
     * 
     * @param limit 一度に処理する最大件数（API制限対策）
     * @return 更新した件数
     */
    @Transactional
    public int updateMissingFields(int limit) {
        logger.info("=== バッチ更新開始 ===");
        logger.info("処理上限: {} 件", limit);

        // base_formまたはtranslation_jaがnullのレコードを取得
        List<Vocabulary> vocabsToUpdate = vocabularyRepository.findByBaseFormIsNullOrTranslationJaIsNull(limit);
        
        logger.info("更新対象: {} 件", vocabsToUpdate.size());

        int successCount = 0;
        int errorCount = 0;

        for (Vocabulary vocab : vocabsToUpdate) {
            try {
                boolean updated = updateVocabulary(vocab);
                if (updated) {
                    successCount++;
                }
            } catch (Exception e) {
                logger.error("単語更新エラー: word={}, error={}", vocab.getWord(), e.getMessage());
                errorCount++;
            }

            // API制限対策: 少し待機
            try {
                Thread.sleep(500); // 0.5秒待機
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                break;
            }
        }

        logger.info("=== バッチ更新完了 ===");
        logger.info("成功: {} 件, エラー: {} 件", successCount, errorCount);

        return successCount;
    }

    /**
     * 全ての単語を強制的に更新（base_form, translation_jaを再生成）
     * 
     * @param limit 一度に処理する最大件数
     * @return 更新した件数
     */
    @Transactional
    public int forceUpdateAll(int limit) {
        logger.info("=== 強制バッチ更新開始 ===");
        logger.info("処理上限: {} 件", limit);

        List<Vocabulary> vocabsToUpdate = vocabularyRepository.findAllOrderByIdAsc(limit);
        
        logger.info("更新対象: {} 件", vocabsToUpdate.size());

        int successCount = 0;
        int errorCount = 0;

        for (Vocabulary vocab : vocabsToUpdate) {
            try {
                // 強制更新: 既存の値をnullにしてから更新
                vocab.setBase_form(null);
                vocab.setTranslation_ja(null);
                
                boolean updated = updateVocabulary(vocab);
                if (updated) {
                    successCount++;
                }
            } catch (Exception e) {
                logger.error("単語更新エラー: word={}, error={}", vocab.getWord(), e.getMessage());
                errorCount++;
            }

            // API制限対策
            try {
                Thread.sleep(500);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                break;
            }
        }

        logger.info("=== 強制バッチ更新完了 ===");
        logger.info("成功: {} 件, エラー: {} 件", successCount, errorCount);

        return successCount;
    }

    /**
     * 単一の単語を更新
     */
    private boolean updateVocabulary(Vocabulary vocab) {
        String word = vocab.getWord();
        
        logger.debug("単語更新中: word={}", word);

        // Gemini APIで原形と簡潔訳を取得
        String[] result = geminiApiClient.getBaseFormAndTranslation(word);
        String baseForm = result[0];
        String translationJa = result[1];

        boolean updated = false;

        // base_formを更新
        if (vocab.getBase_form() == null || vocab.getBase_form().isEmpty()) {
            if (baseForm != null && !baseForm.isEmpty()) {
                vocab.setBase_form(baseForm);
                updated = true;
                logger.debug("  base_form更新: {} → {}", word, baseForm);
            }
        }

        // translation_jaを更新
        if (vocab.getTranslation_ja() == null || vocab.getTranslation_ja().isEmpty()) {
            if (translationJa != null && !translationJa.isEmpty()) {
                vocab.setTranslation_ja(translationJa);
                updated = true;
                logger.debug("  translation_ja更新: {} → {}", word, translationJa);
            }
        }

        if (updated) {
            vocabularyRepository.save(vocab);
            logger.info("✓ 単語更新完了: word={}, baseForm={}, translationJa={}", 
                word, vocab.getBase_form(), vocab.getTranslation_ja());
        } else {
            logger.debug("  更新なし: word={}", word);
        }

        return updated;
    }

    /**
     * 更新が必要な単語数を取得
     */
    public long countMissingFields() {
        return vocabularyRepository.countByBaseFormIsNullOrTranslationJaIsNull();
    }

    /**
     * 全単語数を取得
     */
    public long countAll() {
        return vocabularyRepository.count();
    }
}