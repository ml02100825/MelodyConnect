package com.example.api.service;

import com.example.api.client.WordnikApiClient;
import com.example.api.dto.WordnikWordInfo;
import com.example.api.entity.User;
import com.example.api.entity.UserVocabulary;
import com.example.api.entity.Vocabulary;
import com.example.api.repository.UserRepository;
import com.example.api.repository.UserVocabularyRepository;
import com.example.api.repository.VocabularyRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.Set;

/**
 * UserVocabulary管理サービス
 * クイズ完了時にユーザーの学習単語を登録します
 */
@Service
public class UserVocabularyService {

    private static final Logger logger = LoggerFactory.getLogger(UserVocabularyService.class);

    @Autowired
    private UserVocabularyRepository userVocabularyRepository;

    @Autowired
    private VocabularyRepository vocabularyRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private WordnikApiClient wordnikApiClient;

    /**
     * 除外する一般的な単語（学習価値が低い）
     * 冠詞、代名詞、前置詞、助動詞、接続詞、基本動詞など
     */
    private static final Set<String> COMMON_WORDS = Set.of(
        // 冠詞
        "a", "an", "the",
        
        // 人称代名詞（主格）
        "i", "you", "he", "she", "it", "we", "they",
        
        // 人称代名詞（目的格）
        "me", "him", "her", "us", "them",
        
        // 所有代名詞・所有格（herは上で含めたので除外）
        "my", "your", "his", "its", "our", "their",
        "mine", "yours", "hers", "ours", "theirs",
        
        // 再帰代名詞
        "myself", "yourself", "himself", "herself", "itself", "ourselves", "themselves",
        
        // 指示代名詞
        "this", "that", "these", "those",
        
        // 疑問詞
        "what", "which", "who", "whom", "whose", "where", "when", "why", "how",
        
        // 不定代名詞
        "some", "any", "no", "none", "all", "both", "each", "every",
        "someone", "anyone", "everyone", "nobody", "something", "anything", "everything", "nothing",
        
        // be動詞
        "is", "am", "are", "was", "were", "be", "been", "being",
        
        // have動詞
        "have", "has", "had", "having",
        
        // do動詞
        "do", "does", "did", "doing", "done",
        
        // 助動詞
        "will", "would", "shall", "should", "can", "could", "may", "might", "must",
        "ought", "need", "dare",
        
        // 前置詞
        "in", "on", "at", "to", "for", "of", "with", "by", "from", "up", "down",
        "about", "into", "through", "during", "before", "after", "above", "below",
        "between", "under", "over", "out", "off", "against", "among", "within",
        
        // 接続詞
        "and", "or", "but", "so", "if", "then", "because", "although", "while",
        "as", "than", "whether", "unless", "until", "since",
        
        // その他の一般的な単語
        "there", "here", "now", "just", "only", "also", "very", "too", "much",
        "more", "most", "less", "least", "many", "few", "other", "another",
        "such", "same", "different", "first", "last", "next", "new", "old",
        "good", "bad", "great", "little", "big", "small", "long", "short",
        "high", "low", "right", "left", "yes", "not", "never", "always",
        "get", "got", "go", "goes", "went", "gone", "going",
        "come", "comes", "came", "coming",
        "make", "makes", "made", "making",
        "take", "takes", "took", "taken", "taking",
        "know", "knows", "knew", "known", "knowing",
        "think", "thinks", "thought", "thinking",
        "see", "sees", "saw", "seen", "seeing",
        "want", "wants", "wanted", "wanting",
        "use", "uses", "used", "using",
        "find", "finds", "found", "finding",
        "give", "gives", "gave", "given", "giving",
        "tell", "tells", "told", "telling",
        "say", "says", "said", "saying",
        "let", "lets", "letting",
        "put", "puts", "putting",
        "keep", "keeps", "kept", "keeping",
        "begin", "begins", "began", "begun", "beginning",
        "seem", "seems", "seemed", "seeming",
        "help", "helps", "helped", "helping",
        "show", "shows", "showed", "shown", "showing",
        "hear", "hears", "heard", "hearing",
        "play", "plays", "played", "playing",
        "run", "runs", "ran", "running",
        "move", "moves", "moved", "moving",
        "live", "lives", "lived", "living",
        "believe", "believes", "believed", "believing",
        "hold", "holds", "held", "holding",
        "bring", "brings", "brought", "bringing",
        "happen", "happens", "happened", "happening",
        "write", "writes", "wrote", "written", "writing",
        "provide", "provides", "provided", "providing",
        "sit", "sits", "sat", "sitting",
        "stand", "stands", "stood", "standing",
        "lose", "loses", "lost", "losing",
        "pay", "pays", "paid", "paying",
        "meet", "meets", "met", "meeting",
        "include", "includes", "included", "including",
        "continue", "continues", "continued", "continuing",
        "set", "sets", "setting",
        "learn", "learns", "learned", "learning",
        "change", "changes", "changed", "changing",
        "lead", "leads", "led", "leading",
        "understand", "understands", "understood", "understanding",
        "watch", "watches", "watched", "watching",
        "follow", "follows", "followed", "following",
        "stop", "stops", "stopped", "stopping",
        "create", "creates", "created", "creating",
        "speak", "speaks", "spoke", "spoken", "speaking",
        "read", "reads", "reading",
        "spend", "spends", "spent", "spending",
        "grow", "grows", "grew", "grown", "growing",
        "open", "opens", "opened", "opening",
        "walk", "walks", "walked", "walking",
        "win", "wins", "won", "winning",
        "offer", "offers", "offered", "offering",
        "remember", "remembers", "remembered", "remembering",
        "consider", "considers", "considered", "considering",
        "appear", "appears", "appeared", "appearing",
        "buy", "buys", "bought", "buying",
        "wait", "waits", "waited", "waiting",
        "serve", "serves", "served", "serving",
        "die", "dies", "died", "dying",
        "send", "sends", "sent", "sending",
        "expect", "expects", "expected", "expecting",
        "build", "builds", "built", "building",
        "stay", "stays", "stayed", "staying",
        "fall", "falls", "fell", "fallen", "falling",
        "cut", "cuts", "cutting",
        "reach", "reaches", "reached", "reaching",
        "kill", "kills", "killed", "killing",
        "remain", "remains", "remained", "remaining"
    );

    /**
     * FILL_IN_BLANK問題の答えを非同期でUserVocabularyに登録
     * QuizServiceから呼ばれる
     */
    @Async("vocabularyTaskExecutor")
    public void registerFillInBlankAnswerAsync(Long userId, String word) {
        registerFillInBlankAnswer(userId, word);
    }

    /**
     * FILL_IN_BLANK問題の答えをUserVocabularyに登録
     *
     * @param userId ユーザーID
     * @param word 登録する単語（問題の答え）
     */
    @Transactional
    public void registerFillInBlankAnswer(Long userId, String word) {
        if (word == null || word.trim().isEmpty()) {
            return;
        }

        String normalizedWord = word.toLowerCase().trim();
        
        // 一般的な単語は除外
        if (isCommonWord(normalizedWord)) {
            logger.debug("一般的な単語のため登録をスキップ: word={}", normalizedWord);
            return;
        }

        registerWordToUserVocabulary(userId, normalizedWord, false);
    }

    /**
     * リスニング問題で間違えた単語を非同期でUserVocabularyに登録
     * QuizServiceから呼ばれる
     */
    @Async("vocabularyTaskExecutor")
    public void registerListeningMistakesAsync(Long userId, String userAnswer, String correctAnswer) {
        registerListeningMistakes(userId, userAnswer, correctAnswer);
    }

    /**
     * リスニング問題で間違えた単語をUserVocabularyに登録
     *
     * @param userId ユーザーID
     * @param userAnswer ユーザーの回答
     * @param correctAnswer 正解
     * @return 登録された単語のリスト
     */
    @Transactional
    public List<String> registerListeningMistakes(Long userId, String userAnswer, String correctAnswer) {
        logger.info("リスニング問題の間違いを分析: userId={}", userId);
        
        List<String> registeredWords = new ArrayList<>();

        // 単語に分割
        String[] userWords = normalizeAndSplit(userAnswer);
        String[] correctWords = normalizeAndSplit(correctAnswer);

        // 間違えた単語を特定
        for (int i = 0; i < correctWords.length; i++) {
            String correctWord = correctWords[i];

            // ユーザーの回答に該当する位置の単語が存在しないか、異なる場合
            boolean isIncorrect = i >= userWords.length || !userWords[i].equalsIgnoreCase(correctWord);

            if (isIncorrect && !isCommonWord(correctWord) && correctWord.length() > 1) {
                boolean registered = registerWordToUserVocabulary(userId, correctWord, true);
                if (registered) {
                    registeredWords.add(correctWord);
                }
            }
        }

        logger.info("リスニングで間違えた単語を登録: count={}, words={}", registeredWords.size(), registeredWords);
        return registeredWords;
    }

    /**
     * 単語をUserVocabularyに登録
     * 
     * @param userId ユーザーID
     * @param word 登録する単語
     * @param fetchFromWordnik Vocabularyに存在しない場合Wordnik APIから取得するか
     * @return 登録成功したかどうか
     */
    @Transactional
    public boolean registerWordToUserVocabulary(Long userId, String word, boolean fetchFromWordnik) {
        String normalizedWord = word.toLowerCase().trim();
        
        try {
            // 1. ユーザーを取得
            User user = userRepository.findById(userId)
                .orElse(null);
            
            if (user == null) {
                logger.warn("ユーザーが見つかりません: userId={}", userId);
                return false;
            }

            // 2. Vocabularyを取得または作成（キャッシュ使用）
            Vocabulary vocabulary = findVocabularyByWordCached(normalizedWord);

            if (vocabulary == null) {
                if (fetchFromWordnik) {
                    // Wordnik APIから情報を取得して新規作成
                    vocabulary = createVocabularyFromWordnik(normalizedWord);
                    if (vocabulary == null) {
                        logger.warn("Vocabularyの作成に失敗: word={}", normalizedWord);
                        return false;
                    }
                } else {
                    // Vocabularyが存在しない場合はスキップ
                    logger.debug("Vocabularyが存在しないためスキップ: word={}", normalizedWord);
                    return false;
                }
            }

            // 3. 既にUserVocabularyに登録済みかチェック
            if (userVocabularyRepository.existsByUserIdAndVocabId(userId, vocabulary.getVocab_id())) {
                logger.debug("既に登録済みのためスキップ: userId={}, word={}", userId, normalizedWord);
                return false;
            }

            // 4. UserVocabularyに登録
            UserVocabulary userVocabulary = new UserVocabulary();
            userVocabulary.setUser(user);
            userVocabulary.setVocabulary(vocabulary);
            userVocabulary.setLearnedWordFlag(false);
            userVocabulary.setFavoriteFlag(false);

            userVocabularyRepository.save(userVocabulary);
            logger.info("UserVocabularyに登録: userId={}, word={}", userId, normalizedWord);
            return true;

        } catch (Exception e) {
            logger.error("UserVocabulary登録中にエラー: userId={}, word={}", userId, normalizedWord, e);
            return false;
        }
    }

    /**
     * Vocabularyをキャッシュから取得（キャッシュミス時はDBから取得）
     */
    @Cacheable(value = "vocabularyCache", key = "#word", unless = "#result == null")
    public Vocabulary findVocabularyByWordCached(String word) {
        return vocabularyRepository.findByWord(word).orElse(null);
    }

    /**
     * Wordnik APIから単語情報を取得してVocabularyを作成
     */
    private Vocabulary createVocabularyFromWordnik(String word) {
        try {
            WordnikWordInfo wordInfo = wordnikApiClient.getWordInfo(word);
            
            if (wordInfo == null || wordInfo.getMeaningJa() == null) {
                logger.warn("Wordnik APIから情報を取得できませんでした: word={}", word);
                return null;
            }

            // モックデータのメッセージが含まれている場合はスキップ
            if (wordInfo.getMeaningJa().contains("辞書情報を取得できませんでした") ||
                wordInfo.getMeaningJa().equals("No definition available") ||
                wordInfo.getMeaningJa().equals("Definition not available")) {
                logger.warn("有効な定義が取得できませんでした: word={}", word);
                return null;
            }

            Vocabulary vocab = Vocabulary.builder()
                .word(word)
                .base_form(wordInfo.getBaseForm())           // ★追加: 原形
                .translation_ja(wordInfo.getTranslationJa()) // ★追加: 簡潔訳
                .meaning_ja(wordInfo.getMeaningJa())
                .pronunciation(wordInfo.getPronunciation())
                .part_of_speech(wordInfo.getPartOfSpeech())
                .example_sentence(wordInfo.getExampleSentence())
                .example_translate(wordInfo.getExampleTranslate())
                .audio_url(wordInfo.getAudioUrl())
                .language("en")  // デフォルトは英語
                .isActive(true)
                .isDeleted(false)
                .build();

            Vocabulary savedVocab = vocabularyRepository.save(vocab);
            logger.info("Vocabularyを新規作成: word={}, baseForm={}, translationJa={}", 
                word, vocab.getBase_form(), vocab.getTranslation_ja());
            return savedVocab;

        } catch (Exception e) {
            logger.error("Vocabulary作成中にエラー: word={}", word, e);
            return null;
        }
    }

    /**
     * テキストを正規化して単語に分割
     */
    private String[] normalizeAndSplit(String text) {
        if (text == null || text.isEmpty()) {
            return new String[0];
        }
        // 句読点を除去し、小文字に変換して分割
        return text.toLowerCase()
            .replaceAll("[^a-zA-Z\\s]", "")
            .trim()
            .split("\\s+");
    }

    /**
     * 一般的な単語かどうかをチェック
     */
    private boolean isCommonWord(String word) {
        return COMMON_WORDS.contains(word.toLowerCase());
    }

    /**
     * ユーザーの学習単語一覧を取得（Vocabularyも含む）
     */
    @Transactional(readOnly = true)
    public List<UserVocabulary> getUserVocabularies(Long userId) {
        return userVocabularyRepository.findByUserIdWithVocabulary(userId);
    }

    /**
     * ユーザーのお気に入り単語一覧を取得
     */
    @Transactional(readOnly = true)
    public List<UserVocabulary> getFavoriteVocabularies(Long userId) {
        return userVocabularyRepository.findFavoritesByUserId(userId);
    }

    /**
     * お気に入りフラグを更新
     */
    @Transactional
    public void updateFavoriteFlag(Integer userVocabId, boolean favorite) {
        UserVocabulary uv = userVocabularyRepository.findById(userVocabId)
            .orElseThrow(() -> new IllegalArgumentException("UserVocabularyが見つかりません: " + userVocabId));
        uv.setFavoriteFlag(favorite);
        userVocabularyRepository.save(uv);
    }

    /**
     * 学習済みフラグを更新
     */
    @Transactional
    public void updateLearnedFlag(Integer userVocabId, boolean learned) {
        UserVocabulary uv = userVocabularyRepository.findById(userVocabId)
            .orElseThrow(() -> new IllegalArgumentException("UserVocabularyが見つかりません: " + userVocabId));
        uv.setLearnedWordFlag(learned);
        userVocabularyRepository.save(uv);
    }
}