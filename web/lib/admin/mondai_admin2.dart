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
  bool _didUpdateStatus = false;

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
        _didUpdateStatus = true;
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
      await AdminApiService.deleteQuestion(questionId);
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('問題を削除しました')),
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
      builder: (BuildContext context) {
        return MondaiDeleteConfirmationDialog(
          question: _question,
          onDelete: () async {
            Navigator.pop(context);
            await _deleteQuestion();
          },
        );
      },
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
                  onPressed: () => Navigator.pop(context, _didUpdateStatus),
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
                  child: const Text('問題削除'),
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

class MondaiDeleteConfirmationDialog extends StatefulWidget {
  final Map<String, dynamic> question;
  final Future<void> Function() onDelete;

  const MondaiDeleteConfirmationDialog({
    Key? key,
    required this.question,
    required this.onDelete,
  }) : super(key: key);

  @override
  State<MondaiDeleteConfirmationDialog> createState() => _MondaiDeleteConfirmationDialogState();
}

class _MondaiDeleteConfirmationDialogState extends State<MondaiDeleteConfirmationDialog> {
  bool deleteId = false;
  bool deleteQuestion = false;
  bool deleteAnswer = false;
  bool deleteCategory = false;

  bool get canDelete => deleteId && deleteQuestion && deleteAnswer && deleteCategory;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      backgroundColor: Colors.white,
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.warning_rounded,
              color: Colors.red,
              size: 64,
            ),
            const SizedBox(height: 24),
            _buildCheckboxRow('ID', widget.question['id'], deleteId, (value) {
              setState(() {
                deleteId = value ?? false;
              });
            }),
            const SizedBox(height: 16),
            _buildCheckboxRow('問題', widget.question['question']?.toString().split('\n')[0] ?? '', deleteQuestion, (value) {
              setState(() {
                deleteQuestion = value ?? false;
              });
            }),
            const SizedBox(height: 16),
            _buildCheckboxRow('問題形式', widget.question['category'] ?? '', deleteCategory, (value) {
              setState(() {
                deleteCategory = value ?? false;
              });
            }),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: canDelete ? () async => widget.onDelete() : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: canDelete ? Colors.red : Colors.grey[300],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                elevation: 0,
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('問題を削除する', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[600],
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('キャンセル', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckboxRow(String label, String value, bool checked, Function(bool?) onChanged) {
    return Row(
      children: [
        Checkbox(
          value: checked,
          onChanged: onChanged,
          activeColor: Colors.blue,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            children: [
              SizedBox(
                width: 100,
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
