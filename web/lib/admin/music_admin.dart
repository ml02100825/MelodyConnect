import 'package:flutter/material.dart';
import 'bottom_admin.dart';
import 'vocabulary_admin.dart';
import 'mondai_admin.dart';
import 'artist_admin.dart';
import 'genre_admin.dart';
import 'badge_admin.dart';
import 'music_admin2.dart';
import 'touroku_admin.dart';

class MusicAdmin extends StatefulWidget {
  const MusicAdmin({super.key});

  @override
  State<MusicAdmin> createState() => _MusicAdminState();
}

class _MusicAdminState extends State<MusicAdmin> {
  String selectedTab = '楽曲';
  String selectedMenu = 'コンテンツ管理';

  // 検索フォームのコントローラー
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _songNameController = TextEditingController();
  final TextEditingController _artistController = TextEditingController();
  final TextEditingController _languageController = TextEditingController();
  DateTime? startDate;
  DateTime? endDate;
  
  String? _selectedGenre;
  String? _selectedStatus;

  // サンプルデータ
  final List<Map<String, dynamic>> _musicList = [
    {'id': '0001', 'songName': '楽曲01', 'artist': 'アーティスト01', 'status': '有効'},
    {'id': '0002', 'songName': '楽曲02', 'artist': 'アーティスト02', 'status': '有効'},
    {'id': '0003', 'songName': '楽曲03', 'artist': 'アーティスト03', 'status': '有効'},
    {'id': '0004', 'songName': '楽曲04', 'artist': 'アーティスト04', 'status': '無効'},
  ];

  final Set<String> _selectedIds = {};

  bool get hasSelection => _selectedIds.isNotEmpty;

  void _deactivateSelected() {
    setState(() {
      for (var id in _selectedIds) {
        final index = _musicList.indexWhere((item) => item['id'] == id);
        if (index != -1) {
          _musicList[index]['status'] = '無効';
        }
      }
      _selectedIds.clear();
    });
  }

  void _activateSelected() {
    setState(() {
      for (var id in _selectedIds) {
        final index = _musicList.indexWhere((item) => item['id'] == id);
        if (index != -1) {
          _musicList[index]['status'] = '有効';
        }
      }
      _selectedIds.clear();
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
        Expanded(child: _buildDataTable()),
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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MondaiAdmin()),
        );
        break;
      case '楽曲':
        // 既に楽曲画面なので何もしない
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
              Expanded(
                child: _buildSearchField('ID', _idController),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdown('ジャンル', _selectedGenre, const ['ジャンル1', 'ジャンル2'], (value) {
                  setState(() {
                    _selectedGenre = value;
                  });
                }),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdown('状態', _selectedStatus, const ['有効', '無効'], (value) {
                  setState(() {
                    _selectedStatus = value;
                  });
                }),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildSearchField('楽曲名', _songNameController),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSearchField('言語', _languageController),
              ),
              const SizedBox(width: 12),
              const Expanded(child: SizedBox()),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildSearchField('アーティスト', _artistController),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateRangeCompact('追加日'),
              ),
              const SizedBox(width: 12),
              const Expanded(child: SizedBox()),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _idController.clear();
                    _songNameController.clear();
                    _artistController.clear();
                    _languageController.clear();
                    startDate = null;
                    endDate = null;
                    _selectedGenre = null;
                    _selectedStatus = null;
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
                onPressed: () {
                  // 検索処理
                },
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

  Widget _buildSearchField(String label, TextEditingController controller) {
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

  Widget _buildDropdown(String label, String? value, List<String> items, Function(String?) onChanged) {
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

  Widget _buildDataTable() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          // テーブルヘッダー
          Container(
            color: Colors.grey[200],
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  child: Checkbox(
                    value: _selectedIds.length == _musicList.length && _musicList.isNotEmpty,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedIds.addAll(_musicList.map((e) => e['id'] as String));
                        } else {
                          _selectedIds.clear();
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  flex: 1,
                  child: Text(
                    'ID',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                ),
                const Expanded(
                  flex: 3,
                  child: Text(
                    '楽曲名',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                ),
                const Expanded(
                  flex: 3,
                  child: Text(
                    'アーティスト',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                ),
                const Expanded(
                  flex: 1,
                  child: Text(
                    '状態',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          // テーブルボディ
          Expanded(
            child: ListView.builder(
              itemCount: _musicList.length,
              itemBuilder: (context, index) {
                final item = _musicList[index];
                final isSelected = _selectedIds.contains(item['id']);
                return Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 40,
                        child: Checkbox(
                          value: isSelected,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _selectedIds.add(item['id'] as String);
                              } else {
                                _selectedIds.remove(item['id']);
                              }
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: Text(
                          item['id'] as String,
                          style: const TextStyle(fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MusicDetailPage(
                                  music: item,
                                ),
                              ),
                            );
                          },
                          child: Text(
                            item['songName'] as String,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          item['artist'] as String,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          item['status'] as String,
                          style: TextStyle(
                            fontSize: 13,
                            color: item['status'] == '有効' ? Colors.black : Colors.grey[400],
                          ),
                          textAlign: TextAlign.center,
                        ),
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
            child: const Text('選択中の楽曲を無効化', style: TextStyle(fontSize: 14)),
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
            child: const Text('選択中の楽曲を有効化', style: TextStyle(fontSize: 14)),
          ),
          const SizedBox(width: 12),
        ],
        ElevatedButton(
          onPressed: () {
            showTourokuDialog(
              context,
              'music',
              (data) {
                setState(() {
                  final newId = (_musicList.length + 1).toString().padLeft(4, '0');
                  data['id'] = newId;
                  _musicList.add(data);
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

  @override
  void dispose() {
    _idController.dispose();
    _songNameController.dispose();
    _artistController.dispose();
    _languageController.dispose();
    super.dispose();
  }
}