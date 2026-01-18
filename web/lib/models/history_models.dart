/// 対戦履歴一覧アイテム
class BattleHistoryItem {
  final int resultId;
  final String enemyName;
  final int enemyId;
  final int playerScore;
  final int enemyScore;
  final bool isWin;
  final String matchType;
  final String endedAt;
  final int? rateAfterMatch; // レート変動
  final int? rateAtEnd;      // 対戦終了時のレート
  final String outcomeReason;

  BattleHistoryItem({
    required this.resultId,
    required this.enemyName,
    required this.enemyId,
    required this.playerScore,
    required this.enemyScore,
    required this.isWin,
    required this.matchType,
    required this.endedAt,
    this.rateAfterMatch,
    this.rateAtEnd,
    required this.outcomeReason,
  });

  factory BattleHistoryItem.fromJson(Map<String, dynamic> json) {
    return BattleHistoryItem(
      resultId: json['resultId'] ?? 0,
      enemyName: json['enemyName'] ?? '',
      enemyId: json['enemyId'] ?? 0,
      playerScore: json['playerScore'] ?? 0,
      enemyScore: json['enemyScore'] ?? 0,
      isWin: json['isWin'] ?? json['win'] ?? false,
      matchType: json['matchType'] ?? '',
      endedAt: json['endedAt'] ?? '',
      rateAfterMatch: json['rateAfterMatch'],
      rateAtEnd: json['rateAtEnd'],
      outcomeReason: json['outcomeReason'] ?? 'normal',
    );
  }
}

/// 対戦履歴詳細
class BattleHistoryDetail {
  final int resultId;
  final String enemyName;
  final int enemyId;
  final int playerScore;
  final int enemyScore;
  final bool isWin;
  final String matchType;
  final String endedAt;
  final int? rateAfterMatch; // レート変動
  final int? rateAtEnd;      // 対戦終了時のレート
  final String outcomeReason;
  final String? useLanguage;
  final List<RoundDetail> rounds;

  BattleHistoryDetail({
    required this.resultId,
    required this.enemyName,
    required this.enemyId,
    required this.playerScore,
    required this.enemyScore,
    required this.isWin,
    required this.matchType,
    required this.endedAt,
    this.rateAfterMatch,
    this.rateAtEnd,
    required this.outcomeReason,
    this.useLanguage,
    required this.rounds,
  });

  factory BattleHistoryDetail.fromJson(Map<String, dynamic> json) {
    return BattleHistoryDetail(
      resultId: json['resultId'] ?? 0,
      enemyName: json['enemyName'] ?? '',
      enemyId: json['enemyId'] ?? 0,
      playerScore: json['playerScore'] ?? 0,
      enemyScore: json['enemyScore'] ?? 0,
      isWin: json['isWin'] ?? json['win'] ?? false,
      matchType: json['matchType'] ?? '',
      endedAt: json['endedAt'] ?? '',
      rateAfterMatch: json['rateAfterMatch'],
      rateAtEnd: json['rateAtEnd'],
      outcomeReason: json['outcomeReason'] ?? 'normal',
      useLanguage: json['useLanguage'],
      rounds: (json['rounds'] as List<dynamic>?)
              ?.map((e) => RoundDetail.fromJson(e))
              .toList() ??
          [],
    );
  }
}

/// ラウンド詳細
class RoundDetail {
  final int roundNumber;
  final int? questionId;
  final String questionText;
  final String questionFormat;
  final String playerAnswer;
  final String enemyAnswer;
  final bool isPlayerCorrect;
  final bool isEnemyCorrect;
  final String roundWinner;
  final String status;        // "played", "surrendered", "not_played"
  final String? correctAnswer; // 正解（降参時に表示用）

  RoundDetail({
    required this.roundNumber,
    this.questionId,
    required this.questionText,
    required this.questionFormat,
    required this.playerAnswer,
    required this.enemyAnswer,
    required this.isPlayerCorrect,
    required this.isEnemyCorrect,
    required this.roundWinner,
    required this.status,
    this.correctAnswer,
  });

  factory RoundDetail.fromJson(Map<String, dynamic> json) {
    return RoundDetail(
      roundNumber: json['roundNumber'] ?? 0,
      questionId: json['questionId'],
      questionText: json['questionText'] ?? '',
      questionFormat: json['questionFormat'] ?? '',
      playerAnswer: json['playerAnswer'] ?? '',
      enemyAnswer: json['enemyAnswer'] ?? '',
      isPlayerCorrect: json['isPlayerCorrect'] ?? json['playerCorrect'] ?? false,
      isEnemyCorrect: json['isEnemyCorrect'] ?? json['enemyCorrect'] ?? false,
      roundWinner: json['roundWinner'] ?? 'draw',
      status: json['status'] ?? 'played',
      correctAnswer: json['correctAnswer'],
    );
  }
}

/// 学習履歴一覧アイテム
class LearningHistoryItem {
  final int historyId;
  final String learningAt;
  final int correctCount;
  final int totalCount;
  final String learningLang;

  LearningHistoryItem({
    required this.historyId,
    required this.learningAt,
    required this.correctCount,
    required this.totalCount,
    required this.learningLang,
  });

  factory LearningHistoryItem.fromJson(Map<String, dynamic> json) {
    return LearningHistoryItem(
      historyId: json['historyId'] ?? 0,
      learningAt: json['learningAt'] ?? '',
      correctCount: json['correctCount'] ?? 0,
      totalCount: json['totalCount'] ?? 0,
      learningLang: json['learningLang'] ?? '',
    );
  }
}

/// 学習履歴詳細
class LearningHistoryDetail {
  final int historyId;
  final String learningAt;
  final int correctCount;
  final int totalCount;
  final String learningLang;
  final List<QuestionDetail> questions;

  LearningHistoryDetail({
    required this.historyId,
    required this.learningAt,
    required this.correctCount,
    required this.totalCount,
    required this.learningLang,
    required this.questions,
  });

  factory LearningHistoryDetail.fromJson(Map<String, dynamic> json) {
    return LearningHistoryDetail(
      historyId: json['historyId'] ?? 0,
      learningAt: json['learningAt'] ?? '',
      correctCount: json['correctCount'] ?? 0,
      totalCount: json['totalCount'] ?? 0,
      learningLang: json['learningLang'] ?? '',
      questions: (json['questions'] as List<dynamic>?)
              ?.map((e) => QuestionDetail.fromJson(e))
              .toList() ??
          [],
    );
  }
}

/// 問題詳細
class QuestionDetail {
  final int? questionId;
  final String questionText;
  final String correctAnswer;
  final String userAnswer;
  final bool isCorrect;
  final String questionFormat;

  QuestionDetail({
    this.questionId,
    required this.questionText,
    required this.correctAnswer,
    required this.userAnswer,
    required this.isCorrect,
    required this.questionFormat,
  });

  factory QuestionDetail.fromJson(Map<String, dynamic> json) {
    return QuestionDetail(
      questionId: json['questionId'],
      questionText: json['questionText'] ?? '',
      correctAnswer: json['correctAnswer'] ?? '',
      userAnswer: json['userAnswer'] ?? '',
      isCorrect: json['isCorrect'] ?? json['correct'] ?? false,
      questionFormat: json['questionFormat'] ?? '',
    );
  }
}
