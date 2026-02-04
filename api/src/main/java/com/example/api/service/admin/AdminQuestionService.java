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
import java.time.ZoneId;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
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

    @PersistenceContext
    private EntityManager entityManager;

    @Transactional(readOnly = true)
    public AdminQuestionResponse.ListResponse getQuestions(
            int page, int size, String idSearch, Long artistId, String questionFormat, String language,
            Integer difficultyLevel, Boolean isActive, String questionText, String answer,
            String songName, String artistName, LocalDateTime addedFrom, LocalDateTime addedTo, String sortDirection) {

        Sort.Direction direction = parseSortDirection(sortDirection);

        StringBuilder fromClause = new StringBuilder(
                " FROM question q " +
                        "LEFT JOIN song s ON q.song_id = s.song_id " +
                        "LEFT JOIN artist a ON q.artist_id = a.artist_id " +
                        "WHERE 1=1");
        Map<String, Object> params = new HashMap<>();

        if (idSearch != null && !idSearch.isEmpty()) {
            fromClause.append(" AND CAST(q.question_id AS CHAR) = :questionId");
            params.put("questionId", idSearch);
        }
        if (artistId != null) {
            fromClause.append(" AND q.artist_id = :artistId");
            params.put("artistId", artistId);
        }
        if (questionFormat != null && !questionFormat.isEmpty()) {
            QuestionFormat parsedFormat = parseQuestionFormat(questionFormat);
            fromClause.append(" AND q.question_format = :questionFormat");
            params.put("questionFormat", parsedFormat.name());
        }
        if (language != null && !language.isEmpty()) {
            fromClause.append(" AND q.language = :language");
            params.put("language", language);
        }
        if (questionText != null && !questionText.isEmpty()) {
            fromClause.append(" AND q.text LIKE :questionText");
            params.put("questionText", "%" + questionText + "%");
        }
        if (answer != null && !answer.isEmpty()) {
            fromClause.append(" AND q.answer LIKE :answer");
            params.put("answer", "%" + answer + "%");
        }
        if (songName != null && !songName.isEmpty()) {
            fromClause.append(" AND s.songname LIKE :songName");
            params.put("songName", "%" + songName + "%");
        }
        if (artistName != null && !artistName.isEmpty()) {
            fromClause.append(" AND a.artist_name LIKE :artistName");
            params.put("artistName", "%" + artistName + "%");
        }
        if (difficultyLevel != null) {
            fromClause.append(" AND q.difficulty_level = :difficultyLevel");
            params.put("difficultyLevel", difficultyLevel);
        }
        if (isActive != null) {
            fromClause.append(" AND q.is_active = :isActive");
            params.put("isActive", isActive);
        }
        if (addedFrom != null) {
            fromClause.append(" AND q.adding_at >= :addedFrom");
            params.put("addedFrom", addedFrom);
        }
        if (addedTo != null) {
            fromClause.append(" AND q.adding_at <= :addedTo");
            params.put("addedTo", addedTo);
        }

        String orderBy = " ORDER BY q.question_id " + (direction == Sort.Direction.ASC ? "ASC" : "DESC");
        String selectSql = "SELECT q.question_id, q.song_id, q.artist_id, q.text, q.answer, " +
                "q.complete_sentence, q.question_format, q.difficulty_level, q.language, q.translation_ja, " +
                "q.audio_url, q.is_active, q.is_deleted, q.adding_at, s.songname, a.artist_name" +
                fromClause + orderBy;
        String countSql = "SELECT COUNT(*)" + fromClause;

        Query dataQuery = entityManager.createNativeQuery(selectSql);
        Query countQuery = entityManager.createNativeQuery(countSql);
        params.forEach((key, value) -> {
            dataQuery.setParameter(key, value);
            countQuery.setParameter(key, value);
        });
        dataQuery.setFirstResult(page * size);
        dataQuery.setMaxResults(size);

        List<Object[]> rows = dataQuery.getResultList();
        List<AdminQuestionResponse> questions = rows.stream()
                .map(this::toResponse)
                .collect(Collectors.toList());

        long totalElements = ((Number) countQuery.getSingleResult()).longValue();
        int totalPages = (int) Math.ceil((double) totalElements / size);

        return new AdminQuestionResponse.ListResponse(
                questions, page, size, totalElements, totalPages);
    }
    @Transactional(readOnly = true)
    public AdminQuestionResponse getQuestion(Integer questionId) {
        String selectSql = "SELECT q.question_id, q.song_id, q.artist_id, q.text, q.answer, " +
                "q.complete_sentence, q.question_format, q.difficulty_level, q.language, q.translation_ja, " +
                "q.audio_url, q.is_active, q.is_deleted, q.adding_at, s.songname, a.artist_name " +
                "FROM question q " +
                "LEFT JOIN song s ON q.song_id = s.song_id " +
                "LEFT JOIN artist a ON q.artist_id = a.artist_id " +
                "WHERE q.question_id = :questionId";

        Query dataQuery = entityManager.createNativeQuery(selectSql);
        dataQuery.setParameter("questionId", questionId);
        @SuppressWarnings("unchecked")
        List<Object[]> rows = dataQuery.getResultList();
        if (rows.isEmpty()) {
            throw new IllegalArgumentException("問題が見つかりません: " + questionId);
        }
        return toResponse(rows.get(0));
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
        int updated = entityManager.createNativeQuery(
                "UPDATE question SET is_deleted = true WHERE question_id = :questionId")
            .setParameter("questionId", questionId)
            .executeUpdate();
        if (updated == 0) {
            throw new IllegalArgumentException("問題が見つかりません: " + questionId);
        }
        logger.info("問題削除: {}", questionId);
    }

    @Transactional
    public void restoreQuestion(Integer questionId) {
        int updated = entityManager.createNativeQuery(
                "UPDATE question SET is_deleted = false WHERE question_id = :questionId")
            .setParameter("questionId", questionId)
            .executeUpdate();
        if (updated == 0) {
            throw new IllegalArgumentException("問題が見つかりません: " + questionId);
        }
        logger.info("問題削除解除: {}", questionId);
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
        question.setQuestionFormat(parseQuestionFormat(request.getQuestionFormat()));
        question.setDifficultyLevel(request.getDifficultyLevel());
        question.setLanguage(request.getLanguage());
        question.setTranslationJa(request.getTranslationJa());
        question.setAudioUrl(request.getAudioUrl());
        question.setIsActive(request.getIsActive());
    }

    private AdminQuestionResponse toResponse(Question question) {
        AdminQuestionResponse response = new AdminQuestionResponse();
        response.setQuestionId(question.getQuestionId());
        final Song song = question.getSong();
        if (song != null) {
            response.setSongId(song.getSongId());
            response.setSongName(song.getSongname());
        }
        final Artist artist = question.getArtist();
        if (artist != null) {
            response.setArtistId(artist.getArtistId());
            response.setArtistName(artist.getArtistName());
        }
        response.setText(question.getText());
        response.setAnswer(question.getAnswer());
        response.setCompleteSentence(question.getCompleteSentence());
        response.setQuestionFormat(formatQuestionFormat(question.getQuestionFormat()));
        response.setDifficultyLevel(question.getDifficultyLevel());
        response.setLanguage(question.getLanguage());
        response.setTranslationJa(question.getTranslationJa());
        response.setAudioUrl(question.getAudioUrl());
        response.setIsActive(question.getIsActive());
        response.setIsDeleted(question.getIsDeleted());
        response.setAddingAt(question.getAddingAt());
        return response;
    }

    private AdminQuestionResponse toResponse(Object[] row) {
        AdminQuestionResponse response = new AdminQuestionResponse();
        response.setQuestionId(row[0] != null ? ((Number) row[0]).intValue() : null);
        response.setSongId(row[1] != null ? ((Number) row[1]).longValue() : null);
        response.setArtistId(row[2] != null ? ((Number) row[2]).longValue() : null);
        response.setText((String) row[3]);
        response.setAnswer((String) row[4]);
        response.setCompleteSentence((String) row[5]);
        if (row[6] != null) {
            response.setQuestionFormat(formatQuestionFormat(QuestionFormat.valueOf(row[6].toString())));
        }
        response.setDifficultyLevel(row[7] != null ? ((Number) row[7]).intValue() : null);
        response.setLanguage((String) row[8]);
        response.setTranslationJa((String) row[9]);
        response.setAudioUrl((String) row[10]);
        response.setIsActive(row[11] != null ? (Boolean) row[11] : null);
        response.setIsDeleted(row[12] != null ? (Boolean) row[12] : null);
        response.setAddingAt(toLocalDateTime(row[13]));
        response.setSongName((String) row[14]);
        response.setArtistName((String) row[15]);
        return response;
    }

    private LocalDateTime toLocalDateTime(Object value) {
        if (value == null) {
            return null;
        }
        if (value instanceof LocalDateTime) {
            return (LocalDateTime) value;
        }
        if (value instanceof java.sql.Timestamp) {
            return ((java.sql.Timestamp) value).toLocalDateTime();
        }
        if (value instanceof java.util.Date) {
            return ((java.util.Date) value).toInstant().atZone(ZoneId.systemDefault()).toLocalDateTime();
        }
        throw new IllegalArgumentException("Unsupported date type: " + value.getClass());
    }

    private QuestionFormat parseQuestionFormat(String questionFormat) {
        if (questionFormat == null || questionFormat.isEmpty()) {
            throw new IllegalArgumentException("問題形式が指定されていません");
        }
        switch (questionFormat) {
            case "FILL_IN_BLANK":
            case "FILL_IN_THE_BLANK":
            case "FILL_BLANK":
                return QuestionFormat.FILL_IN_THE_BLANK;
            case "LISTENING":
                return QuestionFormat.LISTENING;
            default:
                return QuestionFormat.valueOf(questionFormat);
        }
    }

    private String formatQuestionFormat(QuestionFormat format) {
        if (format == QuestionFormat.FILL_IN_THE_BLANK) {
            return "FILL_IN_BLANK";
        }
        return format.name();
    }

    private Sort.Direction parseSortDirection(String sortDirection) {
        if ("asc".equalsIgnoreCase(sortDirection)) {
            return Sort.Direction.ASC;
        }
        return Sort.Direction.DESC;
    }
}
