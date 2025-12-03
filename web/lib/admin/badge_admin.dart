import 'package:flutter/material.dart';
import 'bottom_admin.dart';
import 'user_list_admin.dart';
import 'contact_list_admin.dart';

class BadgeAdmin extends StatefulWidget {
  const BadgeAdmin({Key? key}) : super(key: key);

  @override
  State<BadgeAdmin> createState() => _BadgeAdminState();
}

class _BadgeAdminState extends State<BadgeAdmin> {
  String selectedMenu = 'コンテンツ管理';
  final List<bool> selectedRows = [];
  
  // 検索用のコントローラー
  final TextEditingController idController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController typeController = TextEditingController();

  String statusFilter = 'すべて';
  DateTime? startDate;
  DateTime? endDate;

  bool get hasSelection => selectedRows.any((selected) => selected);

  // サンプルデータ
  List<Map<String, dynamic>> badges = [
    {
      'id': 'B001',
      'name': '初めての単語学習',
      'description': '最初の単語を学習した',
      'type': '学習',
      'icon': '🎯',
      'status': '有効',
      'isActive': true,
      'addedDate': DateTime(2024, 11, 1),
      'requirement': '1単語学習',
      'userCount': 1250,
      'createdAt': '2024/11/01 10:00:00',
      'updatedAt': '2024/11/01 10:00:00',
    },
    {
      'id': 'B002',
      'name': '単語マスター',
      'description': '100単語を学習した',
      'type': '学習',
      'icon': '🏆',
      'status': '有効',
      'isActive': true,
      'addedDate': DateTime(2024, 11, 15),
      'requirement': '100単語学習',
      'userCount': 780,
      'createdAt': '2024/11/15 14:30:00',
      'updatedAt': '2024/11/15 14:30:00',
    },
    {
      'id': 'B003',
      'name': '連続ログイン',
      'description': '7日連続でログインした',
      'type': '継続',
      'icon': '🔥',
      'status': '有効',
      'isActive': true,
      'addedDate': DateTime(2024, 11, 20),
      'requirement': '7日連続ログイン',
      'userCount': 920,
      'createdAt': '2024/11/20 09:15:00',
      'updatedAt': '2024/11/20 09:15:00',
    },
    {
      'id': 'B004',
      'name': '完璧な発音',
      'description': '発音練習で満点を取った',
      'type': 'スキル',
      'icon': '⭐',
      'status': '無効',
      'isActive': false,
      'addedDate': DateTime(2024, 11, 25),
      'requirement': '発音テスト100点',
      'userCount': 450,
      'createdAt': '2024/11/25 16:45:00',
      'updatedAt': '2024/11/25 16:45:00',
    },
    {
      'id': 'B005',
      'name': 'コミュニティリーダー',
      'description': 'フォロワーが100人を超えた',
      'type': 'ソーシャル',
      'icon': '👑',
      'status': '有効',
      'isActive': true,
      'addedDate': DateTime(2024, 12, 1),
      'requirement': 'フォロワー100人以上',
      'userCount': 120,
      'createdAt': '2024/12/01 11:20:00',
      'updatedAt': '2024/12/01 11:20:00',
    },
  ];

  List<Map<String, dynamic>> filteredBadges = [];
  
  @override
  void initState() {
    super.initState();
    filteredBadges = List.from(badges);
    _updateSelectedRows();
  }

  void _updateSelectedRows() {
    selectedRows.clear();
    selectedRows.addAll(List<bool>.filled(filteredBadges.length, false));
  }

  void _applyFilter() {
    final idQuery = idController.text.trim();
    final nameQuery = nameController.text.trim().toLowerCase();
    final typeQuery = typeController.text.trim();

    setState(() {
      filteredBadges = badges.where((b) {
        final matchesId = idQuery.isEmpty || b['id'].contains(idQuery);
        final matchesName = nameQuery.isEmpty || b['name'].toLowerCase().contains(nameQuery);
        final matchesType = typeQuery.isEmpty || b['type'].contains(typeQuery);
        final matchesStatus = statusFilter == 'すべて' || b['status'] == statusFilter;
        
        bool matchesDate = true;
        if (startDate != null && endDate != null) {
          final addedDate = b['addedDate'] as DateTime;
          matchesDate = addedDate.isAfter(startDate!.subtract(const Duration(days: 1))) &&
                       addedDate.isBefore(endDate!.add(const Duration(days: 1)));
        }
        
        return matchesId && matchesName && matchesType && matchesStatus && matchesDate;
      }).toList();
      _updateSelectedRows();
    });
  }

  void _deactivateSelected() {
    setState(() {
      for (int i = 0; i < selectedRows.length; i++) {
        if (selectedRows[i]) {
          final badgeId = filteredBadges[i]['id'];
          final originalIndex = badges.indexWhere((b) => b['id'] == badgeId);
          if (originalIndex != -1) {
            badges[originalIndex]['status'] = '無効';
            badges[originalIndex]['isActive'] = false;
          }
          filteredBadges[i]['status'] = '無効';
          filteredBadges[i]['isActive'] = false;
        }
      }
      selectedRows.clear();
      selectedRows.addAll(List<bool>.filled(filteredBadges.length, false));
    });
  }

  void _activateSelected() {
    setState(() {
      for (int i = 0; i < selectedRows.length; i++) {
        if (selectedRows[i]) {
          final badgeId = filteredBadges[i]['id'];
          final originalIndex = badges.indexWhere((b) => b['id'] == badgeId);
          if (originalIndex != -1) {
            badges[originalIndex]['status'] = '有効';
            badges[originalIndex]['isActive'] = true;
          }
          filteredBadges[i]['status'] = '有効';
          filteredBadges[i]['isActive'] = true;
        }
      }
      selectedRows.clear();
      selectedRows.addAll(List<bool>.filled(filteredBadges.length, false));
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
        selectedTab: 'バッジ', // ハードコード
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
              filteredBadges.isEmpty ? _buildNoBadgesFound() : _buildTable(),
              if (filteredBadges.isNotEmpty) ...[
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
              Expanded(flex: 2, child: _buildTextField('バッジ名', nameController)),
              const SizedBox(width: 12),
              Expanded(flex: 1, child: _buildTextField('タイプ', typeController)),
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
                    typeController.clear();
                    statusFilter = 'すべて';
                    startDate = null;
                    endDate = null;
                    filteredBadges = List.from(badges);
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
        3: FlexColumnWidth(1.2),
        4: FlexColumnWidth(1.5),
        5: FlexColumnWidth(1.2),
        6: FlexColumnWidth(1),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.grey[50]),
          children: [
            _buildTableHeader('✓'),
            _buildTableHeader('ID'),
            _buildTableHeader('バッジ名'),
            _buildTableHeader('タイプ'),
            _buildTableHeader('条件'),
            _buildTableHeader('獲得者数'),
            _buildTableHeader('状態'),
          ],
        ),
        ...List.generate(filteredBadges.length, (index) {
          final badge = filteredBadges[index];
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
                Text(badge['id'], style: const TextStyle(fontSize: 14)),
              ),
              _buildTableCell(
                Row(
                  children: [
                    Text(badge['icon'], style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(badge['name'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                          if (badge['description'] != null && badge['description'].toString().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                badge['description'],
                                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              _buildTableCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getTypeColor(badge['type']),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badge['type'],
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              _buildTableCell(
                Text(
                  badge['requirement'],
                  style: const TextStyle(fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _buildTableCell(
                Text(
                  '${badge['userCount']}人',
                  style: const TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
              _buildTableCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: badge['isActive'] ? Colors.green[100] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badge['status'],
                    style: TextStyle(
                      fontSize: 12,
                      color: badge['isActive'] ? Colors.green[800] : Colors.grey[800],
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

  Color _getTypeColor(String type) {
    switch (type) {
      case '学習':
        return Colors.blue;
      case '継続':
        return Colors.orange;
      case 'スキル':
        return Colors.purple;
      case 'ソーシャル':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _buildNoBadgesFound() {
    return Container(
      height: 300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '該当バッジが見つかりません',
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
            child: const Text('選択中のバッジを無効化', style: TextStyle(fontSize: 14)),
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
            child: const Text('選択中のバッジを有効化', style: TextStyle(fontSize: 14)),
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