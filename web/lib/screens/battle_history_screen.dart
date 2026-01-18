import 'package:flutter/material.dart';
import '../models/history_models.dart';
import '../services/history_api_service.dart';
import '../services/token_storage_service.dart';

/// 対戦履歴一覧画面
class BattleHistoryScreen extends StatefulWidget {
  const BattleHistoryScreen({super.key});

  @override
  State<BattleHistoryScreen> createState() => _BattleHistoryScreenState();
}

class _BattleHistoryScreenState extends State<BattleHistoryScreen> {
  final HistoryApiService _apiService = HistoryApiService();
  final TokenStorageService _tokenStorage = TokenStorageService();

  List<BattleHistoryItem> _history = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final userId = await _tokenStorage.getUserId();
      final token = await _tokenStorage.getAccessToken();

      if (userId == null || token == null) {
        setState(() {
          _errorMessage = '認証情報を取得できませんでした';
          _isLoading = false;
        });
        return;
      }

      final history = await _apiService.getBattleHistory(userId, token);
      setState(() {
        _history = history;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '履歴の取得に失敗しました: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('対戦履歴'),
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
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _loadHistory();
              },
              child: const Text('再読み込み'),
            ),
          ],
        ),
      );
    }

    if (_history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_esports, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '対戦履歴がありません',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _history.length,
        itemBuilder: (context, index) {
          return _buildHistoryCard(_history[index]);
        },
      ),
    );
  }

  Widget _buildHistoryCard(BattleHistoryItem item) {
    final isWin = item.isWin;
    final resultColor = isWin ? Colors.green : Colors.red;
    final resultIcon = isWin ? Icons.emoji_events : Icons.sentiment_dissatisfied;
    final resultText = isWin ? '勝利' : '敗北';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: resultColor.withOpacity(0.3)),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/battle-history/detail?resultId=${item.resultId}',
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 結果行
              Row(
                children: [
                  Icon(resultIcon, color: resultColor, size: 28),
                  const SizedBox(width: 8),
                  Text(
                    resultText,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: resultColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'vs. ${item.enemyName}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 詳細行
              Row(
                children: [
                  // スコア
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${item.playerScore}-${item.enemyScore}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // マッチタイプ
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: item.matchType == 'ランク'
                          ? Colors.amber[100]
                          : Colors.green[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.matchType,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: item.matchType == 'ランク'
                            ? Colors.amber[800]
                            : Colors.green[800],
                      ),
                    ),
                  ),
                  const Spacer(),
                  // 日時
                  Text(
                    item.endedAt,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              // レート情報（ランク戦のみ）
              if (item.rateAfterMatch != null || item.rateAtEnd != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (item.rateAtEnd != null)
                      Text(
                        'レート: ${item.rateAtEnd}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                    if (item.rateAfterMatch != null) ...[
                      if (item.rateAtEnd != null) const SizedBox(width: 8),
                      Builder(builder: (context) {
                        final rate = item.rateAfterMatch!;
                        return Text(
                          '(${rate >= 0 ? '+' : ''}$rate)',
                          style: TextStyle(
                            fontSize: 12,
                            color: rate >= 0 ? Colors.green[600] : Colors.red[600],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
