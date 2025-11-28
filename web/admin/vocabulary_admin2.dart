import 'package:flutter/material.dart';

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
    status = (widget.vocab['status'] == 'enabled' || widget.vocab['status'] == true)
        ? '有効'
        : '無効';
  }

  void toggleStatus() {
    setState(() {
      status = (status == '有効') ? '無効' : '有効';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
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
            const SizedBox(height: 32), // タイトルと単語の間隔を広げる

            Text(
              widget.vocab['word'] ?? '',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24), // 単語と詳細情報の間隔

            _detailRow('ID', widget.vocab['id']),
            _detailRow('発音', widget.vocab['pronunciation']),
            _detailRow('品詞', widget.vocab['partOfSpeech']),
            _detailRow('意味', widget.vocab['meaning']),
            _detailRow('例文', widget.vocab['exampleSentence']),
            _detailRow('例文の訳', widget.vocab['exampleTranslation']),
            _detailRow('音声URL', widget.vocab['audioUrl']),
            _detailRow('追加日時', widget.vocab['createdAt']),
            _detailRow('更新日時', widget.vocab['updatedAt']),

            // 状態表示
            const SizedBox(height: 16),
            _detailRow('状態', status),

            const Spacer(),

            Row(
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('一覧へ戻る'),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: toggleStatus,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('単語無効化'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
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

  // ラベルと値の間隔を150に拡大
  Widget _detailRow(String title, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16), // 縦間隔も広げる
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150, // ラベルと値の距離を広く
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
