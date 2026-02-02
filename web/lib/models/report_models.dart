/// 通報リクエスト
class ReportRequest {
  final String reportType; // "VOCABULARY" or "QUESTION"
  final int targetId;
  final String reportContent; // コメント（空文字可）
  final int userId;

  ReportRequest({
    required this.reportType,
    required this.targetId,
    required this.reportContent,
    required this.userId,
  });

  Map<String, dynamic> toJson() => {
    'reportType': reportType,
    'targetId': targetId,
    'reportContent': reportContent,
    'userId': userId,
  };
}

/// 通報レスポンス
class ReportResponse {
  final bool success;
  final String message;
  final int? reportId;

  ReportResponse({
    required this.success,
    required this.message,
    this.reportId,
  });

  factory ReportResponse.fromJson(Map<String, dynamic> json) {
    return ReportResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      reportId: json['reportId'],
    );
  }
}
