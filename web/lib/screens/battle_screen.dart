import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/token_storage_service.dart';

/// バトル画面
/// ランクマッチのバトルを行います
class BattleScreen extends StatefulWidget {
  final String matchId;

  const BattleScreen({Key? key, required this.matchId}) : super(key: key);

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen> {
  final _tokenStorage = TokenStorageService();
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _battleInfo;

  @override
  void initState() {
    super.initState();
    _loadBattleInfo();
  }

  /// バトル情報を取得
  Future<void> _loadBattleInfo() async {
    try {
      final token = await _tokenStorage.getAccessToken();
      if (token == null) {
        throw Exception('認証トークンが見つかりません');
      }

      final response = await http.get(
        Uri.parse('http://localhost:8080/api/battle/start/${widget.matchId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (!mounted) return;

        setState(() {
          _battleInfo = data;
          _isLoading = false;
        });
      } else {
        throw Exception('バトル情報の取得に失敗しました: ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // バトル中は戻るボタンを無効化
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('バトルを終了'),
            content: const Text('バトルを終了してもよろしいですか？\n（この機能は準備中です）'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('いいえ'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('はい'),
              ),
            ],
          ),
        );

        if (shouldExit == true) {
          if (mounted) {
            Navigator.popUntil(context, (route) => route.isFirst);
          }
        }
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Battle'),
          centerTitle: true,
          automaticallyImplyLeading: false,
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(strokeWidth: 6),
            SizedBox(height: 24),
            Text(
              'バトル情報を読み込み中...',
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 64,
              ),
              const SizedBox(height: 24),
              Text(
                'エラーが発生しました',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                child: const Text(
                  'ホームに戻る',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_battleInfo == null) {
      return const Center(
        child: Text('バトル情報が見つかりません'),
      );
    }

    return _buildBattleContent();
  }

  Widget _buildBattleContent() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // バトル準備中メッセージ
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue[200]!, width: 2),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.construction,
                    size: 64,
                    color: Colors.blue[700],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'バトル画面は準備中です',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'この機能は後ほど実装されます',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 48),

            // マッチ情報
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'マッチ情報',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  _buildInfoRow('Match ID', _battleInfo!['matchId'].toString()),
                  const SizedBox(height: 12),
                  _buildInfoRow('Your ID', _battleInfo!['user1Id'].toString()),
                  const SizedBox(height: 12),
                  _buildInfoRow('Opponent ID', _battleInfo!['user2Id'].toString()),
                  const SizedBox(height: 12),
                  _buildInfoRow('Language', _battleInfo!['language'].toString()),
                ],
              ),
            ),

            const SizedBox(height: 48),

            // ホームに戻るボタン
            ElevatedButton.icon(
              onPressed: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              icon: const Icon(Icons.home),
              label: const Text('ホームに戻る'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
