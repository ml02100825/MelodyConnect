import 'package:flutter/material.dart';
import 'bottom_admin.dart';
import 'services/admin_api_service.dart';

class VocabularyEditPage extends StatefulWidget {
  final Map<String, dynamic> vocab;

  const VocabularyEditPage({Key? key, required this.vocab}) : super(key: key);

  @override
  State<VocabularyEditPage> createState() => _VocabularyEditPageState();
}

class _VocabularyEditPageState extends State<VocabularyEditPage> {
  late Map<String, dynamic> _vocab;
  bool _isSaving = false;

  late TextEditingController wordController;
  late TextEditingController pronunciationController;
  late TextEditingController partOfSpeechController;
  late TextEditingController meaningController;
  late TextEditingController translationController;
  late TextEditingController exampleSentenceController;
  late TextEditingController exampleTranslateController;
  late TextEditingController audioUrlController;
  late TextEditingController languageController;

  @override
  void initState() {
    super.initState();
    _vocab = Map<String, dynamic>.from(widget.vocab);
    wordController = TextEditingController(text: _stringValue('word'));
    pronunciationController = TextEditingController(text: _stringValue('pronunciation'));
    partOfSpeechController = TextEditingController(text: _stringValue('partOfSpeech'));
    meaningController = TextEditingController(text: _stringValue('meaning'));
    translationController = TextEditingController(text: _stringValue('translationJa'));
    exampleSentenceController = TextEditingController(text: _stringValue('exampleSentence'));
    exampleTranslateController = TextEditingController(text: _stringValue('exampleTranslation'));
    audioUrlController = TextEditingController(text: _stringValue('audioUrl'));
    languageController = TextEditingController(text: _stringValue('language'));
  }

  String _stringValue(String key) {
    final value = _vocab[key];
    return value == null ? '' : value.toString();
  }

  int _resolveVocabId() {
    final numericId = _vocab['numericId'];
    if (numericId is int) return numericId;
    return int.tryParse(_stringValue('id')) ?? 0;
  }

  Future<void> _saveChanges() async {
    final word = wordController.text.trim();
    final meaningJa = meaningController.text.trim();

    if (word.isEmpty || meaningJa.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Word and meaning are required.')),
      );
      return;
    }

    final vocabId = _resolveVocabId();
    if (vocabId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid vocabulary id.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final payload = {
      'word': word,
      'meaningJa': meaningJa,
      'translationJa': translationController.text.trim(),
      'pronunciation': pronunciationController.text.trim(),
      'partOfSpeech': partOfSpeechController.text.trim(),
      'exampleSentence': exampleSentenceController.text.trim(),
      'exampleTranslate': exampleTranslateController.text.trim(),
      'audioUrl': audioUrlController.text.trim(),
      'language': languageController.text.trim(),
      'isActive': _vocab['isActive'] ?? true,
    };

    try {
      await AdminApiService.updateVocabulary(vocabId, payload);
      _vocab = {
        ..._vocab,
        'word': word,
        'meaning': meaningJa,
        'translationJa': payload['translationJa'],
        'pronunciation': payload['pronunciation'],
        'partOfSpeech': payload['partOfSpeech'],
        'exampleSentence': payload['exampleSentence'],
        'exampleTranslation': payload['exampleTranslate'],
        'audioUrl': payload['audioUrl'],
        'language': payload['language'],
        'updatedAt': DateTime.now().toString(),
      };

      if (mounted) {
        Navigator.pop(context, _vocab);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update vocabulary: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    wordController.dispose();
    pronunciationController.dispose();
    partOfSpeechController.dispose();
    meaningController.dispose();
    translationController.dispose();
    exampleSentenceController.dispose();
    exampleTranslateController.dispose();
    audioUrlController.dispose();
    languageController.dispose();
    super.dispose();
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Vocabulary Edit',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Text('ID: ${_stringValue('id')}', style: const TextStyle(color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 24),
          _buildLabeledField('Word', wordController),
          const SizedBox(height: 16),
          _buildLabeledField('Pronunciation', pronunciationController),
          const SizedBox(height: 16),
          _buildLabeledField('Part of Speech', partOfSpeechController),
          const SizedBox(height: 16),
          _buildLabeledField('Meaning (JA)', meaningController),
          const SizedBox(height: 16),
          _buildLabeledField('Translation (JA)', translationController),
          const SizedBox(height: 16),
          _buildLabeledField('Example Sentence', exampleSentenceController, maxLines: 3),
          const SizedBox(height: 16),
          _buildLabeledField('Example Translation', exampleTranslateController, maxLines: 3),
          const SizedBox(height: 16),
          _buildLabeledField('Audio URL', audioUrlController),
          const SizedBox(height: 16),
          _buildLabeledField('Language', languageController),
          const SizedBox(height: 32),
          Row(
            children: [
              ElevatedButton(
                onPressed: _isSaving ? null : () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  elevation: 0,
                ),
                child: const Text('Cancel'),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  elevation: 0,
                ),
                child: Text(_isSaving ? 'Saving...' : 'Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLabeledField(String label, TextEditingController controller,
      {int maxLines = 1, bool enabled = true, String? helperText}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          enabled: enabled,
          decoration: InputDecoration(
            helperText: helperText,
            filled: true,
            fillColor: enabled ? Colors.white : Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: Colors.grey[400]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: Colors.grey[400]!),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }
}
