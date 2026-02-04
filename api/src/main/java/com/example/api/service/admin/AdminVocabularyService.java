package com.example.api.service.admin;

import com.example.api.dto.admin.AdminVocabularyRequest;
import com.example.api.dto.admin.AdminVocabularyResponse;
import com.example.api.entity.Vocabulary;
import com.example.api.repository.VocabularyRepository;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import jakarta.persistence.Query;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * 管理者用単語管理サービス
 */
@Service
public class AdminVocabularyService {

    private static final Logger logger = LoggerFactory.getLogger(AdminVocabularyService.class);

    @Autowired
    private VocabularyRepository vocabularyRepository;

    @PersistenceContext
    private EntityManager entityManager;

    /**
     * 単語一覧取得
     */
    public AdminVocabularyResponse.ListResponse getVocabularies(
            int page, int size, String idSearch, String word, String partOfSpeech, Boolean isActive,
            LocalDateTime createdFrom, LocalDateTime createdTo, String sortDirection) {

        Sort.Direction direction = parseSortDirection(sortDirection);
        StringBuilder whereClause = new StringBuilder(" FROM vocabulary WHERE 1=1");
        Map<String, Object> params = new HashMap<>();

        if (word != null && !word.isEmpty()) {
            whereClause.append(" AND word LIKE :word");
            params.put("word", "%" + word + "%");
        }
        if (idSearch != null && !idSearch.isEmpty()) {
            whereClause.append(" AND CAST(vocab_id AS CHAR) = :idSearch");
            params.put("idSearch", idSearch);
        }
        if (partOfSpeech != null && !partOfSpeech.isEmpty()) {
            whereClause.append(" AND part_of_speech = :partOfSpeech");
            params.put("partOfSpeech", partOfSpeech);
        }
        if (isActive != null) {
            whereClause.append(" AND is_active = :isActive");
            params.put("isActive", isActive);
        }
        if (createdFrom != null) {
            whereClause.append(" AND created_at >= :createdFrom");
            params.put("createdFrom", createdFrom);
        }
        if (createdTo != null) {
            whereClause.append(" AND created_at <= :createdTo");
            params.put("createdTo", createdTo);
        }

        String orderBy = " ORDER BY vocab_id " + (direction == Sort.Direction.ASC ? "ASC" : "DESC");

        Query dataQuery = entityManager.createNativeQuery("SELECT *" + whereClause + orderBy, Vocabulary.class);
        params.forEach(dataQuery::setParameter);
        dataQuery.setFirstResult(page * size);
        dataQuery.setMaxResults(size);

        @SuppressWarnings("unchecked")
        List<Vocabulary> vocabResults = dataQuery.getResultList();

        Query countQuery = entityManager.createNativeQuery("SELECT COUNT(*)" + whereClause);
        params.forEach(countQuery::setParameter);
        Number totalElements = (Number) countQuery.getSingleResult();

        List<AdminVocabularyResponse> vocabularies = vocabResults.stream()
            .map(this::toResponse)
            .collect(Collectors.toList());

        int totalPages = (int) Math.ceil(totalElements.doubleValue() / size);

        return new AdminVocabularyResponse.ListResponse(
            vocabularies, page, size, totalElements.longValue(), totalPages);
    }

    /**
     * 単語詳細取得
     */
    public AdminVocabularyResponse getVocabulary(Integer vocabId) {
        Query query = entityManager.createNativeQuery(
            "SELECT * FROM vocabulary WHERE vocab_id = :vocabId",
            Vocabulary.class
        );
        query.setParameter("vocabId", vocabId);

        @SuppressWarnings("unchecked")
        List<Vocabulary> results = query.getResultList();
        if (results.isEmpty()) {
            throw new IllegalArgumentException("単語が見つかりません: " + vocabId);
        }
        return toResponse(results.get(0));
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
        Vocabulary vocab = findVocabularyIncludingInactive(vocabId);
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
        int updated = entityManager.createNativeQuery(
                "UPDATE vocabulary SET is_deleted = true WHERE vocab_id = :vocabId")
            .setParameter("vocabId", vocabId)
            .executeUpdate();
        if (updated == 0) {
            throw new IllegalArgumentException("単語が見つかりません: " + vocabId);
        }
        logger.info("単語削除: {}", vocabId);
    }

    @Transactional
    public void restoreVocabulary(Integer vocabId) {
        int updated = entityManager.createNativeQuery(
                "UPDATE vocabulary SET is_deleted = false WHERE vocab_id = :vocabId")
            .setParameter("vocabId", vocabId)
            .executeUpdate();
        if (updated == 0) {
            throw new IllegalArgumentException("単語が見つかりません: " + vocabId);
        }
        logger.info("単語削除解除: {}", vocabId);
    }

    /**
     * 一括有効化
     */
    @Transactional
    public int enableVocabularies(List<Integer> ids) {
        int count = 0;
        for (Integer id : ids) {
            Vocabulary vocab = findVocabularyIncludingInactive(id);
            vocab.setIsActive(true);
            vocabularyRepository.save(vocab);
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
            Vocabulary vocab = findVocabularyIncludingInactive(id);
            vocab.setIsActive(false);
            vocabularyRepository.save(vocab);
            count++;
        }
        logger.info("単語一括無効化: {} 件", count);
        return count;
    }

    private Vocabulary findVocabularyIncludingInactive(Integer vocabId) {
        Query query = entityManager.createNativeQuery(
            "SELECT * FROM vocabulary WHERE vocab_id = :vocabId AND is_deleted = false",
            Vocabulary.class
        );
        query.setParameter("vocabId", vocabId);

        @SuppressWarnings("unchecked")
        List<Vocabulary> results = query.getResultList();
        if (results.isEmpty()) {
            throw new IllegalArgumentException("単語が見つかりません: " + vocabId);
        }
        return results.get(0);
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
        response.setIsDeleted(vocab.getIsDeleted());
        response.setCreatedAt(vocab.getCreated_at());
        response.setUpdatedAt(vocab.getUpdated_at());
        return response;
    }

    private Sort.Direction parseSortDirection(String sortDirection) {
        if ("asc".equalsIgnoreCase(sortDirection)) {
            return Sort.Direction.ASC;
        }
        return Sort.Direction.DESC;
    }
}
