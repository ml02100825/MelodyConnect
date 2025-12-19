import 'package:flutter/material.dart';
import 'bottom_admin.dart';
import 'vocabulary_admin2.dart';
import 'touroku_admin.dart';

class VocabularyAdmin extends StatefulWidget {
  const VocabularyAdmin({Key? key}) : super(key: key);

  @override
  State<VocabularyAdmin> createState() => _VocabularyAdminState();
}

class _VocabularyAdminState extends State<VocabularyAdmin> {
  String selectedTab = '単語';
  String selectedMenu = 'コンテンツ管理';
  final List<bool> selectedRows = List.generate(15, (index) => false);

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
          final originalIndex = vocabularies.indexWhere((v) => v['id'] == vocabId);
          if (originalIndex != -1) {
            vocabularies[originalIndex]['status'] = '無効';
            vocabularies[originalIndex]['isActive'] = false;
          }
          filteredVocabularies[i]['status'] = '無効';
          filteredVocabularies[i]['isActive'] = false;
        }
      }
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
          final originalIndex = vocabularies.indexWhere((v) => v['id'] == vocabId);
          if (originalIndex != -1) {
            vocabularies[originalIndex]['status'] = '有効';
            vocabularies[originalIndex]['isActive'] = true;
          }
          filteredVocabularies[i]['status'] = '有効';
          filteredVocabularies[i]['isActive'] = true;
        }
      }
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
        selectedTab: selectedTab,
        showTabs: true,
        mainContent: _buildMainContent(),
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        _buildSearchArea(),
        const SizedBox(height: 24),
        Expanded(child: _buildTable()),
        const SizedBox(height: 16),
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildSearchArea() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(4),
        color: Colors.grey[50],
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
          const SizedBox(height: 16),
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
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text('クリア', style: TextStyle(fontSize: 14)),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _applyFilter,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
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
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: Colors.grey[400]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: Colors.grey[400]!),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          style: const TextStyle(fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildDropdown(String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: Colors.grey[400]!),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          value: statusFilter,
          items: ['すべて', '有効', '無効']
              .map((item) => DropdownMenuItem(
                    value: item,
                    child: Text(item, style: const TextStyle(fontSize: 13)),
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
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide(color: Colors.grey[400]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide(color: Colors.grey[400]!),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                style: const TextStyle(fontSize: 13),
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
              child: Text('〜', style: TextStyle(fontSize: 14)),
            ),
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide(color: Colors.grey[400]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide(color: Colors.grey[400]!),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                style: const TextStyle(fontSize: 13),
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
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          // ヘッダー
          Container(
            color: Colors.grey[200],
            child: Row(
              children: [
                Container(
                  width: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: Checkbox(
                    value: selectedRows.take(filteredVocabularies.length).every((selected) => selected) && 
                           filteredVocabularies.isNotEmpty,
                    onChanged: (value) {
                      setState(() {
                        for (int i = 0; i < filteredVocabularies.length; i++) {
                          selectedRows[i] = value ?? false;
                        }
                      });
                    },
                  ),
                ),
                _buildTableHeader('ID', 80),
                _buildTableHeader('単語\n意味', 200),
                _buildTableHeader('発音', 150),
                _buildTableHeader('品詞', 100),
                _buildTableHeader('状態', 100),
              ],
            ),
          ),
          // データ行
          Expanded(
            child: ListView.builder(
              itemCount: filteredVocabularies.length,
              itemBuilder: (context, index) {
                final vocab = filteredVocabularies[index];
                return Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 50,
                        padding: const EdgeInsets.all(12),
                        child: Checkbox(
                          value: selectedRows[index],
                          onChanged: (value) {
                            setState(() {
                              selectedRows[index] = value ?? false;
                            });
                          },
                        ),
                      ),
                      _buildTableCell(
                        Text(vocab['id'], style: const TextStyle(fontSize: 13)),
                        80,
                      ),
                      _buildTableCell(
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => VocabularyDetailPage(
                                  vocab: {
                                    'id': vocab['id'],
                                    'word': vocab['word'],
                                    'meaning': vocab['meaning'],
                                    'pronunciation': vocab['pronunciation'],
                                    'partOfSpeech': vocab['partOfSpeech'],
                                    'exampleSentence': '例文がここに入ります。',
                                    'exampleTranslation': '例文の訳がここに入ります。',
                                    'audioUrl': 'https://example.com/audio.mp3',
                                    'createdAt': vocab['addedDate'].toString(),
                                    'updatedAt': DateTime.now().toString(),
                                    'status': vocab['status'],
                                  },
                                ),
                              ),
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                vocab['word'],
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(vocab['meaning'], 
                                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                            ],
                          ),
                        ),
                        200,
                      ),
                      _buildTableCell(
                        Text(vocab['pronunciation'], style: const TextStyle(fontSize: 13)),
                        150,
                      ),
                      _buildTableCell(
                        Text(vocab['partOfSpeech'], style: const TextStyle(fontSize: 13)),
                        100,
                      ),
                      _buildTableCell(
                        Center(
                          child: Text(
                            vocab['status'],
                            style: TextStyle(
                              fontSize: 13,
                              color: vocab['isActive'] ? Colors.black : Colors.grey[400],
                            ),
                          ),
                        ),
                        100,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(String text, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTableCell(Widget child, double width) {
    return Container(
      width: width,
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
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: const Text('選択中の単語を無効化', style: TextStyle(fontSize: 14)),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _activateSelected,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: const Text('選択中の単語を有効化', style: TextStyle(fontSize: 14)),
          ),
          const SizedBox(width: 12),
        ],
        ElevatedButton(
          onPressed: () {
            showTourokuDialog(
              context,
              'vocabulary',
              (data) {
                setState(() {
                  final newId = (vocabularies.length + 1).toString().padLeft(4, '0');
                  data['id'] = newId;
                  data['isActive'] = true;
                  data['createdAt'] = DateTime.now().toString();
                  data['updatedAt'] = DateTime.now().toString();
                  vocabularies.add(data);
                  filteredVocabularies = List.from(vocabularies);
                });
              },
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          child: const Text('追加作成', style: TextStyle(fontSize: 14)),
        ),
      ],
    );
  }
}