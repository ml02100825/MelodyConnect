import 'package:flutter/material.dart';
import '../bottom_nav.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({Key? key}) : super(key: key);

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();

  // 画像は簡易的にパス文字列で扱う（実運用では ImagePicker 等を使います）
  String? _attachedImage;

  bool _showConfirmation = false;

  void _attachImage() async {
    // スタブ: 実装では file picker を利用
    setState(() {
      _attachedImage = 'attached_image_placeholder';
    });
  }

  void _saveDraft() {
    // スタブ: 永続化は未実装
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('下書きを保存しました')));
  }

  void _send() {
    // 簡易バリデーション
    if (_titleController.text.trim().isEmpty || _bodyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('件名と本文を入力してください')));
      return;
    }

    // スタブ: ここで API 送信を行う
    setState(() {
      _showConfirmation = true;
    });
  }

  void _closeConfirmation() {
    setState(() {
      _showConfirmation = false;
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('お問い合わせ', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  const Divider(height: 1, thickness: 1),
                  const SizedBox(height: 12),

                  // 件名
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: '件名',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 本文
                  Expanded(
                    child: TextField(
                      controller: _bodyController,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: InputDecoration(
                        hintText: 'お問い合わせ内容を介せください',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // 画像添付エリア（簡易）
                  Row(
                    children: [
                      Expanded(child: Text('画像があれば貼ってください', style: TextStyle(color: Colors.grey[700]))),
                      IconButton(
                        onPressed: _attachImage,
                        icon: const Icon(Icons.image_outlined),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // 送信ボタン
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _send,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                          side: const BorderSide(color: Colors.black, width: 2),
                        ),
                        elevation: 4,
                      ),
                      child: const Text('送信', style: TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                  ),

                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _saveDraft,
                    child: const Text('下書き保存', style: TextStyle(color: Colors.blueAccent)),
                  ),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // 送信完了モーダル（中央）
          if (_showConfirmation)
            Center(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.8,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: GestureDetector(
                        onTap: _closeConfirmation,
                        child: Container(
                          decoration: BoxDecoration(color: Colors.grey[200], shape: BoxShape.circle),
                          child: const Icon(Icons.close, size: 20),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.blueAccent, width: 4)),
                      child: const Icon(Icons.check, color: Colors.blueAccent, size: 48),
                    ),
                    const SizedBox(height: 12),
                    const Text('お問い合わせを\n受け付けました', textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 4,
        onTap: (index) {},
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }
}
