import 'package:flutter/material.dart';

class TourokuDialog extends StatefulWidget {
  final String type; // 'vocabulary', 'mondai', 'music', 'artist', 'genre', 'badge', etc.
  final Function(Map<String, dynamic>) onRegister;

  const TourokuDialog({
    Key? key,
    required this.type,
    required this.onRegister,
  }) : super(key: key);

  @override
  State<TourokuDialog> createState() => _TourokuDialogState();
}

class _TourokuDialogState extends State<TourokuDialog> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String?> _errors = {};

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    switch (widget.type) {
      case 'vocabulary':
        _controllers['word'] = TextEditingController();
        _controllers['meaning'] = TextEditingController();
        _controllers['pronunciation'] = TextEditingController();
        _controllers['partOfSpeech'] = TextEditingController();
        _controllers['exampleSentence'] = TextEditingController();
        _controllers['exampleTranslation'] = TextEditingController();
        break;
      case 'mondai':
        _controllers['question'] = TextEditingController();
        _controllers['correctAnswer'] = TextEditingController();
        _controllers['category'] = TextEditingController();
        _controllers['difficulty'] = TextEditingController();
        _controllers['songName'] = TextEditingController();
        _controllers['artist'] = TextEditingController();
        break;
      case 'music':
        _controllers['songName'] = TextEditingController();
        _controllers['artist'] = TextEditingController();
        _controllers['genre'] = TextEditingController();
        _controllers['language'] = TextEditingController();
        break;
      case 'artist':
        _controllers['name'] = TextEditingController();
        _controllers['genre'] = TextEditingController();
        _controllers['genreId'] = TextEditingController();
        _controllers['artistApiId'] = TextEditingController();
        _controllers['imageUrl'] = TextEditingController();
        break;
      case 'genre':
        _controllers['name'] = TextEditingController();
        break;
      case 'badge':
        _controllers['name'] = TextEditingController();
        _controllers['mode'] = TextEditingController(text: '1');
        _controllers['condition'] = TextEditingController();
        break;
    }
  }

  bool _validateForm() {
    _errors.clear();
    bool isValid = true;

    _controllers.forEach((key, controller) {
      if (controller.text.trim().isEmpty && !_isOptionalField(key)) {
        _errors[key] = 'この項目は必須です';
        isValid = false;
      }
    });

    setState(() {});
    return isValid;
  }

  bool _isOptionalField(String key) {
    // オプションのフィールドを定義
    final optionalFields = [
      'genreId', 'artistApiId', 'imageUrl',
      'partOfSpeech', 'exampleSentence', 'exampleTranslation'
    ];
    return optionalFields.contains(key);
  }

  void _submitForm() {
    if (_validateForm()) {
      final data = <String, dynamic>{};
      _controllers.forEach((key, controller) {
        data[key] = controller.text.trim();
      });
      data['status'] = '有効';
      data['addedDate'] = DateTime.now();

      widget.onRegister(data);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('登録が完了しました'),
          backgroundColor: Colors.green,
        ),
      );
      
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('入力内容を確認してください'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controllers.forEach((key, controller) {
      controller.dispose();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      backgroundColor: Colors.white,
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        padding: const EdgeInsets.all(32),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _getTitle(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: _buildFormFields(),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    ),
                    child: const Text('キャンセル', style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      elevation: 0,
                    ),
                    child: const Text('登録', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTitle() {
    switch (widget.type) {
      case 'vocabulary':
        return '単語を新規登録';
      case 'mondai':
        return '問題を新規登録';
      case 'music':
        return '楽曲を新規登録';
      case 'artist':
        return 'アーティストを新規登録';
      case 'genre':
        return 'ジャンルを新規登録';
      case 'badge':
        return 'バッジを新規登録';
      default:
        return '新規登録';
    }
  }

  List<Widget> _buildFormFields() {
    switch (widget.type) {
      case 'vocabulary':
        return [
          _buildTextField('単語', 'word', '例: hello'),
          const SizedBox(height: 16),
          _buildTextField('意味', 'meaning', '例: こんにちは'),
          const SizedBox(height: 16),
          _buildTextField('発音', 'pronunciation', '例: həˈloʊ'),
          const SizedBox(height: 16),
          _buildTextField('品詞', 'partOfSpeech', '例: 間投詞'),
          const SizedBox(height: 16),
          _buildTextField('例文', 'exampleSentence', '例: Hello, how are you?', maxLines: 3),
          const SizedBox(height: 16),
          _buildTextField('例文の訳', 'exampleTranslation', '例: こんにちは、お元気ですか？', maxLines: 3),
        ];
      case 'mondai':
        return [
          _buildTextField('問題文', 'question', '例: This is an _____.', maxLines: 3),
          const SizedBox(height: 16),
          _buildTextField('正答', 'correctAnswer', '例: example'),
          const SizedBox(height: 16),
          _buildTextField('問題形式', 'category', '例: 穴埋め'),
          const SizedBox(height: 16),
          _buildTextField('難易度', 'difficulty', '例: 初級'),
          const SizedBox(height: 16),
          _buildTextField('楽曲名', 'songName', '例: 楽曲01'),
          const SizedBox(height: 16),
          _buildTextField('アーティスト', 'artist', '例: アーティスト01'),
        ];
      case 'music':
        return [
          _buildTextField('楽曲名', 'songName', '例: 楽曲01'),
          const SizedBox(height: 16),
          _buildTextField('アーティスト', 'artist', '例: アーティスト01'),
          const SizedBox(height: 16),
          _buildTextField('ジャンル', 'genre', '例: ポップ'),
          const SizedBox(height: 16),
          _buildTextField('言語', 'language', '例: 英語'),
        ];
      case 'artist':
        return [
          _buildTextField('アーティスト名', 'name', '例: アーティスト01'),
          const SizedBox(height: 16),
          _buildTextField('ジャンル', 'genre', '例: ジャンル01'),
          const SizedBox(height: 16),
          _buildTextField('ジャンルID', 'genreId', '例: 00001（任意）'),
          const SizedBox(height: 16),
          _buildTextField('アーティストAPI ID', 'artistApiId', '例: API001（任意）'),
          const SizedBox(height: 16),
          _buildTextField('画像URL', 'imageUrl', '例: https://example.com/artist.png（任意）'),
        ];
      case 'genre':
        return [
          _buildTextField('ジャンル名', 'name', '例: ジャンル01'),
        ];
      case 'badge':
        return [
          _buildTextField('バッジ名', 'name', '例: バッジ01'),
          const SizedBox(height: 16),
          _buildDropdown('モード', 'mode', ['1', '2', '3', '4', '5']),
          const SizedBox(height: 16),
          _buildTextField('取得条件', 'condition', '例: 初めて勝利する'),
        ];
      default:
        return [];
    }
  }

  Widget _buildTextField(String label, String key, String hint, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            if (!_isOptionalField(key)) ...[
              const SizedBox(width: 4),
              const Text(
                '*',
                style: TextStyle(color: Colors.red, fontSize: 14),
              ),
            ]
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _controllers[key],
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
            errorText: _errors[key],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: Colors.grey[400]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: Colors.grey[400]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, String key, List<String> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 4),
            const Text(
              '*',
              style: TextStyle(color: Colors.red, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[400]!),
            borderRadius: BorderRadius.circular(4),
            color: Colors.white,
          ),
          child: DropdownButton<String>(
            value: _controllers[key]?.text,
            isExpanded: true,
            underline: const SizedBox(),
            items: options.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: Text(value),
                ),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _controllers[key]?.text = newValue ?? '';
                _errors.remove(key);
              });
            },
          ),
        ),
        if (_errors.containsKey(key))
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              _errors[key]!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }
}

// 使用例
void showTourokuDialog(BuildContext context, String type, Function(Map<String, dynamic>) onRegister) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return TourokuDialog(
        type: type,
        onRegister: onRegister,
      );
    },
  );
}
