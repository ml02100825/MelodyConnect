import 'package:flutter/material.dart';
import 'bottom_admin.dart';
import 'user_list_admin.dart';
import 'contact_list_admin.dart';

class ArtistAdmin extends StatefulWidget {
  const ArtistAdmin({Key? key}) : super(key: key);

  @override
  State<ArtistAdmin> createState() => _ArtistAdminState();
}

class _ArtistAdminState extends State<ArtistAdmin> {
  String selectedMenu = 'コンテンツ管理';
  final List<bool> selectedRows = [];
  
  // 検索用のコントローラー
  final TextEditingController idController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController countryController = TextEditingController();

  String statusFilter = 'すべて';
  DateTime? startDate;
  DateTime? endDate;

  bool get hasSelection => selectedRows.any((selected) => selected);

  // サンプルデータ
  List<Map<String, dynamic>> artists = [
    {
      'id': 'A001',
      'name': 'Taylor Swift',
      'country': 'アメリカ',
      'genre': 'ポップ',
      'status': '有効',
      'isActive': true,
      'addedDate': DateTime(2024, 11, 1),
      'description': 'アメリカの人気ポップシンガー',
      'createdAt': '2024/11/01 10:00:00',
      'updatedAt': '2024/11/01 10:00:00',
    },
    {
      'id': 'A002',
      'name': 'BTS',
      'country': '韓国',
      'genre': 'K-POP',
      'status': '有効',
      'isActive': true,
      'addedDate': DateTime(2024, 11, 15),
      'description': '世界的に人気の韓国ボーイグループ',
      'createdAt': '2024/11/15 14:30:00',
      'updatedAt': '2024/11/15 14:30:00',
    },
    {
      'id': 'A003',
      'name': 'Ed Sheeran',
      'country': 'イギリス',
      'genre': 'ポップ',
      'status': '有効',
      'isActive': true,
      'addedDate': DateTime(2024, 11, 20),
      'description': 'イギリスのシンガーソングライター',
      'createdAt': '2024/11/20 09:15:00',
      'updatedAt': '2024/11/20 09:15:00',
    },
    {
      'id': 'A004',
      'name': 'YOASOBI',
      'country': '日本',
      'genre': 'J-POP',
      'status': '無効',
      'isActive': false,
      'addedDate': DateTime(2024, 11, 25),
      'description': '日本の音楽ユニット',
      'createdAt': '2024/11/25 16:45:00',
      'updatedAt': '2024/11/25 16:45:00',
    },
  ];

  List<Map<String, dynamic>> filteredArtists = [];
  
  @override
  void initState() {
    super.initState();
    filteredArtists = List.from(artists);
    _updateSelectedRows();
  }

  void _updateSelectedRows() {
    selectedRows.clear();
    selectedRows.addAll(List<bool>.filled(filteredArtists.length, false));
  }

  void _applyFilter() {
    final idQuery = idController.text.trim();
    final nameQuery = nameController.text.trim().toLowerCase();
    final countryQuery = countryController.text.trim();

    setState(() {
      filteredArtists = artists.where((a) {
        final matchesId = idQuery.isEmpty || a['id'].contains(idQuery);
        final matchesName = nameQuery.isEmpty || a['name'].toLowerCase().contains(nameQuery);
        final matchesCountry = countryQuery.isEmpty || a['country'].contains(countryQuery);
        final matchesStatus = statusFilter == 'すべて' || a['status'] == statusFilter;
        
        bool matchesDate = true;
        if (startDate != null && endDate != null) {
          final addedDate = a['addedDate'] as DateTime;
          matchesDate = addedDate.isAfter(startDate!.subtract(const Duration(days: 1))) &&
                       addedDate.isBefore(endDate!.add(const Duration(days: 1)));
        }
        
        return matchesId && matchesName && matchesCountry && matchesStatus && matchesDate;
      }).toList();
      _updateSelectedRows();
    });
  }

  void _deactivateSelected() {
    setState(() {
      for (int i = 0; i < selectedRows.length; i++) {
        if (selectedRows[i]) {
          final artistId = filteredArtists[i]['id'];
          final originalIndex = artists.indexWhere((a) => a['id'] == artistId);
          if (originalIndex != -1) {
            artists[originalIndex]['status'] = '無効';
            artists[originalIndex]['isActive'] = false;
          }
          filteredArtists[i]['status'] = '無効';
          filteredArtists[i]['isActive'] = false;
        }
      }
      selectedRows.clear();
      selectedRows.addAll(List<bool>.filled(filteredArtists.length, false));
    });
  }

  void _activateSelected() {
    setState(() {
      for (int i = 0; i < selectedRows.length; i++) {
        if (selectedRows[i]) {
          final artistId = filteredArtists[i]['id'];
          final originalIndex = artists.indexWhere((a) => a['id'] == artistId);
          if (originalIndex != -1) {
            artists[originalIndex]['status'] = '有効';
            artists[originalIndex]['isActive'] = true;
          }
          filteredArtists[i]['status'] = '有効';
          filteredArtists[i]['isActive'] = true;
        }
      }
      selectedRows.clear();
      selectedRows.addAll(List<bool>.filled(filteredArtists.length, false));
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
        selectedTab: 'アーティスト', // ハードコード
        onTabSelected: (tab) {
          // タブ遷移処理はBottomAdminLayoutで行う
          // ここでは何もしない
        },
        showTabs: true,
        mainContent: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchArea(),
              const SizedBox(height: 24),
              filteredArtists.isEmpty ? _buildNoArtistsFound() : _buildTable(),
              if (filteredArtists.isNotEmpty) ...[
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
              Expanded(flex: 2, child: _buildTextField('アーティスト名', nameController)),
              const SizedBox(width: 12),
              Expanded(flex: 1, child: _buildTextField('国', countryController)),
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
                    countryController.clear();
                    statusFilter = 'すべて';
                    startDate = null;
                    endDate = null;
                    filteredArtists = List.from(artists);
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
        3: FlexColumnWidth(1),
        4: FlexColumnWidth(1.5),
        5: FlexColumnWidth(1),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.grey[50]),
          children: [
            _buildTableHeader('✓'),
            _buildTableHeader('ID'),
            _buildTableHeader('アーティスト名'),
            _buildTableHeader('国'),
            _buildTableHeader('ジャンル'),
            _buildTableHeader('状態'),
          ],
        ),
        ...List.generate(filteredArtists.length, (index) {
          final artist = filteredArtists[index];
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
                Text(artist['id'], style: const TextStyle(fontSize: 14)),
              ),
              _buildTableCell(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(artist['name'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    if (artist['description'] != null && artist['description'].toString().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          artist['description'],
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              _buildTableCell(
                Text(artist['country'], style: const TextStyle(fontSize: 14)),
              ),
              _buildTableCell(
                Text(artist['genre'], style: const TextStyle(fontSize: 14)),
              ),
              _buildTableCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: artist['isActive'] ? Colors.green[100] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    artist['status'],
                    style: TextStyle(
                      fontSize: 12,
                      color: artist['isActive'] ? Colors.green[800] : Colors.grey[800],
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

  Widget _buildNoArtistsFound() {
    return Container(
      height: 300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '該当アーティストが見つかりません',
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
            child: const Text('選択中のアーティストを無効化', style: TextStyle(fontSize: 14)),
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
            child: const Text('選択中のアーティストを有効化', style: TextStyle(fontSize: 14)),
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