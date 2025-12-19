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
  
  List<Badge> badges = [];
  List<Badge> filteredBadges = [];
  List<bool> selectedRows = [];
  bool hasSelection = false;

  // 検索条件
  String idSearch = '';
  String nameSearch = '';
  String conditionSearch = '';
  String? modeFilter;
  String? statusFilter;
  DateTime? addedStart;
  DateTime? addedEnd;

  @override
  void initState() {
    super.initState();
    _loadSampleData();
  }

  void _loadSampleData() {
    badges = [
      Badge(
        id: '00001',
        name: 'バッジ01',
        mode: '対戦',
        condition: '初めて勝利する',
        status: '有効',
        isActive: true,
        addedDate: DateTime(2024, 1, 1),
        updatedDate: DateTime(2024, 1, 1),
      ),
      Badge(
        id: '00002',
        name: 'バッジ02',
        mode: '対戦',
        condition: '10回勝利する',
        status: '有効',
        isActive: true,
        addedDate: DateTime(2024, 1, 15),
        updatedDate: DateTime(2024, 1, 15),
      ),
      Badge(
        id: '00003',
        name: 'バッジ03',
        mode: 'スラングアカウント',
        condition: '初めて全問正解する',
        status: '有効',
        isActive: true,
        addedDate: DateTime(2024, 2, 1),
        updatedDate: DateTime(2024, 2, 1),
      ),
      Badge(
        id: '00004',
        name: 'バッジ04',
        mode: 'スラングアカウント',
        condition: '10回全問正解する',
        status: '無効',
        isActive: false,
        addedDate: DateTime(2024, 2, 15),
        updatedDate: DateTime(2024, 2, 15),
      ),
      Badge(
        id: '00005',
        name: 'マスターリーダー',
        mode: '楽曲',
        condition: '100曲クリアする',
        status: '有効',
        isActive: true,
        addedDate: DateTime(2024, 3, 1),
        updatedDate: DateTime(2024, 3, 1),
      ),
      Badge(
        id: '00006',
        name: '単語マスター',
        mode: '単語',
        condition: '500単語習得する',
        status: '無効',
        isActive: false,
        addedDate: DateTime(2024, 3, 15),
        updatedDate: DateTime(2024, 3, 15),
      ),
    ];
    filteredBadges = List.from(badges);
    selectedRows = List.generate(filteredBadges.length, (index) => false);
  }

  void _searchBadges() {
    setState(() {
      filteredBadges = badges.where((badge) {
        bool matches = true;

        if (idSearch.isNotEmpty && !badge.id.contains(idSearch)) {
          matches = false;
        }
        if (nameSearch.isNotEmpty && !badge.name.contains(nameSearch)) {
          matches = false;
        }
        if (conditionSearch.isNotEmpty && !badge.condition.contains(conditionSearch)) {
          matches = false;
        }
        if (modeFilter != null && badge.mode != modeFilter) {
          matches = false;
        }
        if (statusFilter != null && badge.status != statusFilter) {
          matches = false;
        }

        // 追加日フィルター
        if (addedStart != null && addedEnd != null) {
          final isWithinRange = badge.addedDate.isAfter(addedStart!.subtract(const Duration(days: 1))) &&
                               badge.addedDate.isBefore(addedEnd!.add(const Duration(days: 1)));
          if (!isWithinRange) {
            matches = false;
          }
        }

        return matches;
      }).toList();

      selectedRows = List.generate(filteredBadges.length, (index) => false);
      _updateSelectionState();
    });
  }

  void _clearSearch() {
    setState(() {
      idSearch = '';
      nameSearch = '';
      conditionSearch = '';
      modeFilter = null;
      statusFilter = null;
      addedStart = null;
      addedEnd = null;

      filteredBadges = List.from(badges);
      selectedRows = List.generate(filteredBadges.length, (index) => false);
      _updateSelectionState();
    });
  }

  void _toggleAllSelection(bool? value) {
    setState(() {
      if (value == true) {
        selectedRows = List.generate(filteredBadges.length, (index) => true);
      } else {
        selectedRows = List.generate(filteredBadges.length, (index) => false);
      }
      _updateSelectionState();
    });
  }

  void _toggleBadgeSelection(int index, bool? value) {
    setState(() {
      selectedRows[index] = value ?? false;
      _updateSelectionState();
    });
  }

  void _updateSelectionState() {
    setState(() {
      hasSelection = selectedRows.any((selected) => selected);
    });
  }

  void _deactivateSelected() {
    setState(() {
      for (int i = 0; i < selectedRows.length; i++) {
        if (selectedRows[i]) {
          final badgeId = filteredBadges[i].id;
          final originalIndex = badges.indexWhere((b) => b.id == badgeId);
          if (originalIndex != -1) {
            badges[originalIndex] = badges[originalIndex].copyWith(
              status: '無効',
              isActive: false,
              updatedDate: DateTime.now(),
            );
          }
          filteredBadges[i] = filteredBadges[i].copyWith(
            status: '無効',
            isActive: false,
            updatedDate: DateTime.now(),
          );
        }
      }
      _updateSelectionState();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('選択したバッジを無効化しました')),
    );
  }

  void _activateSelected() {
    setState(() {
      for (int i = 0; i < selectedRows.length; i++) {
        if (selectedRows[i]) {
          final badgeId = filteredBadges[i].id;
          final originalIndex = badges.indexWhere((b) => b.id == badgeId);
          if (originalIndex != -1) {
            badges[originalIndex] = badges[originalIndex].copyWith(
              status: '有効',
              isActive: true,
              updatedDate: DateTime.now(),
            );
          }
          filteredBadges[i] = filteredBadges[i].copyWith(
            status: '有効',
            isActive: true,
            updatedDate: DateTime.now(),
          );
        }
      }
      _updateSelectionState();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('選択したバッジを有効化しました')),
    );
  }

  Future<void> _navigateToDetailPage(Badge badge, {bool isNew = false}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BadgeDetailAdmin(
          badge: badge,
          isNew: isNew,
          onStatusChanged: (updatedBadge, action) {
            // 状態変更を即時反映
            _handleBadgeUpdate(updatedBadge, action);
          },
        ),
      ),
    );

    if (result != null) {
      _handleBadgeUpdate(result['badge'] as Badge, result['action']);
    }
  }

  void _handleBadgeUpdate(Badge updatedBadge, String action) {
    setState(() {
      switch (action) {
        case 'save':
          if (badges.any((b) => b.id == updatedBadge.id)) {
            // 既存のバッジを更新
            final index = badges.indexWhere((b) => b.id == updatedBadge.id);
            if (index != -1) {
              badges[index] = updatedBadge;
            }
          } else {
            // 新規バッジを追加
            badges.add(updatedBadge);
          }
          break;
        case 'delete':
          // バッジを削除
          badges.removeWhere((b) => b.id == updatedBadge.id);
          break;
        case 'status_changed':
          // 状態変更のみ
          final index = badges.indexWhere((b) => b.id == updatedBadge.id);
          if (index != -1) {
            badges[index] = updatedBadge;
          }
          break;
      }

      // フィルター適用
      filteredBadges = badges.where((badge) {
        bool matches = true;

        if (idSearch.isNotEmpty && !badge.id.contains(idSearch)) {
          matches = false;
        }
        if (nameSearch.isNotEmpty && !badge.name.contains(nameSearch)) {
          matches = false;
        }
        if (conditionSearch.isNotEmpty && !badge.condition.contains(conditionSearch)) {
          matches = false;
        }
        if (modeFilter != null && badge.mode != modeFilter) {
          matches = false;
        }
        if (statusFilter != null && badge.status != statusFilter) {
          matches = false;
        }

        if (addedStart != null && addedEnd != null) {
          final isWithinRange = badge.addedDate.isAfter(addedStart!.subtract(const Duration(days: 1))) &&
                               badge.addedDate.isBefore(addedEnd!.add(const Duration(days: 1)));
          if (!isWithinRange) {
            matches = false;
          }
        }

        return matches;
      }).toList();

      selectedRows = List.generate(filteredBadges.length, (index) => false);
      _updateSelectionState();

      // スナックバー表示
      String message = '';
      switch (action) {
        case 'save':
          message = 'バッジを保存しました';
          break;
        case 'delete':
          message = 'バッジを削除しました';
          break;
        case 'status_changed':
          message = '状態を変更しました';
          break;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    });
  }

  // バッジ登録ダイアログを表示
  void _showTourokuDialog() {
    showTourokuDialog(
      context,
      'badge',
      (data) {
        final newBadge = Badge(
          id: '${(badges.length + 1).toString().padLeft(5, '0')}',
          name: data['name'],
          mode: data['mode'],
          condition: data['condition'],
          status: '有効',
          isActive: true,
          addedDate: DateTime.now(),
        );

        badges.add(newBadge);
        filteredBadges = List.from(badges);
        selectedRows = List.generate(filteredBadges.length, (index) => false);
        _updateSelectionState();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('バッジを登録しました')),
        );
      },
    );
  }

  Widget _buildStatusIndicator(String status) {
    final isActive = status == '有効';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.green[100] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          color: isActive ? Colors.green[800] : Colors.grey[800],
        ),
      ),
    );
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
        // 検索条件エリア
        _buildVerticalSearchArea(),
        const SizedBox(height: 16),
        
        // バッジ一覧テーブル
        Expanded(
          child: _buildBadgeTable(),
        ),
      ],
    );
  }

  Widget _buildVerticalSearchArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
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
                      _buildVerticalSearchField('ID', (value) => idSearch = value),
                      const SizedBox(height: 16),
                      _buildVerticalSearchField('バッジ名', (value) => nameSearch = value),
                      const SizedBox(height: 16),
                      _buildVerticalSearchField('取得条件', (value) => conditionSearch = value),
                    ],
                  ),
                ),
                const SizedBox(width: 32),
                
                // 2列目
                Expanded(
                  child: Column(
                    children: [
                      _buildVerticalDropdown('モード', ['全て', '対戦', 'スラングアカウント', '楽曲', '単語', '問題', 'アーティスト'], (value) => modeFilter = value),
                      const SizedBox(height: 16),
                      _buildVerticalDropdown('状態', ['全て', '有効', '無効'], (value) => statusFilter = value),
                      const SizedBox(height: 16),
                      _buildVerticalDateField(
                        '追加日',
                        (date) => addedStart = date,
                        (date) => addedEnd = date,
                        addedStart,
                        addedEnd,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                
                // 3列目
                Expanded(
                  child: Column(
                    children: [
                      // ボタンエリア
                      Container(
                        padding: const EdgeInsets.only(top: 100),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              width: 100,
                              child: OutlinedButton(
                                onPressed: _clearSearch,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.grey[700],
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: const Text('クリア', style: TextStyle(color: Colors.black)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 100,
                              child: ElevatedButton(
                                onPressed: _searchBadges,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue[700],
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: const Text('検索', style: TextStyle(color: Colors.white)),
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

  Widget _buildVerticalSearchField(String label, Function(String) onChanged) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 80,
          padding: const EdgeInsets.only(top: 12),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            decoration: const InputDecoration(
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

  Widget _buildVerticalDateField(
    String label,
    Function(DateTime?) onStartChanged,
    Function(DateTime?) onEndChanged,
    DateTime? startDate,
    DateTime? endDate,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 80,
          padding: const EdgeInsets.only(top: 12),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: startDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (date != null) {
                          onStartChanged(date);
                          setState(() {});
                        }
                      },
                      child: Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[400]!),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Text(
                              startDate != null
                                  ? '${startDate!.year}/${startDate!.month.toString().padLeft(2, '0')}/${startDate!.day.toString().padLeft(2, '0')}'
                                  : '',
                              style: TextStyle(
                                color: startDate != null
                                    ? Colors.black
                                    : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '〜',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: endDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (date != null) {
                          onEndChanged(date);
                          setState(() {});
                        }
                      },
                      child: Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[400]!),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Text(
                              endDate != null
                                  ? '${endDate!.year}/${endDate!.month.toString().padLeft(2, '0')}/${endDate!.day.toString().padLeft(2, '0')}'
                                  : '',
                              style: TextStyle(
                                color: endDate != null
                                    ? Colors.black
                                    : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDropdown(
      String label, List<String> options, Function(String?) onChanged) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 80,
          padding: const EdgeInsets.only(top: 12),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 8),
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

  Widget _buildBadgeTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          // テーブルヘッダー
          if (filteredBadges.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  _buildTableHeader('', 1),
                  _buildTableHeader('ID', 1),
                  _buildTableHeader('バッジ名', 2),
                  _buildTableHeader('モード', 1),
                  _buildTableHeader('取得条件', 3),
                  _buildTableHeader('状態', 1),
                ],
              ),
            ),
          
          // テーブルデータまたは該当なしメッセージ
          Expanded(
            child: filteredBadges.isEmpty
                ? _buildNoBadgesFound()
                : ListView.builder(
                    itemCount: filteredBadges.length,
                    itemBuilder: (context, index) {
                      final badge = filteredBadges[index];
                      return Container(
                        decoration: BoxDecoration(
                          border: Border(
                            left: const BorderSide(color: Colors.grey),
                            right: const BorderSide(color: Colors.grey),
                            bottom: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        child: InkWell(
                          onTap: () => _navigateToDetailPage(badge),
                          child: Row(
                            children: [
                              _buildTableCell(
                                '',
                                1,
                                TextAlign.center,
                                child: Checkbox(
                                  value: selectedRows[index],
                                  onChanged: (value) => _toggleBadgeSelection(index, value),
                                ),
                              ),
                              _buildTableCell(badge.id, 1, TextAlign.center),
                              _buildTableCell(badge.name, 2, TextAlign.left),
                              _buildTableCell(badge.mode, 1, TextAlign.center),
                              _buildTableCell(badge.condition, 3, TextAlign.left),
                              _buildTableCell('', 1, TextAlign.center, 
                                child: _buildStatusIndicator(badge.status)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          
          // 全てのボタンを同じ行に表示
          _buildButtonsArea(),
        ],
      ),
    );
  }

  Widget _buildNoBadgesFound() {
    return Center(
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
    );
  }

  Widget _buildButtonsArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // 選択中のバッジを無効化ボタン
          if (hasSelection)
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(2, 2),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _deactivateSelected,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: const Text('選択中のバッジを無効化', style: TextStyle(color: Colors.white)),
              ),
            ),
          
          // 選択中のバッジを有効化ボタン
          if (hasSelection)
            Container(
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(2, 2),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _activateSelected,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: const Text('選択中のバッジを有効化', style: TextStyle(color: Colors.white)),
              ),
            ),
          
          // バッジ登録ボタン
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(2, 2),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _showTourokuDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: const Text('追加作成', style: TextStyle(color: Colors.white)),
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
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          border: Border(right: BorderSide(color: Colors.grey[300]!)),
        ),
        child: text.isEmpty
            ? Checkbox(
                value: selectedRows.every((element) => element) &&
                    selectedRows.isNotEmpty,
                onChanged: _toggleAllSelection,
              )
            : Text(
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

  Widget _buildTableCell(String text, int flex, TextAlign align,
      {Widget? child}) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          border: Border(right: BorderSide(color: Colors.grey[300]!)),
        ),
        child: child ??
            Text(
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