import 'package:flutter/material.dart';
import 'bottom_admin.dart';
import 'user_list_admin.dart';
import 'contact_list_admin.dart';

class GenreAdmin extends StatefulWidget {
  const GenreAdmin({Key? key}) : super(key: key);

  @override
  State<GenreAdmin> createState() => _GenreAdminState();
}

class _GenreAdminState extends State<GenreAdmin> {
  String selectedMenu = 'コンテンツ管理';
  final List<bool> selectedRows = [];
  
  // 検索用のコントローラー
  final TextEditingController idController = TextEditingController();
  final TextEditingController nameController = TextEditingController();

  String statusFilter = 'すべて';
  DateTime? startDate;
  DateTime? endDate;

  bool get hasSelection => selectedRows.any((selected) => selected);

  // サンプルデータ
  List<Map<String, dynamic>> genres = [
    {
      'id': 'G001',
      'name': 'ポップ',
      'description': 'ポピュラー音楽',
      'status': '有効',
      'isActive': true,
      'addedDate': DateTime(2024, 11, 1),
      'songCount': 150,
      'artistCount': 45,
      'createdAt': '2024/11/01 10:00:00',
      'updatedAt': '2024/11/01 10:00:00',
    },
    {
      'id': 'G002',
      'name': 'ロック',
      'description': 'ロック音楽',
      'status': '有効',
      'isActive': true,
      'addedDate': DateTime(2024, 11, 15),
      'songCount': 120,
      'artistCount': 32,
      'createdAt': '2024/11/15 14:30:00',
      'updatedAt': '2024/11/15 14:30:00',
    },
    {
      'id': 'G003',
      'name': 'K-POP',
      'description': '韓国ポップ音楽',
      'status': '有効',
      'isActive': true,
      'addedDate': DateTime(2024, 11, 20),
      'songCount': 85,
      'artistCount': 28,
      'createdAt': '2024/11/20 09:15:00',
      'updatedAt': '2024/11/20 09:15:00',
    },
    {
      'id': 'G004',
      'name': 'J-POP',
      'description': '日本ポップ音楽',
      'status': '無効',
      'isActive': false,
      'addedDate': DateTime(2024, 11, 25),
      'songCount': 95,
      'artistCount': 35,
      'createdAt': '2024/11/25 16:45:00',
      'updatedAt': '2024/11/25 16:45:00',
    },
    {
      'id': 'G005',
      'name': 'ヒップホップ',
      'description': 'ヒップホップ音楽',
      'status': '有効',
      'isActive': true,
      'addedDate': DateTime(2024, 12, 1),
      'songCount': 65,
      'artistCount': 22,
      'createdAt': '2024/12/01 11:20:00',
      'updatedAt': '2024/12/01 11:20:00',
    },
  ];

  List<Map<String, dynamic>> filteredGenres = [];
  
  @override
  void initState() {
    super.initState();
    filteredGenres = List.from(genres);
    _updateSelectedRows();
  }

  void _updateSelectedRows() {
    selectedRows.clear();
    selectedRows.addAll(List<bool>.filled(filteredGenres.length, false));
  }

  void _applyFilter() {
    final idQuery = idController.text.trim();
    final nameQuery = nameController.text.trim().toLowerCase();

    setState(() {
      filteredGenres = genres.where((g) {
        final matchesId = idQuery.isEmpty || g['id'].contains(idQuery);
        final matchesName = nameQuery.isEmpty || g['name'].toLowerCase().contains(nameQuery);
        final matchesStatus = statusFilter == 'すべて' || g['status'] == statusFilter;
        
        bool matchesDate = true;
        if (startDate != null && endDate != null) {
          final addedDate = g['addedDate'] as DateTime;
          matchesDate = addedDate.isAfter(startDate!.subtract(const Duration(days: 1))) &&
                       addedDate.isBefore(endDate!.add(const Duration(days: 1)));
        }
        
        return matchesId && matchesName && matchesStatus && matchesDate;
      }).toList();
      _updateSelectedRows();
    });
  }

  void _deactivateSelected() {
    setState(() {
      for (int i = 0; i < selectedRows.length; i++) {
        if (selectedRows[i]) {
          final genreId = filteredGenres[i]['id'];
          final originalIndex = genres.indexWhere((g) => g['id'] == genreId);
          if (originalIndex != -1) {
            genres[originalIndex]['status'] = '無効';
            genres[originalIndex]['isActive'] = false;
          }
          filteredGenres[i]['status'] = '無効';
          filteredGenres[i]['isActive'] = false;
        }
      }
      selectedRows.clear();
      selectedRows.addAll(List<bool>.filled(filteredGenres.length, false));
    });
  }

  void _activateSelected() {
    setState(() {
      for (int i = 0; i < selectedRows.length; i++) {
        if (selectedRows[i]) {
          final genreId = filteredGenres[i]['id'];
          final originalIndex = genres.indexWhere((g) => g['id'] == genreId);
          if (originalIndex != -1) {
            genres[originalIndex]['status'] = '有効';
            genres[originalIndex]['isActive'] = true;
          }
          filteredGenres[i]['status'] = '有効';
          filteredGenres[i]['isActive'] = true;
        }
      }
      selectedRows.clear();
      selectedRows.addAll(List<bool>.filled(filteredGenres.length, false));
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
        selectedTab: 'ジャンル', // ハードコード
        onTabSelected: (tab) {
          // タブ遷移処理はBottomAdminLayoutで行う
        },
        showTabs: true,
        mainContent: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchArea(),
              const SizedBox(height: 24),
              filteredGenres.isEmpty ? _buildNoGenresFound() : _buildTable(),
              if (filteredGenres.isNotEmpty) ...[
                const SizedBox(height: 24),
                _buildActionButtons(),
              ],
            ],
          ),
        ),
      ),
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
              Expanded(flex: 2, child: _buildTextField('ジャンル名', nameController)),
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
                    nameController.clear();
                    statusFilter = 'すべて';
                    startDate = null;
                    endDate = null;
                    filteredGenres = List.from(genres);
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
        2: FlexColumnWidth(2),
        3: FlexColumnWidth(1.5),
        4: FlexColumnWidth(1.5),
        5: FlexColumnWidth(1),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.grey[50]),
          children: [
            _buildTableHeader('✓'),
            _buildTableHeader('ID'),
            _buildTableHeader('ジャンル名'),
            _buildTableHeader('楽曲数'),
            _buildTableHeader('アーティスト数'),
            _buildTableHeader('状態'),
          ],
        ),
        ...List.generate(filteredGenres.length, (index) {
          final genre = filteredGenres[index];
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
                Text(genre['id'], style: const TextStyle(fontSize: 14)),
              ),
              _buildTableCell(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(genre['name'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    if (genre['description'] != null && genre['description'].toString().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          genre['description'],
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              _buildTableCell(
                Text(
                  '${genre['songCount']}曲',
                  style: const TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
              _buildTableCell(
                Text(
                  '${genre['artistCount']}人',
                  style: const TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
              _buildTableCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: genre['isActive'] ? Colors.green[100] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    genre['status'],
                    style: TextStyle(
                      fontSize: 12,
                      color: genre['isActive'] ? Colors.green[800] : Colors.grey[800],
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

  Widget _buildNoGenresFound() {
    return Container(
      height: 300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.music_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '該当ジャンルが見つかりません',
              style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.bold),
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
            child: const Text('選択中のジャンルを無効化', style: TextStyle(fontSize: 14)),
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
            child: const Text('選択中のジャンルを有効化', style: TextStyle(fontSize: 14)),
          ),
          const SizedBox(width: 8),
        ],
        ElevatedButton(
          onPressed: () {
            // 新規登録処理
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