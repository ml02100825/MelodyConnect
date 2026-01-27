/// クイズ開始リクエスト
class QuizStartRequest {
  final int userId;
  final String language;
  final String generationMode;
  final String questionFormat;
  final int questionCount;
  final String? genreName;
  final String? songUrl;

  QuizStartRequest({
    required this.userId,
    required this.language,
    required this.generationMode,
    required this.questionFormat,
    required this.questionCount,
    this.genreName,
    this.songUrl,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'language': language,
    'generationMode': generationMode,
    'questionFormat': questionFormat,
    'questionCount': questionCount,
    if (genreName != null) 'genreName': genreName,
    if (songUrl != null) 'songUrl': songUrl,
  };
}

/// クイズ開始レスポンス
class QuizStartResponse {
  final int? sessionId;
  final List<QuizQuestion> questions;
  final SongInfo? songInfo;
  final int totalCount;
  final String? message;

  QuizStartResponse({
    this.sessionId,
    required this.questions,
    this.songInfo,
    required this.totalCount,
    this.message,
  });

  factory QuizStartResponse.fromJson(Map<String, dynamic> json) {
    return QuizStartResponse(
      sessionId: json['sessionId'],
      questions: (json['questions'] as List<dynamic>?)
          ?.map((q) => QuizQuestion.fromJson(q))
          .toList() ?? [],
      songInfo: json['songInfo'] != null
          ? SongInfo.fromJson(json['songInfo'])
          : null,
      totalCount: json['totalCount'] ?? 0,
      message: json['message'],
    );
  }
}

/// クイズ問題
class QuizQuestion {
  final int questionId;
  final String text;
  final String questionFormat;
  final int difficultyLevel;
  final String? audioUrl;
  final String? language;
  final String? answer;  // 正解（リスニングの場合はcompleteSentence）
  final String? completeSentence;  // ★ 追加: 完全な文
  final String? translationJa;     // ★ 追加: 日本語訳

  QuizQuestion({
    required this.questionId,
    required this.text,
    required this.questionFormat,
    required this.difficultyLevel,
    this.audioUrl,
    this.language,
    this.answer,
    this.completeSentence,  // ★ 追加
    this.translationJa,     // ★ 追加
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      questionId: json['questionId'],
      text: json['text'],
      questionFormat: json['questionFormat'],
      difficultyLevel: json['difficultyLevel'] ?? 1,
      audioUrl: json['audioUrl'],
      language: json['language'],
      answer: json['answer'],
      completeSentence: json['completeSentence'],  // ★ 追加
      translationJa: json['translationJa'],        // ★ 追加
    );
  }
}

/// 曲情報
class SongInfo {
  final int songId;
  final String songName;
  final String? artistName;  // nullable に変更（バックエンドがnullを返す可能性がある）
  final String? genre;

  SongInfo({
    required this.songId,
    required this.songName,
    this.artistName,
    this.genre,
  });

  factory SongInfo.fromJson(Map<String, dynamic> json) {
    return SongInfo(
      songId: json['songId'],
      songName: json['songName'] ?? '',
      artistName: json['artistName'],
      genre: json['genre'],
    );
  }
}

/// クイズ完了リクエスト
class QuizCompleteRequest {
  final int sessionId;
  final int userId;
  final List<AnswerResult> answers;
  final bool retired;  // リタイアフラグ（trueの場合はカウント増加しない）

  QuizCompleteRequest({
    required this.sessionId,
    required this.userId,
    required this.answers,
    this.retired = false,
  });

  Map<String, dynamic> toJson() => {
    'sessionId': sessionId,
    'userId': userId,
    'answers': answers.map((a) => a.toJson()).toList(),
    'retired': retired,
  };
}

/// 回答結果
class AnswerResult {
  final int questionId;
  final String userAnswer;
  final bool isCorrect;

  AnswerResult({
    required this.questionId,
    required this.userAnswer,
    required this.isCorrect,
  });

  Map<String, dynamic> toJson() => {
    'questionId': questionId,
    'userAnswer': userAnswer,
    'isCorrect': isCorrect,
  };
}

/// クイズ完了レスポンス
class QuizCompleteResponse {
  final int sessionId;
  final int correctCount;
  final int totalCount;
  final double accuracy;
  final List<QuestionResult> questionResults;
  final SongInfo? songInfo;
  final String? message;

  QuizCompleteResponse({
    required this.sessionId,
    required this.correctCount,
    required this.totalCount,
    required this.accuracy,
    required this.questionResults,
    this.songInfo,
    this.message,
  });

  factory QuizCompleteResponse.fromJson(Map<String, dynamic> json) {
    return QuizCompleteResponse(
      sessionId: json['sessionId'] ?? 0,
      correctCount: json['correctCount'] ?? 0,
      totalCount: json['totalCount'] ?? 0,
      accuracy: (json['accuracy'] ?? 0).toDouble(),
      questionResults: (json['questionResults'] as List<dynamic>?)
          ?.map((r) => QuestionResult.fromJson(r))
          .toList() ?? [],
      songInfo: json['songInfo'] != null
          ? SongInfo.fromJson(json['songInfo'])
          : null,
      message: json['message'],
    );
  }
}

/// 問題結果
class QuestionResult {
  final int questionId;
  final String questionText;
  final String questionFormat;
  final String correctAnswer;
  final String userAnswer;
  final bool isCorrect;
  final int difficultyLevel;

  QuestionResult({
    required this.questionId,
    required this.questionText,
    required this.questionFormat,
    required this.correctAnswer,
    required this.userAnswer,
    required this.isCorrect,
    required this.difficultyLevel,
  });

  factory QuestionResult.fromJson(Map<String, dynamic> json) {
    return QuestionResult(
      questionId: json['questionId'],
      questionText: json['questionText'],
      questionFormat: json['questionFormat'],
      correctAnswer: json['correctAnswer'],
      userAnswer: json['userAnswer'],
      isCorrect: json['isCorrect'],
      difficultyLevel: json['difficultyLevel'] ?? 1,
    );
  }
}