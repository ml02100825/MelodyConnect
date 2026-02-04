import 'package:flutter/material.dart';
import 'bottom_admin.dart';
import 'vocabulary_edit_admin.dart';
import 'services/admin_api_service.dart';

class VocabularyDetailPage extends StatefulWidget {
  final Map<String, dynamic> vocab;

  const VocabularyDetailPage({Key? key, required this.vocab}) : super(key: key);

  @override
  State<VocabularyDetailPage> createState() => _VocabularyDetailPageState();
}

class _VocabularyDetailPageState extends State<VocabularyDetailPage> {
  late Map<String, dynamic> _vocab;
  late String status;
  bool _isUpdating = false;
  bool _isDeleting = false;
  bool _shouldRefresh = false;
  bool get _isDeleted => _vocab['isDeleted'] == true;

  @override
  void initState() {
    super.initState();
    _vocab = Map<String, dynamic>.from(widget.vocab);
    status = (_vocab['status'] == '有効' || _vocab['status'] == 'enabled' || _vocab['status'] == true)
        ? '有効'
        : '無効';
  }

  void toggleStatus() {
    _updateStatus();
  }

  int _resolveVocabId() {
    final numericId = _vocab['numericId'];
    if (numericId is int) {
      return numericId;
    }
    return int.tryParse(_vocab['id']?.toString() ?? '') ?? 0;
  }

  Future<void> _updateStatus() async {
    if (_isUpdating) return;
    final vocabId = _resolveVocabId();
    if (vocabId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('単語IDが不正です。')),
      );
      return;
    }

    final nextStatus = status == '有効' ? '無効' : '有効';
    setState(() {
      _isUpdating = true;
    });

    try {
      if (nextStatus == '有効') {
        await AdminApiService.enableVocabularies([vocabId]);
      } else {
        await AdminApiService.disableVocabularies([vocabId]);
      }
      if (!mounted) return;
      setState(() {
        status = nextStatus;
        _vocab['isActive'] = nextStatus == '有効';
        _vocab['status'] = nextStatus;
        _shouldRefresh = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('単語を$nextStatusに更新しました')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('単語の状態更新に失敗しました: $e')),
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

  Future<void> _deleteVocabulary() async {
    if (_isDeleting) return;
    final vocabId = _resolveVocabId();
    if (vocabId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('単語IDが不正です。')),
      );
      return;
    }
    setState(() {
      _isDeleting = true;
    });
    try {
      if (_isDeleted) {
        await AdminApiService.restoreVocabulary(vocabId);
      } else {
        await AdminApiService.deleteVocabulary(vocabId);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isDeleted ? '単語の削除を解除しました' : '単語を削除しました')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('単語の削除に失敗しました: $e')),
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
              await _deleteVocabulary();
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
        builder: (context) => VocabularyEditPage(vocab: _vocab),
      ),
    );
    if (updated != null && mounted) {
      setState(() {
        _vocab = Map<String, dynamic>.from(updated as Map);
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
        selectedTab: '単語',
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
                  '単語詳細',
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
              _vocab['word'] ?? '',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            _detailRow('ID', _vocab['id']),
            _detailRow('発音', _vocab['pronunciation']),
            _detailRow('品詞', _vocab['partOfSpeech']),
            _detailRow('意味', _vocab['meaning']),
            _detailRow('例文', _vocab['exampleSentence']),
            _detailRow('例文の訳', _vocab['exampleTranslation']),
            _detailRow('音声URL', _vocab['audioUrl']),
            _detailRow('追加日時', _vocab['createdAt']),
            _detailRow('更新日時', _vocab['updatedAt']),

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
                  ),
                  child: Text(status == '有効' ? '単語無効化' : '単語有効化'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isDeleting ? null : _showDeleteDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  ),
                  child: Text(_isDeleted ? '単語削除解除' : '単語削除'),
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
