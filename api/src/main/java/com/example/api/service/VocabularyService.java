package com.example.api.service;

import com.example.api.client.WordnikApiClient;
import com.example.api.dto.WordnikWordInfo;
import com.example.api.entity.Vocabulary;
import com.example.api.repository.VocabularyRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Lazy;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

/**
 * 単語管理サービス
 * リスニング問題で間違えた単語の保存などを管理します
 */
@Service
public class VocabularyService {

    private static final Logger logger = LoggerFactory.getLogger(VocabularyService.class);

    @Autowired
    private WordnikApiClient wordnikApiClient;

    @Autowired
    private VocabularyRepository vocabularyRepository;

    @Autowired
    @Lazy
    private VocabularyService self;

    /**
     * リスニング問題で間違えた単語を保存
     * ユーザーが回答を提出 → 正解と比較 → 間違えた単語を保存
     *
     * @param userAnswer ユーザーの回答
     * @param correctAnswer 正解
     * @return 保存された単語のリスト
     */
    @Transactional
    public List<String> saveIncorrectWords(String userAnswer, String correctAnswer) {
        logger.info("間違えた単語を分析中");

        // 単語に分割
        String[] userWords = normalizeAndSplit(userAnswer);
        String[] correctWords = normalizeAndSplit(correctAnswer);

        // 間違えた単語を特定して保存
        List<String> incorrectWords = new java.util.ArrayList<>();

        for (int i = 0; i < correctWords.length; i++) {
            String correctWord = correctWords[i];

            // ユーザーの回答に該当する位置の単語が存在しないか、異なる場合
            boolean isIncorrect = i >= userWords.length || !userWords[i].equalsIgnoreCase(correctWord);

            if (isIncorrect && !isCommonWord(correctWord)) {
                self.saveVocabulary(correctWord);
                incorrectWords.add(correctWord);
            }
        }

        logger.info("間違えた単語を保存しました: count={}", incorrectWords.size());
        return incorrectWords;
    }

    /**
     * 単語を保存（既に存在する場合はスキップ）
     */
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void saveVocabulary(String word) {
        // 正規化
        String normalizedWord = word.toLowerCase().trim();

        // 既に存在するかチェック
        if (vocabularyRepository.existsByWord(normalizedWord)) {
            logger.debug("単語は既に存在します: word={}", normalizedWord);
            return;
        }

        try {
            // Wordnik APIから情報を取得
            WordnikWordInfo wordInfo = wordnikApiClient.getWordInfo(normalizedWord);

            // エンティティを作成して保存
            Vocabulary vocab = new Vocabulary();
            vocab.setWord(normalizedWord);
            vocab.setMeaning_ja(wordInfo.getMeaningJa());
            vocab.setPronunciation(wordInfo.getPronunciation());
            vocab.setPart_of_speech(wordInfo.getPartOfSpeech());
            vocab.setExample_sentence(wordInfo.getExampleSentence());
            vocab.setExample_translate(wordInfo.getExampleTranslate());
            vocab.setAudio_url(wordInfo.getAudioUrl());

            vocabularyRepository.save(vocab);
            logger.info("単語を保存しました: word={}", normalizedWord);

        } catch (org.springframework.dao.DataIntegrityViolationException e) {
            logger.info("単語の保存時にUNIQUE制約違反（別スレッドが先に作成）: word={}", normalizedWord);
        } catch (Exception e) {
            logger.error("単語の保存に失敗しました: word={}", normalizedWord, e);
        }
    }

    /**
     * Wordnik APIの情報からVocabularyを保存（REQUIRES_NEW: 制約違反時に呼び出し元のトランザクションを汚染しない）
     */
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public Vocabulary saveVocabularyFromWordInfo(String word, WordnikWordInfo wordInfo) {
        Optional<Vocabulary> existing = vocabularyRepository.findFirstByWordOrderByVocabIdAsc(word);
        if (existing.isPresent()) {
            return existing.get();
        }

        try {
            Vocabulary vocab = Vocabulary.builder()
                .word(word)
                .base_form(wordInfo.getBaseForm())
                .translation_ja(wordInfo.getTranslationJa())
                .meaning_ja(wordInfo.getMeaningJa())
                .pronunciation(wordInfo.getPronunciation())
                .part_of_speech(wordInfo.getPartOfSpeech())
                .example_sentence(wordInfo.getExampleSentence())
                .example_translate(wordInfo.getExampleTranslate())
                .audio_url(wordInfo.getAudioUrl())
                .language("en")
                .isActive(true)
                .isDeleted(false)
                .build();

            Vocabulary savedVocab = vocabularyRepository.save(vocab);
            logger.info("Vocabularyを新規作成: word={}, baseForm={}, translationJa={}",
                word, vocab.getBase_form(), vocab.getTranslation_ja());
            return savedVocab;

        } catch (DataIntegrityViolationException e) {
            logger.info("Vocabulary作成時にUNIQUE制約違反（別スレッドが先に作成）: word={}", word);
            return vocabularyRepository.findFirstByWordOrderByVocabIdAsc(word).orElse(null);
        }
    }

    /**
     * 単語情報を取得
     */
    public Optional<Vocabulary> getVocabulary(String word) {
        return vocabularyRepository.findFirstByWordOrderByVocabIdAsc(word.toLowerCase().trim());
    }

    /**
     * テキストを正規化して単語に分割
     */
    private String[] normalizeAndSplit(String text) {
        // 句読点を除去し、小文字に変換して分割
        return text.toLowerCase()
            .replaceAll("[^a-zA-Z\\s]", "")
            .trim()
            .split("\\s+");
    }

    /**
     * 一般的な単語（保存する価値が低い）かどうかをチェック
     */
    private boolean isCommonWord(String word) {
        // 冠詞、代名詞、前置詞など
        List<String> commonWords = List.of(
            "a", "an", "the",
            "i", "you", "he", "she", "it", "we", "they",
            "me", "him", "her", "us", "them",
            "my", "your", "his", "its", "our", "their",
            "is", "am", "are", "was", "were", "be", "been", "being",
            "have", "has", "had",
            "do", "does", "did",
            "will", "would", "can", "could", "should", "may", "might",
            "in", "on", "at", "to", "for", "of", "with", "by",
            "and", "or", "but", "so", "if", "then",
            "this", "that", "these", "those"
        );

        return commonWords.contains(word.toLowerCase());
    }
}
