import 'package:flutter/material.dart';
import 'bottom_admin.dart';
import 'vocabulary_admin2.dart';

class VocabularyAdmin extends StatefulWidget {
  const VocabularyAdmin({Key? key}) : super(key: key);

  @override
  State<VocabularyAdmin> createState() => _VocabularyAdminState();
}

class _VocabularyAdminState extends State<VocabularyAdmin> {
  String selectedTab = '単語';
  String selectedMenu = 'コンテンツ管理';
  final List<bool> selectedRows = [false, false, false, false];

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
    },
  ];

  List<Map<String, dynamic>> filteredVocabularies = [];
  

  @override
  void initState() {
    super.initState();
    filteredVocabularies = List.from(vocabularies);
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
    });
  }

  void _deactivateSelected() {
    setState(() {
      for (int i = 0; i < selectedRows.length; i++) {
        if (selectedRows[i] && i < filteredVocabularies.length) {
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
      for (int i = 0; i < selectedRows.length; i++) {
        selectedRows[i] = false;
      }
    });
  }

  void _activateSelected() {
    setState(() {
      for (int i = 0; i < selectedRows.length; i++) {
        if (selectedRows[i] && i < filteredVocabularies.length) {
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
      for (int i = 0; i < selectedRows.length; i++) {
        selectedRows[i] = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: BottomAdminLayout(
        selectedMenu: selectedMenu,
        onMenuSelected: (menu) {
          setState(() {
            selectedMenu = menu;
          });
        },
        selectedTab: selectedTab,
        onTabSelected: (tab) {
          if (tab != null) {
            setState(() {
              selectedTab = tab;
            });
          }
        },
        showTabs: false,
        mainContent: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTabMenu(),
              const SizedBox(height: 24),
              _buildSearchArea(),
              const SizedBox(height: 24),
              _buildTable(),
              const SizedBox(height: 24),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabMenu() {
  final tabs = ['単語', '問題', '楽曲', 'アーティスト', 'ジャンル', 'バッジ'];

  return Row(
    children: tabs.map((tab) {
      final isSelected = selectedTab == tab;

      return GestureDetector(
        onTap: () {
          setState(() {
            selectedTab = tab;
          });

          // ▼ 単語タブ選択時だけ「単語詳細ページ」へ遷移
          if (tab == '単語') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VocabularyDetailPage(
                  vocab: {
                    // ※ ここに本物の単語データを渡す
                    'id': '0001',
                    'word': 'example',
                    'meaning': '例',
                    'partOfSpeech': '名詞',
                    'pronunciation': 'エグザンプル',
                    'exampleSentence': 'This is an example.',
                    'exampleTranslation': 'これは例です。',
                    'audioUrl': '',
                    'createdAt': '',
                    'updatedAt': '',
                    'status': 'active',
                  },
                ),
              ),
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? Colors.lightBlue : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            tab,
            style: TextStyle(
              fontSize: 14,
              color: isSelected ? Colors.lightBlue : Colors.grey[600],
              fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ),
      );
    }).toList(),
  );
}

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
    final filtered = filteredVocabularies;

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
        ...List.generate(filtered.length, (index) {
          final vocab = filtered[index];
          return TableRow(
            children: [
              _buildTableCell(
                Center(
                  child: Checkbox(
                    value: selectedRows[index % selectedRows.length],
                    onChanged: (value) {
                      setState(() {
                        selectedRows[index % selectedRows.length] = value ?? false;
                      });
                    },
                  ),
                ),
              ),
              _buildTableCell(Text(vocab['id'], style: const TextStyle(fontSize: 14))),
              _buildTableCell(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(vocab['word'], style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(vocab['meaning'], style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ),
              _buildTableCell(Text(vocab['pronunciation'], style: const TextStyle(fontSize: 12))),
              _buildTableCell(Text(vocab['partOfSpeech'], style: const TextStyle(fontSize: 12))),
              _buildTableCell(
                Container(
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
            ],
          );
        }),
      ],
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
    return Container(padding: const EdgeInsets.all(12), child: child);
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
          onPressed: () {},
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