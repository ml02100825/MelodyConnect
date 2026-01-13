import 'package:flutter/material.dart';
import 'bottom_admin.dart';
import 'badge_detail_admin.dart';
import 'touroku_admin.dart';

class Badge {
  final String id;
  final String name;
  final String mode;
  final String condition;
  final String status;
  final bool isActive;
  final DateTime addedDate;
  final DateTime? updatedDate;

  Badge({
    required this.id,
    required this.name,
    required this.mode,
    required this.condition,
    required this.status,
    required this.isActive,
    required this.addedDate,
    this.updatedDate,
  });

  Badge copyWith({
    String? id,
    String? name,
    String? mode,
    String? condition,
    String? status,
    bool? isActive,
    DateTime? addedDate,
    DateTime? updatedDate,
  }) {
    return Badge(
      id: id ?? this.id,
      name: name ?? this.name,
      mode: mode ?? this.mode,
      condition: condition ?? this.condition,
      status: status ?? this.status,
      isActive: isActive ?? this.isActive,
      addedDate: addedDate ?? this.addedDate,
      updatedDate: updatedDate ?? this.updatedDate,
    );
  }
}

class BadgeAdmin extends StatefulWidget {
  const BadgeAdmin({Key? key}) : super(key: key);

  @override
  State<BadgeAdmin> createState() => _BadgeAdminState();
}

class _BadgeAdminState extends State<BadgeAdmin> {
  String selectedTab = 'バッジ';
  String selectedMenu = 'コンテンツ管理';
  final List<bool> selectedRows = List.generate(15, (index) => false);

  final TextEditingController idController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController conditionController = TextEditingController();

  String modeFilter = 'モード';
  String statusFilter = '状態';
  DateTime? startDate;
  DateTime? endDate;

  bool get hasSelection => selectedRows.any((selected) => selected);

  List<Map<String, dynamic>> badges = [
    {
      'id': '00001',
      'name': 'バッジ01',
      'mode': '対戦',
      'condition': '初めて勝利する',
      'status': '有効',
      'addedDate': DateTime(2024, 1, 1),
    },
    {
      'id': '00002',
      'name': 'バッジ02',
      'mode': '対戦',
      'condition': '10回勝利する',
      'status': '有効',
      'addedDate': DateTime(2024, 1, 15),
    },
    {
      'id': '00003',
      'name': 'バッジ03',
      'mode': 'スラングアカウント',
      'condition': '初めて全問正解する',
      'status': '有効',
      'addedDate': DateTime(2024, 2, 1),
    },
    {
      'id': '00004',
      'name': 'バッジ04',
      'mode': 'スラングアカウント',
      'condition': '10回全問正解する',
      'status': '無効',
      'addedDate': DateTime(2024, 2, 15),
    },
    {
      'id': '00005',
      'name': 'マスターリーダー',
      'mode': '楽曲',
      'condition': '100曲クリアする',
      'status': '有効',
      'addedDate': DateTime(2024, 3, 1),
    },
    {
      'id': '00006',
      'name': '単語マスター',
      'mode': '単語',
      'condition': '500単語習得する',
      'status': '無効',
      'addedDate': DateTime(2024, 3, 15),
    },
  ];

  List<Map<String, dynamic>> filteredBadges = [];

  @override
  void initState() {
    super.initState();
    filteredBadges = List.from(badges);
  }

  void _applyFilter() {
    final idQuery = idController.text.trim();
    final nameQuery = nameController.text.trim().toLowerCase();
    final conditionQuery = conditionController.text.trim().toLowerCase();

    setState(() {
      filteredBadges = badges.where((b) {
        final matchesId = idQuery.isEmpty || b['id'].contains(idQuery);
        final matchesName = nameQuery.isEmpty || 
                           b['name'].toLowerCase().contains(nameQuery);
        final matchesCondition = conditionQuery.isEmpty || 
                                 b['condition'].toLowerCase().contains(conditionQuery);
        final matchesMode = modeFilter == 'モード' || b['mode'] == modeFilter;
        final matchesStatus = statusFilter == '状態' || b['status'] == statusFilter;
        
        bool matchesDate = true;
        if (startDate != null && endDate != null) {
          final addedDate = b['addedDate'] as DateTime;
          matchesDate = addedDate.isAfter(startDate!.subtract(const Duration(days: 1))) &&
                       addedDate.isBefore(endDate!.add(const Duration(days: 1)));
        }
        
        return matchesId && matchesName && matchesCondition && matchesMode && matchesStatus && matchesDate;
      }).toList();
    });
  }

  void _deactivateSelected() {
    setState(() {
      for (int i = 0; i < selectedRows.length; i++) {
        if (selectedRows[i] && i < filteredBadges.length) {
          final badgeId = filteredBadges[i]['id'];
          final originalIndex = badges.indexWhere((b) => b['id'] == badgeId);
          if (originalIndex != -1) {
            badges[originalIndex]['status'] = '無効';
          }
          filteredBadges[i]['status'] = '無効';
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
        if (selectedRows[i] && i < filteredBadges.length) {
          final badgeId = filteredBadges[i]['id'];
          final originalIndex = badges.indexWhere((b) => b['id'] == badgeId);
          if (originalIndex != -1) {
            badges[originalIndex]['status'] = '有効';
          }
          filteredBadges[i]['status'] = '有効';
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
        Expanded(child: _buildDataList()),
        const SizedBox(height: 16),
        _buildActionButton(),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 1, child: _buildCompactTextField('ID', idController)),
              const SizedBox(width: 12),
              Expanded(flex: 1, child: _buildCompactDropdown('モード', modeFilter, 
                ['モード', '対戦', 'スラングアカウント', '楽曲', '単語', '問題', 'アーティスト'], (value) {
                setState(() {
                  modeFilter = value ?? 'モード';
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
              Expanded(flex: 1, child: _buildCompactTextField('バッジ名', nameController)),
              const SizedBox(width: 12),
              Expanded(flex: 1, child: _buildCompactDropdown('状態', statusFilter, 
                ['状態', '有効', '無効'], (value) {
                setState(() {
                  statusFilter = value ?? '状態';
                });
              })),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: _buildCompactTextField('取得条件', conditionController)),
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
                    nameController.clear();
                    conditionController.clear();
                    modeFilter = 'モード';
                    statusFilter = '状態';
                    startDate = null;
                    endDate = null;
                    filteredBadges = List.from(badges);
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
              borderRadius: BorderRadius.circular(2),
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
                    value: selectedRows.take(filteredBadges.length).every((selected) => selected) && 
                           filteredBadges.isNotEmpty,
                    onChanged: (value) {
                      setState(() {
                        for (int i = 0; i < filteredBadges.length; i++) {
                          selectedRows[i] = value ?? false;
                        }
                      });
                    },
                  ),
                ),
                _buildListHeader('ID', 80),
                _buildListHeader('バッジ名', 150),
                _buildListHeader('モード', 100),
                _buildListHeader('取得条件', 200),
                _buildListHeader('状態', 80),
              ],
            ),
          ),
          // データ行
          Expanded(
            child: ListView.builder(
              itemCount: filteredBadges.length,
              itemBuilder: (context, index) {
                final badge = filteredBadges[index];
                return Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
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
                        Text(badge['id'], style: const TextStyle(fontSize: 13), textAlign: TextAlign.center),
                        80,
                      ),
                      _buildListCell(
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BadgeDetailAdmin(
                                  badge: Badge(
                                    id: badge['id'],
                                    name: badge['name'],
                                    mode: badge['mode'],
                                    condition: badge['condition'],
                                    status: badge['status'],
                                    isActive: badge['status'] == '有効',
                                    addedDate: badge['addedDate'],
                                  ),
                                ),
                              ),
                            );
                          },
                          child: Text(
                            badge['name'],
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.left,
                          ),
                        ),
                        150,
                      ),
                      _buildListCell(
                        Text(badge['mode'], style: const TextStyle(fontSize: 13), textAlign: TextAlign.center),
                        100,
                      ),
                      _buildListCell(
                        Text(
                          badge['condition'],
                          style: const TextStyle(fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                        200,
                      ),
                      _buildListCell(
                        Text(
                          badge['status'],
                          style: TextStyle(
                            fontSize: 13,
                            color: badge['status'] == '有効' ? Colors.black : Colors.grey[400],
                          ),
                          textAlign: TextAlign.center,
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
            child: const Text('選択中のバッジを無効化', style: TextStyle(fontSize: 14)),
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
            child: const Text('選択中のバッジを有効化', style: TextStyle(fontSize: 14)),
          ),
          const SizedBox(width: 12),
        ],
        ElevatedButton(
          onPressed: () {
            showTourokuDialog(
              context,
              'badge',
              (data) {
                setState(() {
                  final newId = '${(badges.length + 1).toString().padLeft(5, '0')}';
                  data['id'] = newId;
                  data['addedDate'] = DateTime.now();
                  badges.add(data);
                  filteredBadges = List.from(badges);
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