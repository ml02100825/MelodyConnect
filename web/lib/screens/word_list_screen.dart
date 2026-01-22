import 'package:flutter/material.dart';
import '../../models/vocabulary_model.dart';
import '../services/vocabulary_api_service.dart';
import '../services/token_storage_service.dart';
import 'vocabulary_screen.dart';

class WordListScreen extends StatefulWidget {
  final int userId;
  final List<VocabularyCard>? vocabularies; // vocabulary_screenから渡される場合

  const WordListScreen({
    Key? key,
    required this.userId,
    this.vocabularies,
  }) : super(key: key);

  @override
  _WordListScreenState createState() => _WordListScreenState();
}

class _WordListScreenState extends State<WordListScreen> {
  final VocabularyApiService _apiService = VocabularyApiService();
  final TokenStorageService _tokenStorage = TokenStorageService();

  List<Word> words = [];
  List<Word> filteredWords = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _accessToken;

  // 検索条件
  String wordSearch = '';
  String pronunciationSearch = '';
  String partOfSpeechSearch = '';
  String? statusSearch;
  String meaningSearch = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // vocabulary_screenからデータが渡されている場合はそれを使用
    if (widget.vocabularies != null && widget.vocabularies!.isNotEmpty) {
      setState(() {
        words = widget.vocabularies!.map((vc) => Word(
          id: vc.userVocabId,
          word: vc.foreign,
          pronunciation: vc.pronunciation ?? '',
          partOfSpeech: vc.partOfSpeech ?? '',
          status: vc.isLearned ? '学習済み' : (vc.isFlagged ? 'お気に入り' : '未学習'),
          meanings: [vc.japanese],
          exampleSentence: vc.exampleSentence,
          exampleTranslation: vc.exampleTranslation,
          isFavorite: vc.isFlagged,
          isLearned: vc.isLearned,
        )).toList();
        filteredWords = List.from(words);
        _isLoading = false;
      });
      return;
    }

    // APIから取得
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      _accessToken = await _tokenStorage.getAccessToken();
      if (_accessToken == null) {
        setState(() {
          _errorMessage = 'ログインが必要です';
          _isLoading = false;
        });
        return;
      }

      final response = await _apiService.getUserVocabularies(widget.userId, _accessToken!);

      if (response.success) {
        setState(() {
          words = response.vocabularies.map((item) => Word.fromVocabularyItem(item)).toList();
          filteredWords = List.from(words);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response.message ?? '単語の取得に失敗しました';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'エラーが発生しました: $e';
        _isLoading = false;
      });
    }
  }

  void _searchWords() {
    setState(() {
      filteredWords = words.where((word) {
        bool matches = true;

        if (wordSearch.isNotEmpty && 
            !word.word.toLowerCase().contains(wordSearch.toLowerCase())) {
          matches = false;
        }
        if (pronunciationSearch.isNotEmpty && 
            !word.pronunciation.toLowerCase().contains(pronunciationSearch.toLowerCase())) {
          matches = false;
        }
        if (partOfSpeechSearch.isNotEmpty && 
            !word.partOfSpeech.toLowerCase().contains(partOfSpeechSearch.toLowerCase())) {
          matches = false;
        }
        if (statusSearch != null && statusSearch!.isNotEmpty && word.status != statusSearch) {
          matches = false;
        }
        if (meaningSearch.isNotEmpty) {
          bool meaningMatches = false;
          for (String meaning in word.meanings) {
            if (meaning.toLowerCase().contains(meaningSearch.toLowerCase())) {
              meaningMatches = true;
              break;
            }
          }
          if (!meaningMatches) {
            matches = false;
          }
        }

        return matches;
      }).toList();
    });
  }

  void _clearSearch() {
    setState(() {
      wordSearch = '';
      pronunciationSearch = '';
      partOfSpeechSearch = '';
      statusSearch = null;
      meaningSearch = '';
      filteredWords = List.from(words);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('単語一覧'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: '更新',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : Column(
                  children: [
                    // 検索条件エリア
                    _buildSearchArea(),

                    // 単語一覧
                    Expanded(
                      child: _buildWordList(),
                    ),
                  ],
                ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'エラーが発生しました',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('再読み込み'),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          // 1行目: 単語、発音
          Row(
            children: [
              Expanded(child: _buildSearchField('単語', (value) => wordSearch = value)),
              const SizedBox(width: 16),
              Expanded(child: _buildSearchField('発音', (value) => pronunciationSearch = value)),
            ],
          ),
          const SizedBox(height: 12),
          // 2行目: 品詞、状態
          Row(
            children: [
              Expanded(child: _buildSearchField('品詞', (value) => partOfSpeechSearch = value)),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDropdown(
                  '状態',
                  ['すべて', '学習済み', 'お気に入り', '未学習'],
                  (value) => statusSearch = value,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 3行目: 意味、ボタン
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildSearchField('日本語での意味', (value) => meaningSearch = value),
              ),
              const SizedBox(width: 16),
              OutlinedButton(
                onPressed: _clearSearch,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                child: const Text('クリア'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _searchWords,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('検索'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(String label, Function(String) onChanged) {
    return TextField(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        isDense: true,
      ),
      onChanged: onChanged,
    );
  }

  Widget _buildDropdown(String label, List<String> options, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      value: statusSearch,
      items: options.map((option) {
        return DropdownMenuItem(
          value: option == 'すべて' ? null : option,
          child: Text(option),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildWordList() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 件数表示
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Text(
                  '${filteredWords.length}件',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // テーブルヘッダー
          if (filteredWords.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  _buildTableHeader('単語', 2),
                  _buildTableHeader('発音', 2),
                  _buildTableHeader('品詞', 2),
                  _buildTableHeader('状態', 1),
                  _buildTableHeader('日本語での意味', 3),
                ],
              ),
            ),

          // テーブルデータ
          Expanded(
            child: filteredWords.isEmpty
                ? _buildNoWordsFound()
                : ListView.builder(
                    itemCount: filteredWords.length,
                    itemBuilder: (context, index) {
                      final word = filteredWords[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: word.isFavorite ? Colors.amber[50] : null,
                          border: Border(
                            left: BorderSide(color: Colors.grey[300]!),
                            right: BorderSide(color: Colors.grey[300]!),
                            bottom: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        child: InkWell(
                          onTap: () => _showWordDetail(word),
                          child: Row(
                            children: [
                              _buildTableCell(word.displayWord, 2, TextAlign.left),
                              _buildTableCell(word.pronunciation, 2, TextAlign.left),
                              _buildTableCell(word.partOfSpeech, 2, TextAlign.left),
                              _buildStatusCell(word.status, 1),
                              _buildTableCell(word.meanings.join(', '), 3, TextAlign.left),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoWordsFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '該当単語が見つかりません',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '検索条件を変更して再度お試しください',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(String text, int flex) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          border: Border(right: BorderSide(color: Colors.grey[300]!)),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildTableCell(String text, int flex, TextAlign align) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          border: Border(right: BorderSide(color: Colors.grey[300]!)),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.grey[700],
          ),
          textAlign: align,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildStatusCell(String status, int flex) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case '学習済み':
        bgColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
        break;
      case 'お気に入り':
        bgColor = Colors.amber[100]!;
        textColor = Colors.amber[800]!;
        break;
      default:
        bgColor = Colors.grey[100]!;
        textColor = Colors.grey[600]!;
    }

    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          border: Border(right: BorderSide(color: Colors.grey[300]!)),
        ),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 12,
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showWordDetail(Word word) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ハンドル
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 単語
                Text(
                  word.displayWord,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                // 発音
                if (word.pronunciation.isNotEmpty)
                  Text(
                    word.pronunciation,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),

                const SizedBox(height: 8),

                // 品詞・状態
                Wrap(
                  spacing: 8,
                  children: [
                    if (word.partOfSpeech.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          word.partOfSpeech,
                          style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: word.isLearned
                            ? Colors.green[50]
                            : (word.isFavorite ? Colors.amber[50] : Colors.grey[100]),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        word.status,
                        style: TextStyle(
                          fontSize: 12,
                          color: word.isLearned
                              ? Colors.green[700]
                              : (word.isFavorite ? Colors.amber[700] : Colors.grey[600]),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),

                // 意味
                const Text(
                  '意味',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                ...word.meanings.map((meaning) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '• $meaning',
                    style: const TextStyle(fontSize: 16),
                  ),
                )),

                // 例文
                if (word.exampleSentence != null && word.exampleSentence!.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Text(
                    '例文',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    word.exampleSentence!,
                    style: const TextStyle(fontSize: 16),
                  ),
                  if (word.exampleTranslation != null && word.exampleTranslation!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      word.exampleTranslation!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}