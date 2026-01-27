import 'package:flutter/material.dart';
import 'bottom_admin.dart';
import 'services/admin_api_service.dart';

class MondaiEditPage extends StatefulWidget {
  final Map<String, dynamic> question;

  const MondaiEditPage({Key? key, required this.question}) : super(key: key);

  @override
  State<MondaiEditPage> createState() => _MondaiEditPageState();
}

class _MondaiEditPageState extends State<MondaiEditPage> {
  late Map<String, dynamic> _question;
  bool _isSaving = false;

  late TextEditingController textController;
  late TextEditingController answerController;
  late TextEditingController difficultyController;
  late TextEditingController translationController;
  late TextEditingController audioUrlController;

  @override
  void initState() {
    super.initState();
    _question = Map<String, dynamic>.from(widget.question);
    textController = TextEditingController(text: _stringValue('question'));
    answerController = TextEditingController(text: _stringValue('correctAnswer'));
    difficultyController = TextEditingController(text: _stringValue('difficulty'));
    translationController = TextEditingController(text: _stringValue('translationJa'));
    audioUrlController = TextEditingController(text: _stringValue('audioUrl'));
  }

  String _stringValue(String key) {
    final value = _question[key];
    return value == null ? '' : value.toString();
  }

  int _resolveQuestionId() {
    final numericId = _question['numericId'];
    if (numericId is int) return numericId;
    return int.tryParse(_stringValue('id')) ?? 0;
  }

  bool get _isFillInBlank {
    final format = _question['questionFormat']?.toString();
    return format == 'FILL_IN_THE_BLANK' || format == 'FILL_IN_BLANK';
  }

  Future<void> _saveChanges() async {
    final text = textController.text.trim();
    final answer = answerController.text.trim();

    if (text.isEmpty || answer.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Question text and answer are required.')),
      );
      return;
    }

    final questionId = _resolveQuestionId();
    if (questionId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid question id.')),
      );
      return;
    }

    final songId = _question['songId'];
    final artistId = _question['artistId'];
    if (songId == null || artistId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Song ID and Artist ID are required.')),
      );
      return;
    }

    final difficulty = int.tryParse(difficultyController.text.trim());

    setState(() {
      _isSaving = true;
    });

    final payload = {
      'songId': songId,
      'artistId': artistId,
      'text': text,
      'answer': answer,
      'questionFormat': _question['questionFormat'],
      'difficultyLevel': difficulty,
      'translationJa': translationController.text.trim(),
      'audioUrl': _isFillInBlank ? _question['audioUrl'] ?? '' : audioUrlController.text.trim(),
      'isActive': _question['isActive'] ?? true,
    };

    try {
      await AdminApiService.updateQuestion(questionId, payload);
      _question = {
        ..._question,
        'question': text,
        'correctAnswer': answer,
        'difficulty': difficulty ?? _question['difficulty'],
        'translationJa': payload['translationJa'],
        'audioUrl': payload['audioUrl'],
      };

      if (mounted) {
        Navigator.pop(context, _question);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update question: $e')),
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
    textController.dispose();
    answerController.dispose();
    difficultyController.dispose();
    translationController.dispose();
    audioUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BottomAdminLayout(
        mainContent: _buildMainContent(),
        selectedMenu: 'コンテンツ管理',
        selectedTab: '問題',
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
                'Question Edit',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Text('ID: ${_stringValue('id')}', style: const TextStyle(color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 24),
          _buildLabeledField('Question Text', textController, maxLines: 3),
          const SizedBox(height: 16),
          _buildLabeledField('Answer', answerController),
          const SizedBox(height: 16),
          _buildLabeledField('Difficulty Level', difficultyController),
          const SizedBox(height: 16),
          _buildLabeledField('Translation (JA)', translationController),
          const SizedBox(height: 16),
          _buildLabeledField(
            'Audio URL',
            audioUrlController,
            enabled: !_isFillInBlank,
            helperText: _isFillInBlank ? 'Disabled for FILL_IN_THE_BLANK.' : null,
          ),
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
