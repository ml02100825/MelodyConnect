import 'package:flutter/material.dart';
import 'bottom_admin.dart';
import 'user_list_admin.dart';
import 'contact_list_admin.dart';
import 'vocabulary_admin2.dart';
import 'artist_admin.dart';
import 'genre_admin.dart';
import 'badge_admin.dart';

class VocabularyAdmin extends StatefulWidget {
  const VocabularyAdmin({Key? key}) : super(key: key);

  @override
  State<VocabularyAdmin> createState() => _VocabularyAdminState();
}

class _VocabularyAdminState extends State<VocabularyAdmin> {
  String selectedMenu = 'コンテンツ管理';
  
  // 各行の選択状態を動的に管理
  List<bool> selectedRows = [];
  
  // 検索用のコントローラー
  final TextEditingController idController = TextEditingController();
  final TextEditingController wordController = TextEditingController();
  final TextEditingController partOfSpeechController = TextEditingController();

  String statusFilter = 'すべて';
  DateTime? startDate;
  DateTime? endDate;

  bool get hasSelection => selectedRows.any((selected) => selected);

  // サンプルデータ
  List<Map<String, dynamic>> vocabularies = [
    {
      'id': '0001',
      'word': 'hello',
      'meaning': 'こんにちは',
      'pronunciation': 'həˈloʊ',
      'partOfSpeech': '間投詞',
      'status': '有効',
      'isActive': true,
      'addedDate': DateTime(2024, 11, 1),
      'exampleSentence': 'Hello, how are you?',
      'exampleTranslation': 'こんにちは、お元気ですか？',
      'audioUrl': 'https://example.com/hello.mp3',
      'createdAt': '2024/11/01 10:00:00',
      'updatedAt': '2024/11/01 10:00:00',
    },
    {
      'id': '0002',
      'word': 'world',
      'meaning': '世界',
      'pronunciation': 'wɜːrld',
      'partOfSpeech': '名詞',
      'status': '有効',
      'isActive': true,
      'addedDate': DateTime(2024, 11, 15),
      'exampleSentence': 'The world is beautiful.',
      'exampleTranslation': '世界は美しい。',
      'audioUrl': 'https://example.com/world.mp3',
      'createdAt': '2024/11/15 14:30:00',
      'updatedAt': '2024/11/15 14:30:00',
    },
    {
      'id': '0003',
      'word': 'music',
      'meaning': '音楽',
      'pronunciation': 'ˈmjuːzɪk',
      'partOfSpeech': '名詞',
      'status': '有効',
      'isActive': true,
      'addedDate': DateTime(2024, 11, 20),
      'exampleSentence': 'I love listening to music.',
      'exampleTranslation': '音楽を聴くのが大好きです。',
      'audioUrl': 'https://example.com/music.mp3',
      'createdAt': '2024/11/20 09:15:00',
      'updatedAt': '2024/11/20 09:15:00',
    },
    {
      'id': '0004',
      'word': 'learn',
      'meaning': '学ぶ',
      'pronunciation': 'lɜːrn',
      'partOfSpeech': '動詞',
      'status': '無効',
      'isActive': false,
      'addedDate': DateTime(2024, 11, 25),
      'exampleSentence': 'Children learn quickly.',
      'exampleTranslation': '子供はすぐに学びます。',
      'audioUrl': 'https://example.com/learn.mp3',
      'createdAt': '2024/11/25 16:45:00',
      'updatedAt': '2024/11/25 16:45:00',
    },
  ];

  List<Map<String, dynamic>> filteredVocabularies = [];
  
  @override
  void initState() {
    super.initState();
    filteredVocabularies = List.from(vocabularies);
    _updateSelectedRows();
  }

  // selectedRowsをフィルター後のデータ数に合わせて更新
  void _updateSelectedRows() {
    selectedRows = List<bool>.filled(filteredVocabularies.length, false);
  }

  void _applyFilter() {
    final idQuery = idController.text.trim();
    final wordQuery = wordController.text.trim().toLowerCase();
    final partQuery = partOfSpeechController.text.trim();

    setState(() {
      filteredVocabularies = vocabularies.where((v) {
        final matchesId = idQuery.isEmpty || v['id'].contains(idQuery);
        final matchesWord = wordQuery.isEmpty || v['word'].toLowerCase().contains(wordQuery);
        final matchesPart = partQuery.isEmpty || v['partOfSpeech'].contains(partQuery);
        final matchesStatus = statusFilter == 'すべて' || v['status'] == statusFilter;
        
        // 日付フィルター
        bool matchesDate = true;
        if (startDate != null && endDate != null) {
          final addedDate = v['addedDate'] as DateTime;
          matchesDate = addedDate.isAfter(startDate!.subtract(const Duration(days: 1))) &&
                       addedDate.isBefore(endDate!.add(const Duration(days: 1)));
        }
        
        return matchesId && matchesWord && matchesPart && matchesStatus && matchesDate;
      }).toList();
      _updateSelectedRows();
    });
  }

  void _deactivateSelected() {
    setState(() {
      for (int i = 0; i < selectedRows.length; i++) {
        if (selectedRows[i]) {
          final vocabId = filteredVocabularies[i]['id'];
          // 元のリストも更新
          final originalIndex = vocabularies.indexWhere((v) => v['id'] == vocabId);
          if (originalIndex != -1) {
            vocabularies[originalIndex]['status'] = '無効';
            vocabularies[originalIndex]['isActive'] = false;
          }
          // フィルター済みリストも更新
          filteredVocabularies[i]['status'] = '無効';
          filteredVocabularies[i]['isActive'] = false;
        }
      }
      // チェックボックスをリセット
      selectedRows = List<bool>.filled(filteredVocabularies.length, false);
    });
  }

  void _activateSelected() {
    setState(() {
      for (int i = 0; i < selectedRows.length; i++) {
        if (selectedRows[i]) {
          final vocabId = filteredVocabularies[i]['id'];
          // 元のリストも更新
          final originalIndex = vocabularies.indexWhere((v) => v['id'] == vocabId);
          if (originalIndex != -1) {
            vocabularies[originalIndex]['status'] = '有効';
            vocabularies[originalIndex]['isActive'] = true;
          }
          // フィルター済みリストも更新
          filteredVocabularies[i]['status'] = '有効';
          filteredVocabularies[i]['isActive'] = true;
        }
      }
      // チェックボックスをリセット
      selectedRows = List<bool>.filled(filteredVocabularies.length, false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: BottomAdminLayout(
        selectedMenu: selectedMenu,
        onMenuSelected: (menu) {
          // メニュー遷移処理
          if (menu == 'ユーザー管理') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => UserListAdmin()),
            );
          } else if (menu == 'お問い合わせ管理') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => ContactListAdmin()),
            );
          }
        },
        selectedTab: '単語', // ハードコード
        onTabSelected: (tab) {
          // タブ遷移処理はBottomAdminLayoutで行う
          // ここでは何もしない
        },
        showTabs: true, // タブを表示
        mainContent: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // _buildTabMenu(),
              const SizedBox(height: 24),
              _buildSearchArea(),
              const SizedBox(height: 24),
              // データがある場合はテーブル、ない場合はNo Users Foundを表示
              filteredVocabularies.isEmpty ? _buildNoUsersFound() : _buildTable(),
              if (filteredVocabularies.isNotEmpty) ...[
                const SizedBox(height: 24),
                _buildActionButtons(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Widget _buildTabMenu() {
  //   final tabs = ['単語', '問題', '楽曲', 'アーティスト', 'ジャンル', 'バッジ'];

  //   return Row(
  //     children: tabs.map((tab) {
  //       final isSelected = selectedTab == tab;

  //       return GestureDetector(
  //         onTap: () {
  //           setState(() {
  //             selectedTab = tab;
  //           });
  //         },
  //         child: Container(
  //           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  //           decoration: BoxDecoration(
  //             border: Border(
  //               bottom: BorderSide(
  //                 color: isSelected ? Colors.lightBlue : Colors.transparent,
  //                 width: 2,
  //               ),
  //             ),
  //           ),
  //           child: Text(
  //             tab,
  //             style: TextStyle(
  //               fontSize: 14,
  //               color: isSelected ? Colors.lightBlue : Colors.grey[600],
  //               fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
  //             ),
  //           ),
  //         ),
  //       );
  //     }).toList(),
  //   );
  // }

  Widget _buildSearchArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(flex: 1, child: _buildTextField('ID', idController)),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: _buildTextField('単語', wordController)),
              const SizedBox(width: 12),
              Expanded(flex: 1, child: _buildTextField('品詞', partOfSpeechController)),
              const SizedBox(width: 12),
              Expanded(flex: 1, child: _buildDropdown('状態')),
              const SizedBox(width: 12),
              Expanded(flex: 3, child: _buildDateRangeField('追加日')),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    idController.clear();
                    wordController.clear();
                    partOfSpeechController.clear();
                    statusFilter = 'すべて';
                    startDate = null;
                    endDate = null;
                    filteredVocabularies = List.from(vocabularies);
                    _updateSelectedRows();
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                  foregroundColor: Colors.grey[700],
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('クリア', style: TextStyle(fontSize: 14)),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _applyFilter,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('検索', style: TextStyle(fontSize: 14)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildDropdown(String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          value: statusFilter,
          items: ['すべて', '有効', '無効']
              .map((item) => DropdownMenuItem(
                    value: item,
                    child: Text(item, style: const TextStyle(fontSize: 14)),
                  ))
              .toList(),
          onChanged: (value) {
            setState(() {
              statusFilter = value ?? 'すべて';
            });
          },
        ),
      ],
    );
  }

  Widget _buildDateRangeField(String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  hintText: '開始日',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  suffixIcon: Icon(Icons.calendar_today, size: 18, color: Colors.grey[600]),
                ),
                style: const TextStyle(fontSize: 14),
                readOnly: true,
                controller: TextEditingController(
                  text: startDate != null 
                      ? '${startDate!.year}/${startDate!.month}/${startDate!.day}'
                      : '',
                ),
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: startDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() {
                      startDate = picked;
                    });
                  }
                },
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text('〜', style: TextStyle(fontSize: 16)),
            ),
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  hintText: '終了日',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  suffixIcon: Icon(Icons.calendar_today, size: 18, color: Colors.grey[600]),
                ),
                style: const TextStyle(fontSize: 14),
                readOnly: true,
                controller: TextEditingController(
                  text: endDate != null 
                      ? '${endDate!.year}/${endDate!.month}/${endDate!.day}'
                      : '',
                ),
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: endDate ?? startDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() {
                      endDate = picked;
                    });
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTable() {
    return Table(
      border: TableBorder.all(color: Colors.grey[300]!),
      columnWidths: const {
        0: FixedColumnWidth(60),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1.5),
        3: FlexColumnWidth(1.5),
        4: FlexColumnWidth(1),
        5: FlexColumnWidth(1),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.grey[50]),
          children: [
            _buildTableHeader('✓'),
            _buildTableHeader('ID'),
            _buildTableHeader('単語'),
            _buildTableHeader('発音'),
            _buildTableHeader('品詞'),
            _buildTableHeader('状態'),
          ],
        ),
        ...List.generate(filteredVocabularies.length, (index) {
          final vocab = filteredVocabularies[index];
          return TableRow(
            children: [
              _buildTableCell(
                Center(
                  child: Checkbox(
                    value: selectedRows[index],
                    onChanged: (value) {
                      setState(() {
                        selectedRows[index] = value ?? false;
                      });
                    },
                  ),
                ),
              ),
              _buildTableCell(
                GestureDetector(
                  onTap: () => _navigateToDetailPage(context, vocab),
                  child: Text(vocab['id'], style: const TextStyle(fontSize: 14)),
                ),
              ),
              _buildTableCell(
                GestureDetector(
                  onTap: () => _navigateToDetailPage(context, vocab),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(vocab['word'], style: const TextStyle(fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(vocab['meaning'], style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                ),
              ),
              _buildTableCell(
                GestureDetector(
                  onTap: () => _navigateToDetailPage(context, vocab),
                  child: Text(vocab['pronunciation'], style: const TextStyle(fontSize: 12)),
                ),
              ),
              _buildTableCell(
                GestureDetector(
                  onTap: () => _navigateToDetailPage(context, vocab),
                  child: Text(vocab['partOfSpeech'], style: const TextStyle(fontSize: 12)),
                ),
              ),
              _buildTableCell(
                GestureDetector(
                  onTap: () => _navigateToDetailPage(context, vocab),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: vocab['isActive'] ? Colors.green[100] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      vocab['status'],
                      style: TextStyle(
                        fontSize: 12,
                        color: vocab['isActive'] ? Colors.green[800] : Colors.grey[800],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  Future<void> _navigateToDetailPage(BuildContext context, Map<String, dynamic> vocab) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VocabularyDetailAdmin(
          vocab: vocab,
          onStatusChanged: (updatedVocab, newStatus) {
            // 詳細ページでの状態変更を反映
            setState(() {
              final originalIndex = vocabularies.indexWhere((v) => v['id'] == updatedVocab['id']);
              if (originalIndex != -1) {
                vocabularies[originalIndex] = updatedVocab;
              }
              
              final filteredIndex = filteredVocabularies.indexWhere((v) => v['id'] == updatedVocab['id']);
              if (filteredIndex != -1) {
                filteredVocabularies[filteredIndex] = updatedVocab;
              }
            });
          },
        ),
      ),
    );

    // 削除処理
    if (result != null && result['action'] == 'delete') {
      final deletedVocab = result['vocab'];
      setState(() {
        vocabularies.removeWhere((v) => v['id'] == deletedVocab['id']);
        filteredVocabularies.removeWhere((v) => v['id'] == deletedVocab['id']);
        _updateSelectedRows();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('単語を削除しました')),
      );
    }
  }

  // 単語が見つからない場合のウィジェット
  Widget _buildNoUsersFound() {
    return Container(
      height: 400, // 適切な高さを設定
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
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
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader(String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: Colors.grey[700],
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildTableCell(Widget child) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: child,
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (hasSelection) ...[
          ElevatedButton(
            onPressed: _deactivateSelected,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: const Text('選択中の単語を無効化', style: TextStyle(fontSize: 14)),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _activateSelected,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: const Text('選択中の単語を有効化', style: TextStyle(fontSize: 14)),
          ),
          const SizedBox(width: 8),
        ],
        ElevatedButton(
          onPressed: () {
            // 新規登録機能
            // TODO: 新規登録画面への遷移を実装
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.lightBlue,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
          child: const Text('新規登録', style: TextStyle(fontSize: 14)),
        ),
      ],
    );
  }
}