import 'package:flutter/material.dart';
import 'bottom_admin.dart';
import 'vocabulary_admin.dart';
import 'music_admin.dart';
import 'artist_admin.dart';
import 'genre_admin.dart';
import 'badge_admin.dart';
import 'mondai_admin2.dart';
import 'touroku_admin.dart';
import 'mondai_admin2.dart';

class MondaiAdmin extends StatefulWidget {
  const MondaiAdmin({Key? key}) : super(key: key);

  @override
  State<MondaiAdmin> createState() => _MondaiAdminState();
}

class _MondaiAdminState extends State<MondaiAdmin> {
  String selectedTab = '問題';
  String selectedMenu = 'コンテンツ管理';
  final List<bool> selectedRows = List.generate(15, (index) => false);

  final TextEditingController idController = TextEditingController();
  final TextEditingController questionController = TextEditingController();
  final TextEditingController correctAnswerController = TextEditingController();
  final TextEditingController songNameController = TextEditingController();
  final TextEditingController artistController = TextEditingController();

  String categoryFilter = '問題形式';
  String difficultyFilter = '難易度';
  String statusFilter = '状態';
  DateTime? startDate;
  DateTime? endDate;

  bool get hasSelection => selectedRows.any((selected) => selected);

  List<Map<String, dynamic>> questions = [
    {
      'id': '0001',
      'question': 'This question is an ——.\nこの問題は例です。',
      'correctAnswer': 'example\n☆☆☆☆☆★',
      'category': '穴埋め',
      'difficulty': '初級',
      'status': '有効',
      'addedDate': DateTime(2024, 9, 1),
      'releaseDate': DateTime(2019, 12, 15),
      'songName': '楽曲01',
      'artist': 'アーティスト01',
    },
    {
      'id': '0002',
      'question': 'This question is an ——.\nこの問題は例です。',
      'correctAnswer': 'example\n☆☆☆☆☆★',
      'category': '穴埋め',
      'difficulty': '初級',
      'status': '有効',
      'addedDate': DateTime(2024, 9, 15),
      'releaseDate': DateTime(2018, 2, 12),
      'songName': '楽曲02',
      'artist': 'アーティスト02',
    },
    {
      'id': '0003',
      'question': 'This question is an example.',
      'correctAnswer': '☆☆☆☆☆★',
      'category': 'リスニング',
      'difficulty': '中級',
      'status': '有効',
      'addedDate': DateTime(2024, 10, 1),
      'releaseDate': DateTime(2019, 5, 15),
      'songName': '楽曲03',
      'artist': 'アーティスト03',
    },
    {
      'id': '0004',
      'question': 'This question is an example.',
      'correctAnswer': '☆☆☆☆☆★',
      'category': 'リスニング',
      'difficulty': '中級',
      'status': '無効',
      'addedDate': DateTime(2024, 10, 15),
      'releaseDate': DateTime(2020, 2, 12),
      'songName': '楽曲04',
      'artist': 'アーティスト04',
    },
  ];

  List<Map<String, dynamic>> filteredQuestions = [];

  @override
  void initState() {
    super.initState();
    filteredQuestions = List.from(questions);
  }

  void _applyFilter() {
    final idQuery = idController.text.trim();
    final questionQuery = questionController.text.trim().toLowerCase();
    final correctAnswerQuery = correctAnswerController.text.trim().toLowerCase();
    final songNameQuery = songNameController.text.trim().toLowerCase();
    final artistQuery = artistController.text.trim().toLowerCase();

    setState(() {
      filteredQuestions = questions.where((q) {
        final matchesId = idQuery.isEmpty || q['id'].contains(idQuery);
        final matchesQuestion = questionQuery.isEmpty || 
                               q['question'].toLowerCase().contains(questionQuery);
        final matchesCorrectAnswer = correctAnswerQuery.isEmpty || 
                                     q['correctAnswer'].toLowerCase().contains(correctAnswerQuery);
        final matchesSongName = songNameQuery.isEmpty || 
                               q['songName'].toLowerCase().contains(songNameQuery);
        final matchesArtist = artistQuery.isEmpty || 
                             q['artist'].toLowerCase().contains(artistQuery);
        final matchesCategory = categoryFilter == '問題形式' || q['category'] == categoryFilter;
        final matchesStatus = statusFilter == '状態' || q['status'] == statusFilter;
        final matchesDifficulty = difficultyFilter == '難易度' || q['difficulty'] == difficultyFilter;
        
        bool matchesDate = true;
        if (startDate != null && endDate != null) {
          final addedDate = q['addedDate'] as DateTime;
          matchesDate = addedDate.isAfter(startDate!.subtract(const Duration(days: 1))) &&
                       addedDate.isBefore(endDate!.add(const Duration(days: 1)));
        }
        
        return matchesId && matchesQuestion && matchesCorrectAnswer && matchesSongName && 
               matchesArtist && matchesCategory && matchesStatus && matchesDifficulty && matchesDate;
      }).toList();
    });
  }

  void _deactivateSelected() {
    setState(() {
      for (int i = 0; i < selectedRows.length; i++) {
        if (selectedRows[i] && i < filteredQuestions.length) {
          final questionId = filteredQuestions[i]['id'];
          final originalIndex = questions.indexWhere((q) => q['id'] == questionId);
          if (originalIndex != -1) {
            questions[originalIndex]['status'] = '無効';
          }
          filteredQuestions[i]['status'] = '無効';
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
        if (selectedRows[i] && i < filteredQuestions.length) {
          final questionId = filteredQuestions[i]['id'];
          final originalIndex = questions.indexWhere((q) => q['id'] == questionId);
          if (originalIndex != -1) {
            questions[originalIndex]['status'] = '有効';
          }
          filteredQuestions[i]['status'] = '有効';
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
        showTabs: false,
        mainContent: _buildMainContent(),
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        _buildTabBar(),
        const SizedBox(height: 24),
        _buildSearchArea(),
        const SizedBox(height: 24),
        Expanded(child: _buildDataList()),
        const SizedBox(height: 16),
        _buildActionButton(),
      ],
    );
  }

  Widget _buildTabBar() {
    final tabs = ['単語', '問題', '楽曲', 'アーティスト', 'ジャンル', 'バッジ'];
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        children: tabs.map((tab) {
          final isSelected = selectedTab == tab;
          return GestureDetector(
            onTap: () {
              setState(() {
                selectedTab = tab;
              });
              _navigateToTab(tab);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSelected ? Colors.blue : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                tab,
                style: TextStyle(
                  fontSize: 14,
                  color: isSelected ? Colors.blue : Colors.grey[600],
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _navigateToTab(String tab) {
    switch (tab) {
      case '単語':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const VocabularyAdmin()),
        );
        break;
      case '問題':
        // 既に問題画面なので何もしない
        break;
      case '楽曲':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MusicAdmin()),
        );
        break;
      case 'アーティスト':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ArtistAdmin()),
        );
        break;
      case 'ジャンル':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const GenreAdmin()),
        );
        break;
      case 'バッジ':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const BadgeAdmin()),
        );
        break;
    }
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 1, child: _buildCompactTextField('ID', idController)),
              const SizedBox(width: 12),
              Expanded(flex: 1, child: _buildCompactDropdown('問題形式', categoryFilter, 
                ['問題形式', '穴埋め', 'リスニング', '選択', '並び替え'], (value) {
                setState(() {
                  categoryFilter = value ?? '問題形式';
                });
              })),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: _buildDateRangeCompact('追加日')),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 1, child: _buildCompactTextField('問題文', questionController)),
              const SizedBox(width: 12),
              Expanded(flex: 1, child: _buildCompactDropdown('難易度', difficultyFilter, 
                ['難易度', '初級', '中級', '上級'], (value) {
                setState(() {
                  difficultyFilter = value ?? '難易度';
                });
              })),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: _buildCompactTextField('楽曲名', songNameController)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 1, child: _buildCompactTextField('正答', correctAnswerController)),
              const SizedBox(width: 12),
              Expanded(flex: 1, child: _buildCompactDropdown('状態', statusFilter, 
                ['状態', '有効', '無効'], (value) {
                setState(() {
                  statusFilter = value ?? '状態';
                });
              })),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: _buildCompactTextField('アーティスト名', artistController)),
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
                    questionController.clear();
                    correctAnswerController.clear();
                    songNameController.clear();
                    artistController.clear();
                    categoryFilter = '問題形式';
                    difficultyFilter = '難易度';
                    statusFilter = '状態';
                    startDate = null;
                    endDate = null;
                    filteredQuestions = List.from(questions);
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

  Widget _buildCompactTextField(String label, TextEditingController controller) {
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

  Widget _buildCompactDropdown(String label, String value, List<String> items, Function(String?) onChanged) {
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
          value: value,
          items: items
              .map((item) => DropdownMenuItem(
                    value: item,
                    child: Text(item, style: const TextStyle(fontSize: 13)),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildDateRangeCompact(String label) {
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

  Widget _buildDataList() {
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
                    value: selectedRows.take(filteredQuestions.length).every((selected) => selected) && 
                           filteredQuestions.isNotEmpty,
                    onChanged: (value) {
                      setState(() {
                        for (int i = 0; i < filteredQuestions.length; i++) {
                          selectedRows[i] = value ?? false;
                        }
                      });
                    },
                  ),
                ),
                _buildListHeader('ID\n問題形式', 80),
                _buildListHeader('問題文\n知識', 250),
                _buildListHeader('正答\n難易度', 150),
                _buildListHeader('楽曲名\nアーティスト名', 180),
                _buildListHeader('状態', 80),
              ],
            ),
          ),
          // データ行
          Expanded(
            child: ListView.builder(
              itemCount: filteredQuestions.length,
              itemBuilder: (context, index) {
                final question = filteredQuestions[index];
                return Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildListCell(
                        Checkbox(
                          value: selectedRows[index],
                          onChanged: (value) {
                            setState(() {
                              selectedRows[index] = value ?? false;
                            });
                          },
                        ),
                        50,
                      ),
                      _buildListCell(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(question['id'], style: const TextStyle(fontSize: 13)),
                            const SizedBox(height: 4),
                            Text(question['category'], 
                              style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          ],
                        ),
                        80,
                      ),
                      _buildListCell(
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MondaiDetailPage(
                                  vocab: question,
                                ),
                              ),
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                question['question'].split('\n')[0],
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (question['question'].contains('\n')) ...[
                                const SizedBox(height: 4),
                                Text(
                                  question['question'].split('\n')[1],
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        250,
                      ),
                      _buildListCell(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              question['correctAnswer'].split('\n')[0],
                              style: const TextStyle(fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (question['correctAnswer'].contains('\n')) ...[
                              const SizedBox(height: 4),
                              Text(
                                question['correctAnswer'].split('\n')[1],
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                        150,
                      ),
                      _buildListCell(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(question['songName'], style: const TextStyle(fontSize: 13)),
                            const SizedBox(height: 4),
                            Text(question['artist'], 
                              style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          ],
                        ),
                        180,
                      ),
                      _buildListCell(
                        Center(
                          child: Text(
                            question['status'],
                            style: TextStyle(
                              fontSize: 13,
                              color: question['status'] == '有効' ? Colors.black : Colors.grey[400],
                            ),
                          ),
                        ),
                        80,
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

  Widget _buildListHeader(String text, double width) {
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

  Widget _buildListCell(Widget child, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(12),
      child: child,
    );
  }

  Widget _buildActionButton() {
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
            child: const Text('選択中の問題を無効化', style: TextStyle(fontSize: 14)),
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
            child: const Text('選択中の問題を有効化', style: TextStyle(fontSize: 14)),
          ),
          const SizedBox(width: 12),
        ],
        ElevatedButton(
          onPressed: () {
            showTourokuDialog(
              context,
              'mondai',
              (data) {
                setState(() {
                  final newId = (questions.length + 1).toString().padLeft(4, '0');
                  data['id'] = newId;
                  data['releaseDate'] = DateTime.now();
                  questions.add(data);
                  filteredQuestions = List.from(questions);
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