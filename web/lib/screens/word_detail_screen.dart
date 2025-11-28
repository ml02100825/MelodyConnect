import 'package:flutter/material.dart';
import '../word_model.dart';

class WordDetailScreen extends StatefulWidget {
  final Word word;

  const WordDetailScreen({Key? key, required this.word}) : super(key: key);

  @override
  _WordDetailScreenState createState() => _WordDetailScreenState();
}

class _WordDetailScreenState extends State<WordDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Melody Connect'),
        backgroundColor: Colors.blue[700],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ナビゲーションメニュー
            _buildNavigationMenu(),
            SizedBox(height: 24),

            // 単語基本情報
            _buildWordHeader(),
            SizedBox(height: 24),

            // 単語詳細情報
            _buildWordDetails(),
            SizedBox(height: 32),

            // 操作ボタン
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationMenu() {
    return Row(
      children: [
        _buildNavItem('単語', isActive: true),
        _buildNavItem('問題'),
        _buildNavItem('楽曲'),
        _buildNavItem('アーティスト'),
        _buildNavItem('ジャンル'),
        _buildNavItem('バッジ'),
      ],
    );
  }

  Widget _buildNavItem(String title, {bool isActive = false}) {
    return Padding(
      padding: EdgeInsets.only(right: 24),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          color: isActive ? Colors.blue[700] : Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildWordHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '単語詳細',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text(
          widget.word.word,
          style: TextStyle(fontSize: 20, color: Colors.grey[600]),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '10',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            ),
            SizedBox(width: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '00001',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWordDetails() {
    return Column(
      children: [
        // 基本情報
        _buildInfoCard(
          '発音',
          [
            _buildInfoRow('品詞', widget.word.partOfSpeech),
            _buildInfoRow('日本語での意味', widget.word.meanings.join(', ')),
            _buildInfoRow('例文', 'This app allows you to learn English words.'),
            _buildInfoRow('例文の訳', 'このアプリでは英単語を学ぶことができます。'),
            _buildInfoRow('音声URL', 'xxxxxxxxxxxxxxxxxx'),
          ],
        ),
        SizedBox(height: 16),

        // 管理情報
        _buildInfoCard(
          '追加日時',
          [
            _buildInfoRow('更新日時', '2026/01/01'),
            _buildInfoRow('状態', widget.word.status),
            _buildInfoRow('', '有効'), // 状態の有効/無効
          ],
        ),
      ],
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('一覧へ戻る'),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              _toggleWordStatus();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.word.status == '公開' ? Colors.orange : Colors.green,
            ),
            child: Text(widget.word.status == '公開' ? '非公開にする' : '公開する'),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _showDeleteConfirmation,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('削除'),
          ),
        ),
      ],
    );
  }

  void _toggleWordStatus() {
    setState(() {
      // 状態を切り替える処理（実際にはAPI呼び出しなど）
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('単語の状態を変更しました')),
      );
    });
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('単語削除'),
        content: Text('本当にこの単語を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              _deleteWord();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('削除'),
          ),
        ],
      ),
    );
  }

  void _deleteWord() {
    // 単語削除処理（実際にはAPI呼び出しなど）
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('単語を削除しました')),
    );
    Navigator.pop(context);
  }
}