import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../bottom_nav.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({Key? key}) : super(key: key);

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  // 複数画像を保持するリスト
  List<XFile?> _attachedImages = [];

  bool _showConfirmation = false;

  Future<void> _attachImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _attachedImages.add(image);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('画像の選択に失敗しました: $e')),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _attachedImages.removeAt(index);
    });
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
                        hintText: 'お問い合わせ内容を入力してください',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // 画像添付エリア
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '画像があれば添付してください (${_attachedImages.length}枚)',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ),
                      // ギャラリーから選択
                      IconButton(
                        onPressed: _attachImage,
                        icon: const Icon(Icons.photo_library_outlined),
                        tooltip: 'ギャラリーから選択',
                      ),
                    ],
                  ),

                  // 添付画像のプレビュー
                  if (_attachedImages.isNotEmpty)
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _attachedImages.length,
                        itemBuilder: (context, index) {
                          return Stack(
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: FutureBuilder(
                                  future: _attachedImages[index]!.readAsBytes(),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData) {
                                      return ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.memory(
                                          snapshot.data!,
                                          fit: BoxFit.cover,
                                        ),
                                      );
                                    } else {
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    }
                                  },
                                ),
                              ),
                              // 削除ボタン
                              Positioned(
                                top: 4,
                                right: 12,
                                child: GestureDetector(
                                  onTap: () => _removeImage(index),
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 20,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 12),

                  // 送信ボタン
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _send,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        elevation: 4,
                      ),
                      child: const Text('送信', style: TextStyle(fontSize: 16, color: Colors.white)),
                    ),
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