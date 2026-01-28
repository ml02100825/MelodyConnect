import 'package:flutter/material.dart';
import 'bottom_admin.dart';
import 'services/admin_api_service.dart';

class ContactDetailPage extends StatefulWidget {
  final Map<String, dynamic> contact;
  final Function(Map<String, dynamic>) onUpdate;

  const ContactDetailPage({
    Key? key,
    required this.contact,
    required this.onUpdate,
  }) : super(key: key);

  @override
  State<ContactDetailPage> createState() => _ContactDetailPageState();
}

class _ContactDetailPageState extends State<ContactDetailPage> {
  late String selectedStatus;
  late TextEditingController adminMemoController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    selectedStatus = widget.contact['status'] ?? '未対応';
    adminMemoController = TextEditingController(text: widget.contact['adminMemo'] ?? '');
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
      final contactId = widget.contact['numericId'] as int;
      await AdminApiService.updateContactStatus(
        contactId,
        selectedStatus,
        adminMemoController.text.isNotEmpty ? adminMemoController.text : null,
      );

      widget.contact['status'] = selectedStatus;
      widget.contact['adminMemo'] = adminMemoController.text;
      widget.onUpdate(widget.contact);

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
      final contactId = widget.contact['numericId'] as int;
      await AdminApiService.updateContactStatus(
        contactId,
        '完了',
        adminMemoController.text.isNotEmpty ? adminMemoController.text : null,
      );

      widget.contact['status'] = '完了';
      widget.contact['adminMemo'] = adminMemoController.text;
      widget.onUpdate(widget.contact);

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
            selectedTab: 'お問い合わせ',
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
    final receivedDate = widget.contact['receivedDate'] as DateTime;
    final dateStr = '${receivedDate.year}/${receivedDate.month.toString().padLeft(2, '0')}/${receivedDate.day.toString().padLeft(2, '0')} ${receivedDate.hour.toString().padLeft(2, '0')}:${receivedDate.minute.toString().padLeft(2, '0')}';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'お問い合わせ詳細',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),

            // 件名
            Text(
              '件名：${widget.contact['subject']}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // ユーザー情報
            Text(
              'ユーザー：${widget.contact['userName']}（${widget.contact['email']}）',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),

            // 受信日時
            Text(
              '受信日時：$dateStr',
              style: const TextStyle(fontSize: 16),
            ),
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

            // 本文
            const Text(
              '【本文】',
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
                widget.contact['content'] ?? '',
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
                  onPressed: _isLoading ? null : () {
                    // 返信処理（メール送信など）
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('返信機能は未実装です')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  ),
                  child: const Text('返信する'),
                ),
                const SizedBox(width: 12),
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
}
