import 'package:flutter/material.dart';
import '../word_model.dart';
import 'word_detail_screen.dart';

class WordListScreen extends StatefulWidget {
  @override
  _WordListScreenState createState() => _WordListScreenState();
}

class _WordListScreenState extends State<WordListScreen> {
  List<Word> words = [];
  List<Word> filteredWords = [];

  // 検索条件
  String wordSearch = '';
  String pronunciationSearch = '';
  String partOfSpeechSearch = '';
  String? statusSearch = '';
  String meaningSearch = '';

  @override
  void initState() {
    super.initState();
    _loadSampleData();
  }

  void _loadSampleData() {
    words = [
      Word(
        word: 'word',
        pronunciation: 'wárd',
        partOfSpeech: '(名詞) 加算名詞',
        status: '公開',
        meanings: ['語、単語、(口で言う)言葉、話、試話、言葉、口論、指図、命令、標語'],
      ),
      Word(
        word: 'word',
        pronunciation: 'wárd',
        partOfSpeech: '(名詞) 不可算名詞',
        status: '公開',
        meanings: ['知らせ、使う、消息、伝言'],
      ),
      Word(
        word: 'word',
        pronunciation: 'wárd',
        partOfSpeech: '(動詞) 他動詞',
        status: '非公開',
        meanings: ['[虚例]用形を伴って「〈…を〉言葉で……」言い表わす'],
      ),
      Word(
        word: 'example',
        pronunciation: 'tgizompal',
        partOfSpeech: '(名詞) 加算名詞',
        status: '公開',
        meanings: ['例、英例、手本、収穫、前例、元例、見せしめ、戒め'],
      ),
    ];
    filteredWords = List.from(words);
  }

  void _searchWords() {
    setState(() {
      filteredWords = words.where((word) {
        bool matches = true;

        if (wordSearch.isNotEmpty && !word.word.contains(wordSearch)) {
          matches = false;
        }
        if (pronunciationSearch.isNotEmpty && !word.pronunciation.contains(pronunciationSearch)) {
          matches = false;
        }
        if (partOfSpeechSearch.isNotEmpty && !word.partOfSpeech.contains(partOfSpeechSearch)) {
          matches = false;
        }
        if (statusSearch != null && statusSearch != '全て' && word.status != statusSearch) {
          matches = false;
        }
        if (meaningSearch.isNotEmpty) {
          bool meaningMatches = false;
          for (String meaning in word.meanings) {
            if (meaning.contains(meaningSearch)) {
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
        title: Text('Melody Connect'),
        backgroundColor: Colors.blue[700],
      ),
      body: Column(
        children: [
          // ナビゲーションメニュー
          _buildNavigationMenu(),
          
          // 検索条件エリア
          Expanded(
            flex: 0,
            child: _buildSearchArea(),
          ),
          
          // 単語一覧
          Expanded(
            child: _buildWordList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationMenu() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          _buildNavItem('単語', isActive: true),
          _buildNavItem('問題'),
          _buildNavItem('楽曲'),
          _buildNavItem('アーティスト'),
          _buildNavItem('ジャンル'),
          _buildNavItem('バッジ'),
        ],
      ),
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

  Widget _buildSearchArea() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1列目
                Expanded(
                  child: Column(
                    children: [
                      _buildSearchField('単語', (value) => wordSearch = value),
                      SizedBox(height: 16),
                      _buildSearchField('発音', (value) => pronunciationSearch = value),
                    ],
                  ),
                ),
                SizedBox(width: 16),
                
                // 2列目
                Expanded(
                  child: Column(
                    children: [
                      _buildSearchField('品詞', (value) => partOfSpeechSearch = value),
                      SizedBox(height: 16),
                      _buildDropdown('状態', ['全て', '公開', '非公開'], (value) => statusSearch = value),
                    ],
                  ),
                ),
                SizedBox(width: 16),
                
                // 3列目
                Expanded(
                  child: Column(
                    children: [
                      _buildSearchField('日本語での意味', (value) => meaningSearch = value),
                      SizedBox(height: 16),
                      // ボタンエリア
                      Container(
                        padding: EdgeInsets.only(top: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              width: 100,
                              child: OutlinedButton(
                                onPressed: _clearSearch,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.grey[700],
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: Text('クリア', style: TextStyle(color: Colors.black)),
                              ),
                            ),
                            SizedBox(width: 8),
                            Container(
                              width: 100,
                              child: ElevatedButton(
                                onPressed: _searchWords,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue[700],
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: Text('検索', style: TextStyle(color: Colors.white)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(String label, Function(String) onChanged) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 120,
          padding: EdgeInsets.only(top: 12),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
            ),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, List<String> options, Function(String?) onChanged) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 120,
          padding: EdgeInsets.only(top: 12),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: DropdownButtonFormField<String>(
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: options.map((option) {
              return DropdownMenuItem(
                value: option == '全て' ? null : option,
                child: Text(option),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildWordList() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
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
                          border: Border(
                            left: BorderSide(color: Colors.grey[300]!),
                            right: BorderSide(color: Colors.grey[300]!),
                            bottom: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => WordDetailScreen(word: word),
                              ),
                            );
                          },
                          child: Row(
                            children: [
                              _buildTableCell(word.word, 2, TextAlign.left),
                              _buildTableCell(word.pronunciation, 2, TextAlign.left),
                              _buildTableCell(word.partOfSpeech, 2, TextAlign.left),
                              _buildTableCell(word.status, 1, TextAlign.center),
                              _buildTableCell(word.meanings.join(', '), 3, TextAlign.left),
                            ],
                          ),
                        )
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
          SizedBox(height: 16),
          Text(
            '該当単語が見つかりません',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
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
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
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
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          border: Border(right: BorderSide(color: Colors.grey[300]!)),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.grey[700],
          ),
          textAlign: align,
        ),
      ),
    );
  }
}