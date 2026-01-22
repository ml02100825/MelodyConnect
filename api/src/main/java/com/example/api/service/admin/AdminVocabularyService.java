package com.example.api.service.admin;

import com.example.api.dto.admin.AdminVocabularyRequest;
import com.example.api.dto.admin.AdminVocabularyResponse;
import com.example.api.entity.Vocabulary;
import com.example.api.repository.VocabularyRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import jakarta.persistence.criteria.Predicate;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

/**
 * 管理者用単語管理サービス
 */
@Service
public class AdminVocabularyService {

    private static final Logger logger = LoggerFactory.getLogger(AdminVocabularyService.class);

    @Autowired
    private VocabularyRepository vocabularyRepository;

    /**
     * 単語一覧取得
     */
    public AdminVocabularyResponse.ListResponse getVocabularies(
            int page, int size, String word, String language, Boolean isActive) {

        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "vocabId"));

        Specification<Vocabulary> spec = (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();

            // @Whereアノテーションを無視するため、削除フラグは明示的にチェック
            predicates.add(cb.equal(root.get("isDeleted"), false));

            if (word != null && !word.isEmpty()) {
                predicates.add(cb.like(root.get("word"), "%" + word + "%"));
            }
            if (language != null && !language.isEmpty()) {
                predicates.add(cb.equal(root.get("language"), language));
            }
            if (isActive != null) {
                predicates.add(cb.equal(root.get("isActive"), isActive));
            }

            return cb.and(predicates.toArray(new Predicate[0]));
        };

        Page<Vocabulary> vocabPage = vocabularyRepository.findAll(spec, pageable);

        List<AdminVocabularyResponse> vocabularies = vocabPage.getContent().stream()
                .map(this::toResponse)
                .collect(Collectors.toList());

        return new AdminVocabularyResponse.ListResponse(
                vocabularies, page, size, vocabPage.getTotalElements(), vocabPage.getTotalPages());
    }

    /**
     * 単語詳細取得
     */
    public AdminVocabularyResponse getVocabulary(Integer vocabId) {
        Vocabulary vocab = vocabularyRepository.findById(vocabId)
                .orElseThrow(() -> new IllegalArgumentException("単語が見つかりません: " + vocabId));
        return toResponse(vocab);
    }

    /**
     * 単語作成
     */
    @Transactional
    public AdminVocabularyResponse createVocabulary(AdminVocabularyRequest request) {
        Vocabulary vocab = new Vocabulary();
        updateFromRequest(vocab, request);
        vocab = vocabularyRepository.save(vocab);
        logger.info("単語作成: {}", vocab.getVocabId());
        return toResponse(vocab);
    }

    /**
     * 単語更新
     */
    @Transactional
    public AdminVocabularyResponse updateVocabulary(Integer vocabId, AdminVocabularyRequest request) {
        Vocabulary vocab = vocabularyRepository.findById(vocabId)
                .orElseThrow(() -> new IllegalArgumentException("単語が見つかりません: " + vocabId));
        updateFromRequest(vocab, request);
        vocab = vocabularyRepository.save(vocab);
        logger.info("単語更新: {}", vocabId);
        return toResponse(vocab);
    }

    /**
     * 単語削除（論理削除）
     */
    @Transactional
    public void deleteVocabulary(Integer vocabId) {
        Vocabulary vocab = vocabularyRepository.findById(vocabId)
                .orElseThrow(() -> new IllegalArgumentException("単語が見つかりません: " + vocabId));
        vocab.setIsDeleted(true);
        vocabularyRepository.save(vocab);
        logger.info("単語削除: {}", vocabId);
    }

    /**
     * 一括有効化
     */
    @Transactional
    public int enableVocabularies(List<Integer> ids) {
        int count = 0;
        for (Integer id : ids) {
            vocabularyRepository.findById(id).ifPresent(vocab -> {
                vocab.setIsActive(true);
                vocabularyRepository.save(vocab);
            });
            count++;
        }
        logger.info("単語一括有効化: {} 件", count);
        return count;
    }

    /**
     * 一括無効化
     */
    @Transactional
    public int disableVocabularies(List<Integer> ids) {
        int count = 0;
        for (Integer id : ids) {
            vocabularyRepository.findById(id).ifPresent(vocab -> {
                vocab.setIsActive(false);
                vocabularyRepository.save(vocab);
            });
            count++;
        }
        logger.info("単語一括無効化: {} 件", count);
        return count;
    }

    private void updateFromRequest(Vocabulary vocab, AdminVocabularyRequest request) {
        vocab.setWord(request.getWord());
        vocab.setBase_form(request.getBaseForm());
        vocab.setMeaning_ja(request.getMeaningJa());
        vocab.setTranslation_ja(request.getTranslationJa());
        vocab.setPronunciation(request.getPronunciation());
        vocab.setPart_of_speech(request.getPartOfSpeech());
        vocab.setExample_sentence(request.getExampleSentence());
        vocab.setExample_translate(request.getExampleTranslate());
        vocab.setAudio_url(request.getAudioUrl());
        vocab.setLanguage(request.getLanguage());
        vocab.setIsActive(request.getIsActive());
    }

    private AdminVocabularyResponse toResponse(Vocabulary vocab) {
        AdminVocabularyResponse response = new AdminVocabularyResponse();
        response.setVocabId(vocab.getVocabId());
        response.setWord(vocab.getWord());
        response.setBaseForm(vocab.getBase_form());
        response.setMeaningJa(vocab.getMeaning_ja());
        response.setTranslationJa(vocab.getTranslation_ja());
        response.setPronunciation(vocab.getPronunciation());
        response.setPartOfSpeech(vocab.getPart_of_speech());
        response.setExampleSentence(vocab.getExample_sentence());
        response.setExampleTranslate(vocab.getExample_translate());
        response.setAudioUrl(vocab.getAudio_url());
        response.setLanguage(vocab.getLanguage());
        response.setIsActive(vocab.getIsActive());
        response.setCreatedAt(vocab.getCreated_at());
        response.setUpdatedAt(vocab.getUpdated_at());
        return response;
    }
}
