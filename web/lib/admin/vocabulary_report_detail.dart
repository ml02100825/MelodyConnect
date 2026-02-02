import 'package:flutter/material.dart';
import 'bottom_admin.dart';
import 'services/admin_api_service.dart';

class VocabularyReportDetailPage extends StatefulWidget {
  final Map<String, dynamic> report;
  final Function(Map<String, dynamic>) onUpdate;

  const VocabularyReportDetailPage({
    Key? key,
    required this.report,
    required this.onUpdate,
  }) : super(key: key);

  @override
  State<VocabularyReportDetailPage> createState() => _VocabularyReportDetailPageState();
}

class _VocabularyReportDetailPageState extends State<VocabularyReportDetailPage> {
  late String selectedStatus;
  late TextEditingController adminMemoController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    selectedStatus = widget.report['status'] ?? '未対応';
    adminMemoController = TextEditingController(text: widget.report['adminMemo'] ?? '');
  }

  @override
  void dispose() {
    adminMemoController.dispose();
    super.dispose();
  }

  Future<void> _saveAndReturn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final reportId = widget.report['numericId'] as int;
      await AdminApiService.updateVocabularyReportStatus(
        reportId,
        selectedStatus,
        adminMemoController.text.isNotEmpty ? adminMemoController.text : null,
      );

      widget.report['status'] = selectedStatus;
      widget.report['adminMemo'] = adminMemoController.text;
      widget.onUpdate(widget.report);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新に失敗しました: $e')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _completeAndReturn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final reportId = widget.report['numericId'] as int;
      await AdminApiService.updateVocabularyReportStatus(
        reportId,
        '完了',
        adminMemoController.text.isNotEmpty ? adminMemoController.text : null,
      );

      widget.report['status'] = '完了';
      widget.report['adminMemo'] = adminMemoController.text;
      widget.onUpdate(widget.report);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ステータスを「完了」に変更しました')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新に失敗しました: $e')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          BottomAdminLayout(
            mainContent: _buildMainContent(),
            selectedMenu: 'お問い合わせ管理',
            selectedTab: '単語報告',
            showTabs: false,
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    final addedAt = widget.report['addedAt'] as DateTime;
    final dateStr = '${addedAt.year}/${addedAt.month.toString().padLeft(2, '0')}/${addedAt.day.toString().padLeft(2, '0')} ${addedAt.hour.toString().padLeft(2, '0')}:${addedAt.minute.toString().padLeft(2, '0')}';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '単語報告詳細',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),

            // 報告ID
            _buildInfoRow('報告ID', widget.report['id']?.toString() ?? ''),
            const SizedBox(height: 16),

            // 単語ID
            _buildInfoRow('単語ID', widget.report['vocabularyId']?.toString() ?? ''),
            const SizedBox(height: 16),

            // 単語
            _buildInfoRow('単語', widget.report['word'] ?? ''),
            const SizedBox(height: 16),

            // 意味
            _buildInfoRow('意味', widget.report['meaningJa'] ?? ''),
            const SizedBox(height: 16),

            // ユーザーID
            _buildInfoRow('ユーザーID', widget.report['userId']?.toString() ?? ''),
            const SizedBox(height: 16),

            // ユーザーメール
            _buildInfoRow('報告者', widget.report['userEmail'] ?? ''),
            const SizedBox(height: 16),

            // 報告日時
            _buildInfoRow('報告日時', dateStr),
            const SizedBox(height: 16),

            // ステータス選択
            Row(
              children: [
                const Text(
                  'ステータス：',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[400]!),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: DropdownButton<String>(
                    value: selectedStatus,
                    underline: const SizedBox(),
                    items: ['未対応', '対応中', '完了'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          selectedStatus = newValue;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 報告内容
            const Text(
              '【報告内容】',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(4),
                color: Colors.grey[50],
              ),
              child: Text(
                widget.report['reportContent'] ?? '',
                style: const TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(height: 24),

            // 管理者メモ
            const Text(
              '【管理者メモ】',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: adminMemoController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: '管理者だけが見られるメモ欄',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),

            const SizedBox(height: 40),

            // ボタン
            Row(
              children: [
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveAndReturn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  ),
                  child: const Text('保存して戻る'),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _isLoading ? null : _completeAndReturn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  ),
                  child: const Text('完了にする'),
                ),
              ],
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
            '$label：',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }
}
