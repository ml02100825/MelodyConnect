import 'package:flutter/material.dart';
import 'bottom_admin.dart';

// クラス名を維持しつつ、VocabularyAdminと互換性を持たせる
class VocabularyDetailAdmin extends StatefulWidget {
  final Map<String, dynamic> vocab;  // パラメータ名を vocab に統一
  final Function(Map<String, dynamic>, String)? onStatusChanged;

  const VocabularyDetailAdmin({
    Key? key,
    required this.vocab,
    this.onStatusChanged,
  }) : super(key: key);

  @override
  _VocabularyDetailAdminState createState() => _VocabularyDetailAdminState();
}

class _VocabularyDetailAdminState extends State<VocabularyDetailAdmin> {
  final Map<String, TextEditingController> _controllers = {};
  bool _isEditing = false;
  
  // 削除確認用チェックボックスの状態（ダイアログ用）
  bool wordChecked = false;
  bool idChecked = false;
  bool partOfSpeechChecked = false;
  
  // 現在の状態をコピーして保持
  late Map<String, dynamic> _currentVocab;
  
  @override
  void initState() {
    super.initState();
    // 元データのコピーを作成
    _currentVocab = Map.from(widget.vocab);
    
    // VocabularyAdmin のデータ構造に合わせて調整
    _currentVocab['example'] ??= _currentVocab['exampleSentence'] ?? '';
    _currentVocab['translation'] ??= _currentVocab['exampleTranslation'] ?? '';
    _currentVocab['audioUrl'] ??= '';
    _currentVocab['status'] ??= '有効';
    _currentVocab['createdAt'] ??= '不明';
    _currentVocab['updatedAt'] ??= '不明';
    
    // コントローラーを初期化
    _controllers['word'] = TextEditingController(text: _currentVocab['word'] ?? '');
    _controllers['pronunciation'] = TextEditingController(text: _currentVocab['pronunciation'] ?? '');
    _controllers['partOfSpeech'] = TextEditingController(text: _currentVocab['partOfSpeech'] ?? '');
    _controllers['meaning'] = TextEditingController(text: _currentVocab['meaning'] ?? '');
    _controllers['example'] = TextEditingController(text: _currentVocab['example'] ?? '');
    _controllers['translation'] = TextEditingController(text: _currentVocab['translation'] ?? '');
    _controllers['audioUrl'] = TextEditingController(text: _currentVocab['audioUrl'] ?? '');
  }

  @override
  void dispose() {
    // コントローラーを破棄
    _controllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  void _saveChanges() {
    // 変更を保存
    setState(() {
      // コントローラーの値でデータを更新
      _currentVocab['word'] = _controllers['word']!.text;
      _currentVocab['pronunciation'] = _controllers['pronunciation']!.text;
      _currentVocab['partOfSpeech'] = _controllers['partOfSpeech']!.text;
      _currentVocab['meaning'] = _controllers['meaning']!.text;
      _currentVocab['example'] = _controllers['example']!.text;
      _currentVocab['exampleSentence'] = _controllers['example']!.text; // 元のフィールドにも保存
      _currentVocab['translation'] = _controllers['translation']!.text;
      _currentVocab['exampleTranslation'] = _controllers['translation']!.text; // 元のフィールドにも保存
      _currentVocab['audioUrl'] = _controllers['audioUrl']!.text;
      
      // 更新日時を更新
      final now = DateTime.now();
      _currentVocab['updatedAt'] = '${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
      
      _isEditing = false;
    });
    
    // 変更を親に通知
    if (widget.onStatusChanged != null) {
      widget.onStatusChanged!(_currentVocab, 'updated');
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('変更を保存しました')),
    );
  }

  void _cancelEdit() {
    setState(() {
      // 元の値に戻す
      _controllers['word']!.text = widget.vocab['word'];
      _controllers['pronunciation']!.text = widget.vocab['pronunciation'];
      _controllers['partOfSpeech']!.text = widget.vocab['partOfSpeech'];
      _controllers['meaning']!.text = widget.vocab['meaning'];
      _controllers['example']!.text = widget.vocab['exampleSentence'] ?? '';
      _controllers['translation']!.text = widget.vocab['exampleTranslation'] ?? '';
      _controllers['audioUrl']!.text = widget.vocab['audioUrl'] ?? '';
      _isEditing = false;
    });
  }

  Widget _buildAudioSection() {
    final audioUrl = _currentVocab['audioUrl'] ?? '';
    final displayUrl = audioUrl.isNotEmpty ? _maskAudioUrl(audioUrl) : '音声ファイルなし';
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '音声再生',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                IconButton(
                  onPressed: audioUrl.isNotEmpty ? () {
                    _playAudio(audioUrl);
                  } : null,
                  icon: Icon(
                    Icons.play_arrow,
                    size: 40,
                    color: audioUrl.isNotEmpty ? Colors.blue : Colors.grey,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ファイル: $displayUrl',
                        style: TextStyle(
                          color: audioUrl.isNotEmpty ? Colors.grey[600] : Colors.grey[400],
                          fontStyle: audioUrl.isEmpty ? FontStyle.italic : FontStyle.normal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (_isEditing)
                        ElevatedButton(
                          onPressed: () {
                            _changeAudioFile();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[50],
                            foregroundColor: Colors.blue,
                          ),
                          child: const Text('音声ファイルを変更'),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _maskAudioUrl(String url) {
    if (url.length <= 20) return url;
    return '${url.substring(0, 10)}...${url.substring(url.length - 10)}';
  }

  void _playAudio(String url) {
    // 音声再生処理を実装
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('音声を再生: ${_maskAudioUrl(url)}')),
    );
  }

  void _changeAudioFile() {
    final controller = TextEditingController(text: _currentVocab['audioUrl']);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('音声ファイルを変更'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: '音声URL',
                hintText: 'https://example.com/audio.mp3',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // ファイル選択処理
              },
              child: const Text('ファイルを選択'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _currentVocab['audioUrl'] = controller.text;
                _controllers['audioUrl']!.text = controller.text;
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('音声URLを更新しました')),
              );
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _isEditing && enabled
                ? TextField(
                    controller: controller,
                    maxLines: maxLines,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
                    child: Text(
                      controller.text.isNotEmpty ? controller.text : '(未設定)',
                      style: TextStyle(
                        fontSize: 16,
                        color: controller.text.isNotEmpty ? Colors.black : Colors.grey[400],
                        fontStyle: controller.text.isEmpty ? FontStyle.italic : FontStyle.normal,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNonEditableField({
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
              child: Text(
                value,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: BottomAdminLayout(
        selectedMenu: 'コンテンツ管理',  // 適切なメニュー名に変更
        onMenuSelected: (menu) {
          // メニュー選択時の処理（必要に応じて実装）
        },
        selectedTab: '単語',
        onTabSelected: (tab) {
          // タブ選択時の処理（必要に応じて実装）
        },
        showTabs: false,
        mainContent: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // タイトルと編集ボタン
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '単語詳細',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${_currentVocab['id']}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          _isEditing ? Icons.save : Icons.edit,
                          size: 24,
                        ),
                        onPressed: _isEditing ? _saveChanges : _toggleEditMode,
                        tooltip: _isEditing ? '保存' : '編集',
                        color: Colors.blue,
                      ),
                      if (_isEditing)
                        IconButton(
                          icon: const Icon(Icons.cancel, size: 24),
                          onPressed: _cancelEdit,
                          tooltip: 'キャンセル',
                          color: Colors.grey[600],
                        ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // 音声再生セクション
              _buildAudioSection(),
              
              const SizedBox(height: 24),
              
              // 単語フィールド
              _buildEditableField(
                label: '単語',
                controller: _controllers['word']!,
              ),
              
              // IDフィールド（編集不可）
              _buildNonEditableField(
                label: 'ID',
                value: _currentVocab['id'] ?? '',
              ),
              
              // 発音フィールド
              _buildEditableField(
                label: '発音',
                controller: _controllers['pronunciation']!,
              ),
              
              // 品詞フィールド
              _buildEditableField(
                label: '品詞',
                controller: _controllers['partOfSpeech']!,
              ),
              
              // 日本語での意味フィールド
              _buildEditableField(
                label: '日本語での意味',
                controller: _controllers['meaning']!,
                maxLines: 3,
              ),
              
              // 例文フィールド
              _buildEditableField(
                label: '例文',
                controller: _controllers['example']!,
                maxLines: 2,
              ),
              
              // 例文の訳フィールド
              _buildEditableField(
                label: '例文の訳',
                controller: _controllers['translation']!,
                maxLines: 2,
              ),
              
              // 音声URLフィールド
              _buildEditableField(
                label: '音声URL',
                controller: _controllers['audioUrl']!,
              ),
              
              // 追加日時フィールド（編集不可）
              _buildNonEditableField(
                label: '追加日時',
                value: _currentVocab['createdAt'] ?? '不明',
              ),
              
              // 更新日時フィールド（編集不可）
              _buildNonEditableField(
                label: '更新日時',
                value: _currentVocab['updatedAt'] ?? '不明',
              ),
              
              // 状態フィールド
              _buildNonEditableField(
                label: '状態',
                value: _currentVocab['status'] ?? '不明',
              ),
              
              const SizedBox(height: 32),
              
              // 操作ボタン
              Row(
                children: [
                  // 左端：一覧へ戻る
                  OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    child: Text('一覧へ戻る', style: TextStyle(color: Colors.white)),
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          onPressed: _toggleStatus,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _currentVocab['status'] == '有効' ? Colors.orange : Colors.green,
                            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            _currentVocab['status'] == '有効' ? '単語無効化' : '単語有効化',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        SizedBox(width: 16),
                        // 削除ボタン
                        ElevatedButton(
                          onPressed:  _showDeleteConfirmation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                            elevation: 0,
                          ),
                          child: const Text('単語削除', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleStatus() {
    setState(() {
      final newStatus = _currentVocab['status'] == '有効' ? '無効' : '有効';
      _currentVocab['status'] = newStatus;
      _currentVocab['isActive'] = newStatus == '有効';
    });
    
    // 状態変更を親に通知
    if (widget.onStatusChanged != null) {
      widget.onStatusChanged!(_currentVocab, 'status_changed');
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('状態を${_currentVocab['status']}に変更しました')),
    );
  }

  // 削除確認ダイアログ（チェックボックス付き）
  void _showDeleteConfirmation() {
    // ダイアログ表示前に状態をリセット
    wordChecked = false;
    idChecked = false;
    partOfSpeechChecked = false;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // 修正: すべてのチェックボックスがチェックされているか確認
          final allChecked = wordChecked && 
                            idChecked && 
                            partOfSpeechChecked;
          
          return AlertDialog(
            title: Container(
              alignment: Alignment.center,
              child: const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 100,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '削除確認',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '以下の項目をすべてチェックして、削除を確認してください:',
                    style: TextStyle(
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Column(
                    children: [
                      CheckboxListTile(
                        title: Text(
                          'ID: ${_currentVocab['id']}',
                          style: const TextStyle(fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                        value: idChecked,
                        onChanged: (value) => setDialogState(() => idChecked = value ?? false),
                        controlAffinity: ListTileControlAffinity.leading,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      CheckboxListTile(
                        title: Text(
                          '単語: ${_controllers['word']!.text}',
                          style: const TextStyle(fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                        value: wordChecked,
                        onChanged: (value) => setDialogState(() => wordChecked = value ?? false),
                        controlAffinity: ListTileControlAffinity.leading,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      CheckboxListTile(
                        title: Text(
                          '品詞: ${_controllers['partOfSpeech']!.text}',
                          style: const TextStyle(fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                        value: partOfSpeechChecked,
                        onChanged: (value) => setDialogState(() => partOfSpeechChecked = value ?? false),
                        controlAffinity: ListTileControlAffinity.leading,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: allChecked
                        ? () {
                            _deleteWord();
                            Navigator.pop(context);
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('単語を削除する', style: TextStyle(color: Colors.white)),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: TextButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text('キャンセル', style: TextStyle(color: Colors.grey)),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDeleteCheckbox(String label, bool value, Function(bool?) onChanged) {
    return CheckboxListTile(
      title: Text(
        label,
        style: const TextStyle(fontSize: 14),
        overflow: TextOverflow.ellipsis,
        maxLines: 2,
      ),
      value: value,
      onChanged: onChanged,
      controlAffinity: ListTileControlAffinity.leading,
      dense: true,
      contentPadding: EdgeInsets.zero,
    );
  }

  void _deleteWord() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('単語を削除しました')),
    );
    
    // 削除結果を返して前の画面に戻る
    Navigator.pop(context, {'action': 'delete', 'vocab': _currentVocab});
  }
}