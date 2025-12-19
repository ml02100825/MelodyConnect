import 'package:flutter/material.dart';
import 'bottom_admin.dart';

class VocabularyDetailPage extends StatefulWidget {
  final Map<String, dynamic> vocab;

  const VocabularyDetailPage({Key? key, required this.vocab}) : super(key: key);

  @override
  State<VocabularyDetailPage> createState() => _VocabularyDetailPageState();
}

class _VocabularyDetailPageState extends State<VocabularyDetailPage> {
  late String status;

  @override
  void initState() {
    super.initState();
    status = (widget.vocab['status'] == '有効' || widget.vocab['status'] == 'enabled' || widget.vocab['status'] == true)
        ? '有効'
        : '無効';
  }

  void toggleStatus() {
    setState(() {
      status = (status == '有効') ? '無効' : '有効';
    });
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return VocabularyDeleteConfirmationDialog(
          vocab: widget.vocab,
          onDelete: () {
            // 削除処理
            Navigator.pop(context); // ダイアログを閉じる
            Navigator.pop(context); // 詳細画面を閉じる
          },
        );
      },
    );
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
            const Text(
              '単語詳細',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),

            Text(
              widget.vocab['word'] ?? '',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            _detailRow('ID', widget.vocab['id']),
            _detailRow('発音', widget.vocab['pronunciation']),
            _detailRow('品詞', widget.vocab['partOfSpeech']),
            _detailRow('意味', widget.vocab['meaning']),
            _detailRow('例文', widget.vocab['exampleSentence']),
            _detailRow('例文の訳', widget.vocab['exampleTranslation']),
            _detailRow('音声URL', widget.vocab['audioUrl']),
            _detailRow('追加日時', widget.vocab['createdAt']),
            _detailRow('更新日時', widget.vocab['updatedAt']),

            const SizedBox(height: 16),
            _detailRow('状態', status),

            const SizedBox(height: 40),

            Row(
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  ),
                  child: const Text('一覧へ戻る'),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: toggleStatus,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: status == '有効' ? Colors.orange : Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  ),
                  child: Text(status == '有効' ? '単語無効化' : '単語有効化'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _showDeleteDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  ),
                  child: const Text('単語削除'),
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

class VocabularyDeleteConfirmationDialog extends StatefulWidget {
  final Map<String, dynamic> vocab;
  final VoidCallback onDelete;

  const VocabularyDeleteConfirmationDialog({
    Key? key,
    required this.vocab,
    required this.onDelete,
  }) : super(key: key);

  @override
  State<VocabularyDeleteConfirmationDialog> createState() => _VocabularyDeleteConfirmationDialogState();
}

class _VocabularyDeleteConfirmationDialogState extends State<VocabularyDeleteConfirmationDialog> {
  bool deleteId = false;
  bool deleteWord = false;
  bool deleteMeaning = false;
  bool deletePartOfSpeech = false;

  bool get canDelete => deleteId && deleteWord && deleteMeaning && deletePartOfSpeech;

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
            _buildCheckboxRow('ID', widget.vocab['id'], deleteId, (value) {
              setState(() {
                deleteId = value ?? false;
              });
            }),
            const SizedBox(height: 16),
            _buildCheckboxRow('単語', widget.vocab['word'] ?? '', deleteWord, (value) {
              setState(() {
                deleteWord = value ?? false;
              });
            }),
            const SizedBox(height: 16),
            _buildCheckboxRow('品詞', widget.vocab['partOfSpeech'] ?? '', deletePartOfSpeech, (value) {
              setState(() {
                deletePartOfSpeech = value ?? false;
              });
            }),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: canDelete ? widget.onDelete : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: canDelete ? Colors.red : Colors.grey[300],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                elevation: 0,
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('単語を削除する', style: TextStyle(fontSize: 16)),
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