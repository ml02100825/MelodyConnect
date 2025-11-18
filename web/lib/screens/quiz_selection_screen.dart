import 'package:flutter/material.dart';
import '../models/quiz_models.dart';
import '../services/quiz_api_service.dart';
import '../services/token_storage_service.dart';
import 'quiz_question_screen.dart';

class QuizSelectionScreen extends StatefulWidget {
  const QuizSelectionScreen({super.key});

  @override
  State<QuizSelectionScreen> createState() => _QuizSelectionScreenState();
}

class _QuizSelectionScreenState extends State<QuizSelectionScreen> {
  final QuizApiService _apiService = QuizApiService();
  final TokenStorageService _tokenStorage = TokenStorageService();

  // ユーザーID
  int? _userId;

  // 選択状態
  String _selectedLanguage = 'en';
  String _selectedMode = 'COMPLETE_RANDOM';
  String _selectedFormat = 'ALL_RANDOM';
  int _questionCount = 10;

  // 追加入力
  String? _genreName;
  String? _songUrl;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final userId = await _tokenStorage.getUserId();
    setState(() {
      _userId = userId;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('学習設定'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 言語選択
            _buildSectionTitle('1. 学習言語を選択'),
            _buildLanguageSelector(),
            const SizedBox(height: 24),

            // 2. 問題生成方法
            _buildSectionTitle('2. 問題生成方法を選択'),
            _buildModeSelector(),
            const SizedBox(height: 24),

            // 3. 問題形式
            _buildSectionTitle('3. 問題形式を選択'),
            _buildFormatSelector(),
            const SizedBox(height: 24),

            // 4. 問題数
            _buildSectionTitle('4. 問題数を選択'),
            _buildQuestionCountSlider(),
            const SizedBox(height: 32),

            // 開始ボタン
            _buildStartButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.deepPurple,
        ),
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildOptionCard(
            title: '英語',
            subtitle: 'English',
            icon: Icons.language,
            isSelected: _selectedLanguage == 'en',
            onTap: () => setState(() => _selectedLanguage = 'en'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildOptionCard(
            title: '韓国語',
            subtitle: 'Korean',
            icon: Icons.language,
            isSelected: _selectedLanguage == 'ko',
            onTap: () => setState(() => _selectedLanguage = 'ko'),
          ),
        ),
      ],
    );
  }

  Widget _buildModeSelector() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildOptionCard(
                title: 'お気に入り',
                subtitle: 'アーティストから',
                icon: Icons.favorite,
                isSelected: _selectedMode == 'FAVORITE_ARTIST',
                onTap: () => setState(() => _selectedMode = 'FAVORITE_ARTIST'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildOptionCard(
                title: 'ジャンル',
                subtitle: '指定ジャンルから',
                icon: Icons.category,
                isSelected: _selectedMode == 'GENRE_RANDOM',
                onTap: () => setState(() => _selectedMode = 'GENRE_RANDOM'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildOptionCard(
                title: 'ランダム',
                subtitle: '完全ランダム',
                icon: Icons.shuffle,
                isSelected: _selectedMode == 'COMPLETE_RANDOM',
                onTap: () => setState(() => _selectedMode = 'COMPLETE_RANDOM'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildOptionCard(
                title: 'URL入力',
                subtitle: '曲を指定',
                icon: Icons.link,
                isSelected: _selectedMode == 'URL_INPUT',
                onTap: () => setState(() => _selectedMode = 'URL_INPUT'),
              ),
            ),
          ],
        ),
        // 追加入力フィールド
        if (_selectedMode == 'GENRE_RANDOM') ...[
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(
              labelText: 'ジャンル名',
              hintText: 'pop, rock, hiphop...',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => _genreName = value,
          ),
        ],
        if (_selectedMode == 'URL_INPUT') ...[
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(
              labelText: '曲のURL',
              hintText: 'https://...',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => _songUrl = value,
          ),
        ],
      ],
    );
  }

  Widget _buildFormatSelector() {
    return Column(
      children: [
        _buildOptionCard(
          title: 'すべてランダム',
          subtitle: 'リスニングと虫食いをランダムに出題',
          icon: Icons.shuffle,
          isSelected: _selectedFormat == 'ALL_RANDOM',
          onTap: () => setState(() => _selectedFormat = 'ALL_RANDOM'),
        ),
        const SizedBox(height: 12),
        _buildOptionCard(
          title: 'リスニングのみ',
          subtitle: '音声を聞いて回答',
          icon: Icons.headphones,
          isSelected: _selectedFormat == 'LISTENING_ONLY',
          onTap: () => setState(() => _selectedFormat = 'LISTENING_ONLY'),
        ),
        const SizedBox(height: 12),
        _buildOptionCard(
          title: '虫食いのみ',
          subtitle: '空欄を埋める問題',
          icon: Icons.edit,
          isSelected: _selectedFormat == 'FILL_IN_BLANK_ONLY',
          onTap: () => setState(() => _selectedFormat = 'FILL_IN_BLANK_ONLY'),
        ),
      ],
    );
  }

  Widget _buildQuestionCountSlider() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('問題数'),
            Text(
              '$_questionCount問',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
          ],
        ),
        Slider(
          value: _questionCount.toDouble(),
          min: 5,
          max: 30,
          divisions: 5,
          label: '$_questionCount問',
          activeColor: Colors.deepPurple,
          onChanged: (value) {
            setState(() => _questionCount = value.round());
          },
        ),
      ],
    );
  }

  Widget _buildOptionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepPurple.withOpacity(0.1) : Colors.white,
          border: Border.all(
            color: isSelected ? Colors.deepPurple : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.deepPurple : Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.deepPurple : Colors.black,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Colors.deepPurple,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _startQuiz,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                '学習を開始',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Future<void> _startQuiz() async {
    if (_userId == null) {
      _showError('ユーザー情報が取得できませんでした');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final request = QuizStartRequest(
        userId: _userId!,
        language: _selectedLanguage,
        generationMode: _selectedMode,
        questionFormat: _selectedFormat,
        questionCount: _questionCount,
        genreName: _genreName,
        songUrl: _songUrl,
      );

      final response = await _apiService.startQuiz(request);

      if (response.questions.isEmpty) {
        _showError('問題が見つかりませんでした');
        return;
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuizQuestionScreen(
              sessionId: response.sessionId!,
              userId: _userId!,
              questions: response.questions,
              songInfo: response.songInfo,
            ),
          ),
        );
      }
    } catch (e) {
      _showError('エラーが発生しました: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
