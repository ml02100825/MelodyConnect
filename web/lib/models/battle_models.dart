/// バトル関連のモデルクラス

/// バトル状態
enum BattleStatus {
  answering,        // 問題表示＋入力欄＋解答ボタンが有効
  submitting,       // 解答送信中
  waitingOpponent,  // 自分が解答済みで、相手の解答待ち
  roundResult,      // ラウンド結果表示
  matchFinished,    // 試合終了
}

/// 問題形式
enum QuestionFormat {
  listening,        // リスニング問題
  fillInTheBlank,   // 虫食い問題
}

/// 問題形式をパース
QuestionFormat parseQuestionFormat(String? format) {
  if (format == null) return QuestionFormat.fillInTheBlank;
  final lowerFormat = format.toLowerCase().trim();
  if (lowerFormat == 'listening') {
    return QuestionFormat.listening;
  }
  return QuestionFormat.fillInTheBlank;
}

/// プレイヤー情報
class BattlePlayer {
  final int userId;
  final String username;
  final String? iconUrl;
  final int? rating;
  bool hasAnswered;

  BattlePlayer({
    required this.userId,
    required this.username,
    this.iconUrl,
    this.rating,
    this.hasAnswered = false,
  });

  factory BattlePlayer.fromJson(Map<String, dynamic> json) {
    return BattlePlayer(
      userId: json['userId'] ?? json['id'] ?? 0,
      username: json['username'] ?? json['userName'] ?? 'Player',
      iconUrl: json['imageUrl'] ?? json['iconUrl'],
      rating: json['rating'] ?? json['rate'],
      hasAnswered: json['hasAnswered'] ?? false,
    );
  }
}

/// バトル問題
class BattleQuestion {
  final int questionId;
  final String text;
  final String questionFormat;
  final String? audioUrl;
  final String? translationJa;
  final String? songName;
  final String? artistName;
  final int roundNumber;
  final int totalRounds;
  final int roundTimeLimitMs;
  final int roundStartTimestamp;

  BattleQuestion({
    required this.questionId,
    required this.text,
    required this.questionFormat,
    this.audioUrl,
    this.translationJa,
    this.songName,
    this.artistName,
    required this.roundNumber,
    required this.totalRounds,
    required this.roundTimeLimitMs,
    required this.roundStartTimestamp,
  });

  factory BattleQuestion.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final rawRoundStartTimestamp = json['roundStartTimestamp'];
    final roundStartTimestamp = rawRoundStartTimestamp is num
        ? rawRoundStartTimestamp.toInt()
        : null;

    return BattleQuestion(
      questionId: json['questionId'] ?? 0,
      text: json['text'] ?? '',
      questionFormat: json['questionFormat'] ?? 'FILL_IN_THE_BLANK',
      audioUrl: json['audioUrl'],
      translationJa: json['translationJa'],
      songName: json['songName'],
      artistName: json['artistName'],
      roundNumber: json['roundNumber'] ?? 1,
      totalRounds: json['totalRounds'] ?? 10,
      roundTimeLimitMs: json['roundTimeLimitMs'] ?? 90000,
      // サーバー値欠落時は受信時刻を採用（= 実質フルタイム開始）
      roundStartTimestamp: roundStartTimestamp ?? now,
    );
  }

  /// サーバー時刻に基づいて残り時間（秒）を計算
  int calculateRemainingSeconds() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final elapsed = now - roundStartTimestamp;
    final remaining = (roundTimeLimitMs - elapsed) ~/ 1000;
    return remaining > 0 ? remaining : 0;
  }

  /// リスニング問題かどうか
  bool get isListening => parseQuestionFormat(questionFormat) == QuestionFormat.listening;

  /// 問題形式（enum）
  QuestionFormat get format => parseQuestionFormat(questionFormat);
}

/// ラウンド結果
class RoundResult {
  final int roundNumber;
  final int? questionId;
  final String correctAnswer;
  final int? roundWinnerId;
  final bool isNoCount;
  final String? noCountReason;

  // Player1の情報
  final int player1Id;
  final String? player1Answer;
  final bool player1Correct;
  final int player1ResponseTimeMs;

  // Player2の情報
  final int player2Id;
  final String? player2Answer;
  final bool player2Correct;
  final int player2ResponseTimeMs;

  // 現在のスコア
  final int player1Wins;
  final int player2Wins;

  // 試合継続フラグ
  final bool matchContinues;

  // 問題文
  final String? questionText;

  RoundResult({
    required this.roundNumber,
    this.questionId,
    required this.correctAnswer,
    this.roundWinnerId,
    required this.isNoCount,
    this.noCountReason,
    required this.player1Id,
    this.player1Answer,
    required this.player1Correct,
    required this.player1ResponseTimeMs,
    required this.player2Id,
    this.player2Answer,
    required this.player2Correct,
    required this.player2ResponseTimeMs,
    required this.player1Wins,
    required this.player2Wins,
    required this.matchContinues,
    this.questionText,
  });

  factory RoundResult.fromJson(Map<String, dynamic> json) {
    return RoundResult(
      roundNumber: json['roundNumber'] ?? 0,
      questionId: json['questionId'],
      correctAnswer: json['correctAnswer'] ?? '',
      roundWinnerId: json['roundWinnerId'],
      isNoCount: json['noCount'] ?? json['isNoCount'] ?? false,
      noCountReason: json['noCountReason'],
      player1Id: json['player1Id'] ?? 0,
      player1Answer: json['player1Answer'],
      player1Correct: json['player1Correct'] ?? false,
      player1ResponseTimeMs: json['player1ResponseTimeMs'] ?? 0,
      player2Id: json['player2Id'] ?? 0,
      player2Answer: json['player2Answer'],
      player2Correct: json['player2Correct'] ?? false,
      player2ResponseTimeMs: json['player2ResponseTimeMs'] ?? 0,
      player1Wins: json['player1Wins'] ?? 0,
      player2Wins: json['player2Wins'] ?? 0,
      matchContinues: json['matchContinues'] ?? true,
    questionText: json['questionText'],
    );
  }

  /// 指定ユーザーがラウンドの勝者かどうか
  bool isWinner(int userId) => roundWinnerId == userId;

  /// ノーカウント理由の表示テキスト
  String get noCountReasonText {
    switch (noCountReason) {
      case 'both_timeout':
        return '両者タイムアウト';
      case 'both_incorrect':
        return '両者不正解';
      case 'same_time':
        return '同タイム';
      default:
        return 'ノーカウント';
    }
  }
}

/// バトル結果
class BattleResult {
  final String matchUuid;
  final String result; // "win", "lose", "draw"
  final String outcomeReason; // "normal", "surrender", "timeout", "disconnect"
  final int myScore;
  final int opponentScore;
  final int rateChange;
  final int newRate;
  final List<RoundResult> rounds;
  final String? opponentSurrendered; // 相手が降参した場合のメッセージ

// ...



  BattleResult({
    required this.matchUuid,
    required this.result,
    required this.outcomeReason,
    required this.myScore,
    required this.opponentScore,
    required this.rateChange,
    required this.newRate,
    required this.rounds,
    this.opponentSurrendered,

  });

  factory BattleResult.fromJson(Map<String, dynamic> json) {
    return BattleResult(
      matchUuid: json['matchUuid'] ?? '',
      result: json['result'] ?? 'lose',
      outcomeReason: json['outcomeReason'] ?? 'normal',
      myScore: json['myScore'] ?? 0,
      opponentScore: json['opponentScore'] ?? 0,
      rateChange: json['rateChange'] ?? 0,
      newRate: json['newRate'] ?? 1500,
      rounds: (json['rounds'] as List<dynamic>?)
          ?.map((r) => RoundResult.fromJson(r))
          .toList() ?? [],
      opponentSurrendered: json['opponentSurrendered'],
    );
  }

  bool get isWin => result == 'win';
  bool get isLose => result == 'lose';
  bool get isDraw => result == 'draw';

  String get resultText {
    switch (result) {
      case 'win':
        return '勝利！';
      case 'lose':
        return '敗北...';
      case 'draw':
        return '引き分け';
      default:
        return result;
    }
  }

  String get outcomeReasonText {
    switch (outcomeReason) {
      case 'normal':
        return '';
      case 'surrender':
        return '（降参）';
      case 'timeout':
        return '（タイムアウト）';
      case 'disconnect':
        return '（切断）';
      default:
        return '';
    }
  }
}

/// バトル開始情報
class BattleStartInfo {
  final String matchId;
  final int user1Id;
  final int user2Id;
  final String language;
  final int questionCount;
  final int roundTimeLimitSeconds;
  final int winsRequired;
  final int maxRounds;
  final int? hostId;

  // ユーザー詳細情報
  final BattlePlayer? user1Info;
  final BattlePlayer? user2Info;

  BattleStartInfo({
    required this.matchId,
    required this.user1Id,
    required this.user2Id,
    required this.language,
    required this.questionCount,
    required this.roundTimeLimitSeconds,
    required this.winsRequired,
    required this.maxRounds,
    this.hostId,
    this.user1Info,
    this.user2Info,
  });

  factory BattleStartInfo.fromJson(Map<String, dynamic> json) {
    return BattleStartInfo(
      matchId: json['matchId'] ?? '',
      user1Id: json['user1Id'] ?? 0,
      user2Id: json['user2Id'] ?? 0,
      language: json['language'] ?? 'english',
      questionCount: json['questionCount'] ?? 10,
      roundTimeLimitSeconds: json['roundTimeLimitSeconds'] ?? 90,
      winsRequired: json['winsRequired'] ?? 3,
      maxRounds: json['maxRounds'] ?? 10,
      hostId: json['hostId'],
      user1Info: json['user1Info'] != null
          ? BattlePlayer.fromJson(json['user1Info'])
          : null,
      user2Info: json['user2Info'] != null
          ? BattlePlayer.fromJson(json['user2Info'])
          : null,
    );
  }
}
