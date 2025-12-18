/// ユーザー単語帳のモデルクラス
class VocabularyItem {
  final int userVocabId;
  final int vocabId;
  final String word;
  final String? baseForm;        // ★追加: 原形
  final String? translationJa;   // ★追加: 簡潔な日本語訳
  final String meaningJa;
  final String? pronunciation;
  final String? partOfSpeech;
  final String? exampleSentence;
  final String? exampleTranslation;
  final String? audioUrl;
  final String? language;
  bool isFavorite;
  bool isLearned;
  final DateTime firstLearnedAt;

  VocabularyItem({
    required this.userVocabId,
    required this.vocabId,
    required this.word,
    this.baseForm,
    this.translationJa,
    required this.meaningJa,
    this.pronunciation,
    this.partOfSpeech,
    this.exampleSentence,
    this.exampleTranslation,
    this.audioUrl,
    this.language,
    required this.isFavorite,
    required this.isLearned,
    required this.firstLearnedAt,
  });

  /// 表示用の日本語訳を取得
  /// translationJaを優先表示（nullの場合のみmeaningJa）
  String get displayMeaning {
    return translationJa ?? meaningJa;
  }

  /// 表示用の単語を取得
  /// baseFormがあればそれを、なければwordを返す
  String get displayWord {
    if (baseForm != null && baseForm!.isNotEmpty) {
      return baseForm!;
    }
    return word;
  }

  factory VocabularyItem.fromJson(Map<String, dynamic> json) {
    return VocabularyItem(
      userVocabId: json['userVocabId'] ?? 0,
      vocabId: json['vocabId'] ?? 0,
      word: json['word'] ?? '',
      baseForm: json['baseForm'],
      translationJa: json['translationJa'],
      meaningJa: json['meaningJa'] ?? '',
      pronunciation: json['pronunciation'],
      partOfSpeech: json['partOfSpeech'],
      exampleSentence: json['exampleSentence'],
      exampleTranslation: json['exampleTranslation'],
      audioUrl: json['audioUrl'],
      language: json['language'],
      isFavorite: json['isFavorite'] ?? false,
      isLearned: json['isLearned'] ?? false,
      firstLearnedAt: json['firstLearnedAt'] != null
          ? DateTime.parse(json['firstLearnedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userVocabId': userVocabId,
      'vocabId': vocabId,
      'word': word,
      'baseForm': baseForm,
      'translationJa': translationJa,
      'meaningJa': meaningJa,
      'pronunciation': pronunciation,
      'partOfSpeech': partOfSpeech,
      'exampleSentence': exampleSentence,
      'exampleTranslation': exampleTranslation,
      'audioUrl': audioUrl,
      'language': language,
      'isFavorite': isFavorite,
      'isLearned': isLearned,
      'firstLearnedAt': firstLearnedAt.toIso8601String(),
    };
  }

  /// 言語コードを表示用の言語名に変換
  String get languageDisplay {
    switch (language?.toLowerCase()) {
      case 'en':
        return '英語';
      case 'ko':
        return '韓国語';
      case 'zh':
        return '中国語';
      case 'ja':
        return '日本語';
      default:
        return language ?? '不明';
    }
  }
}

/// ユーザー単語帳APIレスポンス
class VocabularyResponse {
  final bool success;
  final String? message;
  final int? totalCount;
  final List<VocabularyItem> vocabularies;

  VocabularyResponse({
    required this.success,
    this.message,
    this.totalCount,
    required this.vocabularies,
  });

  factory VocabularyResponse.fromJson(Map<String, dynamic> json) {
    return VocabularyResponse(
      success: json['success'] ?? false,
      message: json['message'],
      totalCount: json['totalCount'],
      vocabularies: (json['vocabularies'] as List<dynamic>?)
              ?.map((item) => VocabularyItem.fromJson(item))
              .toList() ??
          [],
    );
  }
}

/// word_list_screen.dart用のWordモデル（後方互換性のため）
class Word {
  final int id;
  final String word;
  final String? baseForm;        // ★追加: 原形
  final String? translationJa;   // ★追加: 簡潔な日本語訳
  final String pronunciation;
  final String partOfSpeech;
  final String status;
  final List<String> meanings;
  final String? exampleSentence;
  final String? exampleTranslation;
  bool isFavorite;
  bool isLearned;

  Word({
    required this.id,
    required this.word,
    this.baseForm,
    this.translationJa,
    required this.pronunciation,
    required this.partOfSpeech,
    required this.status,
    required this.meanings,
    this.exampleSentence,
    this.exampleTranslation,
    required this.isFavorite,
    required this.isLearned,
  });

  /// 表示用の日本語訳を取得
  String get displayMeaning {
    return translationJa ?? (meanings.isNotEmpty ? meanings.first : '');
  }

  /// 表示用の単語を取得
  String get displayWord {
    if (baseForm != null && baseForm!.isNotEmpty) {
      return baseForm!;
    }
    return word;
  }

  /// VocabularyItemからWordに変換
  factory Word.fromVocabularyItem(VocabularyItem item) {
    return Word(
      id: item.userVocabId,
      word: item.word,
      baseForm: item.baseForm,
      translationJa: item.translationJa,
      pronunciation: item.pronunciation ?? '',
      partOfSpeech: item.partOfSpeech ?? '',
      status: item.isLearned ? '学習済み' : (item.isFavorite ? 'お気に入り' : '未学習'),
      meanings: [item.meaningJa],
      exampleSentence: item.exampleSentence,
      exampleTranslation: item.exampleTranslation,
      isFavorite: item.isFavorite,
      isLearned: item.isLearned,
    );
  }
}