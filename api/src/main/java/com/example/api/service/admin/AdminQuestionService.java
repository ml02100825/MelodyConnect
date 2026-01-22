package com.example.api.service.admin;

import com.example.api.dto.admin.AdminQuestionRequest;
import com.example.api.dto.admin.AdminQuestionResponse;
import com.example.api.entity.Artist;
import com.example.api.entity.Question;
import com.example.api.entity.Song;
import com.example.api.enums.QuestionFormat;
import com.example.api.repository.ArtistRepository;
import com.example.api.repository.QuestionRepository;
import com.example.api.repository.SongRepository;
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
 * 管理者用問題管理サービス
 */
@Service
public class AdminQuestionService {

    private static final Logger logger = LoggerFactory.getLogger(AdminQuestionService.class);

    @Autowired
    private QuestionRepository questionRepository;

    @Autowired
    private SongRepository songRepository;

    @Autowired
    private ArtistRepository artistRepository;

    public AdminQuestionResponse.ListResponse getQuestions(
            int page, int size, Long songId, Long artistId, String questionFormat, String language, Boolean isActive) {

        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "questionId"));

        Specification<Question> spec = (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();
            predicates.add(cb.equal(root.get("isDeleted"), false));

            if (songId != null) {
                predicates.add(cb.equal(root.get("song").get("song_id"), songId));
            }
            if (artistId != null) {
                predicates.add(cb.equal(root.get("artist").get("artistId"), artistId));
            }
            if (questionFormat != null && !questionFormat.isEmpty()) {
                predicates.add(cb.equal(root.get("questionFormat"), QuestionFormat.valueOf(questionFormat)));
            }
            if (language != null && !language.isEmpty()) {
                predicates.add(cb.equal(root.get("language"), language));
            }
            if (isActive != null) {
                predicates.add(cb.equal(root.get("isActive"), isActive));
            }

            return cb.and(predicates.toArray(new Predicate[0]));
        };

        Page<Question> questionPage = questionRepository.findAll(spec, pageable);

        List<AdminQuestionResponse> questions = questionPage.getContent().stream()
                .map(this::toResponse)
                .collect(Collectors.toList());

        return new AdminQuestionResponse.ListResponse(
                questions, page, size, questionPage.getTotalElements(), questionPage.getTotalPages());
    }

    public AdminQuestionResponse getQuestion(Integer questionId) {
        Question question = questionRepository.findById(questionId)
                .orElseThrow(() -> new IllegalArgumentException("問題が見つかりません: " + questionId));
        return toResponse(question);
    }

    @Transactional
    public AdminQuestionResponse createQuestion(AdminQuestionRequest request) {
        Song song = songRepository.findById(request.getSongId())
                .orElseThrow(() -> new IllegalArgumentException("楽曲が見つかりません: " + request.getSongId()));
        Artist artist = artistRepository.findById(request.getArtistId())
                .orElseThrow(() -> new IllegalArgumentException("アーティストが見つかりません: " + request.getArtistId()));

        Question question = new Question();
        updateFromRequest(question, request, song, artist);
        question = questionRepository.save(question);
        logger.info("問題作成: {}", question.getQuestionId());
        return toResponse(question);
    }

    @Transactional
    public AdminQuestionResponse updateQuestion(Integer questionId, AdminQuestionRequest request) {
        Question question = questionRepository.findById(questionId)
                .orElseThrow(() -> new IllegalArgumentException("問題が見つかりません: " + questionId));
        Song song = songRepository.findById(request.getSongId())
                .orElseThrow(() -> new IllegalArgumentException("楽曲が見つかりません: " + request.getSongId()));
        Artist artist = artistRepository.findById(request.getArtistId())
                .orElseThrow(() -> new IllegalArgumentException("アーティストが見つかりません: " + request.getArtistId()));

        updateFromRequest(question, request, song, artist);
        question = questionRepository.save(question);
        logger.info("問題更新: {}", questionId);
        return toResponse(question);
    }

    @Transactional
    public void deleteQuestion(Integer questionId) {
        Question question = questionRepository.findById(questionId)
                .orElseThrow(() -> new IllegalArgumentException("問題が見つかりません: " + questionId));
        question.setIsDeleted(true);
        questionRepository.save(question);
        logger.info("問題削除: {}", questionId);
    }

    @Transactional
    public int enableQuestions(List<Integer> ids) {
        int count = 0;
        for (Integer id : ids) {
            questionRepository.findById(id).ifPresent(q -> {
                q.setIsActive(true);
                questionRepository.save(q);
            });
            count++;
        }
        logger.info("問題一括有効化: {} 件", count);
        return count;
    }

    @Transactional
    public int disableQuestions(List<Integer> ids) {
        int count = 0;
        for (Integer id : ids) {
            questionRepository.findById(id).ifPresent(q -> {
                q.setIsActive(false);
                questionRepository.save(q);
            });
            count++;
        }
        logger.info("問題一括無効化: {} 件", count);
        return count;
    }

    private void updateFromRequest(Question question, AdminQuestionRequest request, Song song, Artist artist) {
        question.setSong(song);
        question.setArtist(artist);
        question.setText(request.getText());
        question.setAnswer(request.getAnswer());
        question.setCompleteSentence(request.getCompleteSentence());
        question.setQuestionFormat(QuestionFormat.valueOf(request.getQuestionFormat()));
        question.setDifficultyLevel(request.getDifficultyLevel());
        question.setLanguage(request.getLanguage());
        question.setTranslationJa(request.getTranslationJa());
        question.setAudioUrl(request.getAudioUrl());
        question.setIsActive(request.getIsActive());
    }

    private AdminQuestionResponse toResponse(Question question) {
        AdminQuestionResponse response = new AdminQuestionResponse();
        response.setQuestionId(question.getQuestionId());
        response.setSongId(question.getSong().getSong_id());
        response.setSongName(question.getSong().getSongname());
        response.setArtistId(question.getArtist().getArtistId());
        response.setArtistName(question.getArtist().getArtistName());
        response.setText(question.getText());
        response.setAnswer(question.getAnswer());
        response.setCompleteSentence(question.getCompleteSentence());
        response.setQuestionFormat(question.getQuestionFormat().name());
        response.setDifficultyLevel(question.getDifficultyLevel());
        response.setLanguage(question.getLanguage());
        response.setTranslationJa(question.getTranslationJa());
        response.setAudioUrl(question.getAudioUrl());
        response.setIsActive(question.getIsActive());
        response.setAddingAt(question.getAddingAt());
        return response;
    }
}
