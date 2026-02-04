import 'package:flutter/material.dart';
import 'bottom_admin.dart';
import 'mondai_edit_admin.dart';
import 'services/admin_api_service.dart';

class MondaiDetailPage extends StatefulWidget {
  final Map<String, dynamic> vocab;

  const MondaiDetailPage({Key? key, required this.vocab}) : super(key: key);

  @override
  State<MondaiDetailPage> createState() => _MondaiDetailPageState();
}

class _MondaiDetailPageState extends State<MondaiDetailPage> {
  late Map<String, dynamic> _question;
  late String status;
  bool _isUpdating = false;
  bool _isDeleting = false;
  bool _shouldRefresh = false;
  bool get _isDeleted => _question['isDeleted'] == true;

  @override
  void initState() {
    super.initState();
    _question = Map<String, dynamic>.from(widget.vocab);
    status = _question['status'] ?? '有効';
  }

  void toggleStatus() {
    _updateStatus();
  }

  int _resolveQuestionId() {
    final numericId = _question['numericId'];
    if (numericId is int) {
      return numericId;
    }
    return int.tryParse(_question['id']?.toString() ?? '') ?? 0;
  }

  Future<void> _updateStatus() async {
    if (_isUpdating) return;
    final questionId = _resolveQuestionId();
    if (questionId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('問題IDが不正です。')),
      );
      return;
    }

    final nextStatus = status == '有効' ? '無効' : '有効';
    setState(() {
      _isUpdating = true;
    });

    try {
      if (nextStatus == '有効') {
        await AdminApiService.enableQuestions([questionId]);
      } else {
        await AdminApiService.disableQuestions([questionId]);
      }
      if (!mounted) return;
      setState(() {
        status = nextStatus;
        _question['isActive'] = nextStatus == '有効';
        _question['status'] = nextStatus;
        _shouldRefresh = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('問題を$nextStatusに更新しました')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('問題の状態更新に失敗しました: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Future<void> _deleteQuestion() async {
    if (_isDeleting) return;
    final questionId = _resolveQuestionId();
    if (questionId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('問題IDが不正です。')),
      );
      return;
    }
    setState(() {
      _isDeleting = true;
    });
    try {
      if (_isDeleted) {
        await AdminApiService.restoreQuestion(questionId);
      } else {
        await AdminApiService.deleteQuestion(questionId);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isDeleted ? '問題の削除を解除しました' : '問題を削除しました')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('問題の削除に失敗しました: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('削除確認'),
        content: Text(_isDeleted ? '削除を解除しますか？' : '削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('いいえ'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteQuestion();
            },
            child: const Text('はい'),
          ),
        ],
      ),
    );
  }

  Future<void> _openEditPage() async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MondaiEditPage(question: _question),
      ),
    );
    if (updated != null && mounted) {
      setState(() {
        _question = Map<String, dynamic>.from(updated as Map);
        _shouldRefresh = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BottomAdminLayout(
        mainContent: _buildMainContent(),
        selectedMenu: 'コンテンツ管理',
        selectedTab: '問題',
        showTabs: false,
      ),
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '問題詳細',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: _openEditPage,
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  tooltip: 'Edit',
                ),
              ],
            ),
            const SizedBox(height: 32),

            Text(
              _question['question']?.toString().split('\n')[0] ?? '',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            _detailRow('ID', _question['id']),
            _detailRow('問題形式', _question['category']),
            _detailRow('問題', _question['question']),
            _detailRow('正答', _question['correctAnswer']),
            _detailRow('難易度', _question['difficulty']),
            _detailRow('楽曲名', _question['songName']),
            _detailRow('アーティスト', _question['artist']),
            _detailRow('追加日時', _question['addedDate']?.toString().split(' ')[0] ?? ''),
            _detailRow('リリース日', _question['releaseDate']?.toString().split(' ')[0] ?? ''),

            const SizedBox(height: 16),
            _detailRow('状態', status),

            const SizedBox(height: 40),

            Row(
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, _shouldRefresh ? true : null),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    elevation: 0,
                  ),
                  child: const Text('一覧へ戻る'),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _isUpdating ? null : toggleStatus,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: status == '有効' ? Colors.orange : Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    elevation: 0,
                  ),
                  child: Text(status == '有効' ? '問題無効化' : '問題有効化'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isDeleting ? null : _showDeleteDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    elevation: 0,
                  ),
                  child: Text(_isDeleted ? '問題削除解除' : '問題削除'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String title, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              '$title:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? '',
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }
}
