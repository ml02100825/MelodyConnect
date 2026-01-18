import 'package:flutter/material.dart';
import '../models/history_models.dart';
import '../services/history_api_service.dart';
import '../services/token_storage_service.dart';

/// 対戦履歴詳細画面
class BattleHistoryDetailScreen extends StatefulWidget {
  final int resultId;

  const BattleHistoryDetailScreen({
    super.key,
    required this.resultId,
  });

  @override
  State<BattleHistoryDetailScreen> createState() => _BattleHistoryDetailScreenState();
}

class _BattleHistoryDetailScreenState extends State<BattleHistoryDetailScreen> {
  final HistoryApiService _apiService = HistoryApiService();
  final TokenStorageService _tokenStorage = TokenStorageService();

  BattleHistoryDetail? _detail;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    try {
      final token = await _tokenStorage.getAccessToken();

      if (token == null) {
        setState(() {
          _errorMessage = '認証情報を取得できませんでした';
          _isLoading = false;
        });
        return;
      }

      final detail = await _apiService.getBattleHistoryDetail(widget.resultId, token);
      setState(() {
        _detail = detail;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '詳細の取得に失敗しました: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('対戦詳細'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(_errorMessage!, style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    if (_detail == null) {
      return const Center(child: Text('データがありません'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // サマリーカード
          _buildSummaryCard(),
          const SizedBox(height: 24),
          // ラウンド詳細
          const Text(
            'ラウンド詳細',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ..._detail!.rounds.map((round) => _buildRoundCard(round)),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final detail = _detail!;
    final isWin = detail.isWin;
    final resultColor = isWin ? Colors.green : Colors.red;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              resultColor.withOpacity(0.8),
              resultColor,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(
              isWin ? Icons.emoji_events : Icons.sentiment_dissatisfied,
              size: 48,
              color: Colors.white,
            ),
            const SizedBox(height: 8),
            Text(
              isWin ? '勝利' : '敗北',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            // 降参・切断の場合は理由を表示
            if (detail.outcomeReason == 'surrender' || detail.outcomeReason == 'disconnect') ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  detail.outcomeReason == 'surrender'
                      ? (isWin ? '相手が降参' : 'あなたが降参')
                      : (isWin ? '相手が切断' : 'あなたが切断'),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              '${detail.playerScore} - ${detail.enemyScore}',
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'vs. ${detail.enemyName}',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildInfoChip(detail.matchType, Colors.white24),
                const SizedBox(width: 8),
                _buildInfoChip(detail.endedAt, Colors.white24),
              ],
            ),
            if (detail.rateAfterMatch != null || detail.rateAtEnd != null) ...[
              const SizedBox(height: 8),
              Column(
                children: [
                  if (detail.rateAtEnd != null)
                    Text(
                      'レート: ${detail.rateAtEnd}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  if (detail.rateAfterMatch != null)
                    Builder(builder: (context) {
                      final rate = detail.rateAfterMatch!;
                      return Text(
                        '(${rate >= 0 ? '+' : ''}$rate)',
                        style: TextStyle(
                          fontSize: 14,
                          color: rate >= 0 ? Colors.white : Colors.white70,
                        ),
                      );
                    }),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String text, Color backgroundColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildRoundCard(RoundDetail round) {
    // 降参・切断で未プレイのラウンド
    final isSurrendered = round.status == 'surrendered' || round.status == 'not_played';

    Color winnerColor;
    String winnerText;
    IconData winnerIcon;

    if (isSurrendered) {
      winnerColor = Colors.orange;
      winnerText = '未実施';
      winnerIcon = Icons.flag;
    } else {
      switch (round.roundWinner) {
        case 'player':
          winnerColor = Colors.green;
          winnerText = '勝ち';
          winnerIcon = Icons.check_circle;
          break;
        case 'enemy':
          winnerColor = Colors.red;
          winnerText = '負け';
          winnerIcon = Icons.cancel;
          break;
        default:
          winnerColor = Colors.grey;
          winnerText = '引き分け';
          winnerIcon = Icons.remove_circle;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: winnerColor.withOpacity(0.3)),
      ),
      child: ExpansionTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: winnerColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              'R${round.roundNumber}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: winnerColor,
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            Icon(winnerIcon, size: 20, color: winnerColor),
            const SizedBox(width: 8),
            Text(
              winnerText,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: winnerColor,
              ),
            ),
          ],
        ),
        subtitle: Text(
          round.questionFormat == 'listening' || round.questionFormat == 'LISTENING'
              ? 'リスニング'
              : '虫食い',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 問題文
                _buildDetailSection('問題', round.questionText),
                const SizedBox(height: 12),
                if (isSurrendered) ...[
                  // 降参・切断による未実施ラウンド
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          _detail!.outcomeReason == 'surrender'
                              ? '降参により未実施'
                              : '切断により未実施',
                          style: TextStyle(
                            color: Colors.orange[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (round.correctAnswer != null && round.correctAnswer!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildDetailSection('正解', round.correctAnswer!, valueColor: Colors.blue),
                  ],
                ] else ...[
                  // 通常のプレイ済みラウンド
                  _buildDetailSection(
                    '自分の回答',
                    round.playerAnswer.isEmpty ? '(未回答)' : round.playerAnswer,
                    valueColor: round.isPlayerCorrect ? Colors.green : Colors.red,
                    suffix: round.isPlayerCorrect ? ' ✓' : ' ✗',
                  ),
                  const SizedBox(height: 12),
                  _buildDetailSection(
                    '相手の回答',
                    round.enemyAnswer.isEmpty ? '(未回答)' : round.enemyAnswer,
                    valueColor: round.isEnemyCorrect ? Colors.green : Colors.red,
                    suffix: round.isEnemyCorrect ? ' ✓' : ' ✗',
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String label, String value, {Color? valueColor, String? suffix}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$value${suffix ?? ''}',
            style: TextStyle(
              fontSize: 14,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }
}
