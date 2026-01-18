import 'package:flutter/material.dart';
import '../models/history_models.dart';
import '../services/history_api_service.dart';
import '../services/token_storage_service.dart';

/// 学習履歴一覧画面
class LearningHistoryScreen extends StatefulWidget {
  final int? userId;

  const LearningHistoryScreen({
    super.key,
    this.userId,
  });

  @override
  State<LearningHistoryScreen> createState() => _LearningHistoryScreenState();
}

class _LearningHistoryScreenState extends State<LearningHistoryScreen> {
  final HistoryApiService _apiService = HistoryApiService();
  final TokenStorageService _tokenStorage = TokenStorageService();

  List<LearningHistoryItem> _history = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      int? userId = widget.userId;
      if (userId == null) {
        userId = await _tokenStorage.getUserId();
      }
      final token = await _tokenStorage.getAccessToken();

      if (userId == null || token == null) {
        setState(() {
          _errorMessage = '認証情報を取得できませんでした';
          _isLoading = false;
        });
        return;
      }

      final history = await _apiService.getLearningHistory(userId, token);
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
        title: const Text('学習履歴'),
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
            Icon(Icons.school, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '学習履歴がありません',
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

  Widget _buildHistoryCard(LearningHistoryItem item) {
    final accuracy = item.totalCount > 0
        ? (item.correctCount / item.totalCount * 100).round()
        : 0;

    Color accuracyColor;
    if (accuracy >= 80) {
      accuracyColor = Colors.green;
    } else if (accuracy >= 60) {
      accuracyColor = Colors.orange;
    } else {
      accuracyColor = Colors.red;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/learning-history/detail?historyId=${item.historyId}',
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 正解率サークル
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accuracyColor.withOpacity(0.1),
                  border: Border.all(color: accuracyColor, width: 3),
                ),
                child: Center(
                  child: Text(
                    '$accuracy%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: accuracyColor,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // 詳細情報
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.learningAt,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '正解: ${item.correctCount}/${item.totalCount}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              // 言語バッジ
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _getLanguageLabel(item.learningLang),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  String _getLanguageLabel(String lang) {
    switch (lang.toLowerCase()) {
      case 'en':
      case 'english':
        return '英語';
      case 'ja':
      case 'japanese':
        return '日本語';
      case 'ko':
      case 'korean':
        return '韓国語';
      default:
        return lang;
    }
  }
}
