import 'package:flutter/material.dart';
import 'bottom_admin.dart';
import 'badge_detail_admin.dart';
import 'touroku_admin.dart';
import 'services/admin_api_service.dart';

class Badge {
  final String id;
  final String name;
  final String mode;
  final String condition;
  final String status;
  final bool isActive;
  final DateTime addedDate;
  final DateTime? updatedDate;
  final int numericId;

  Badge({
    required this.id,
    required this.name,
    required this.mode,
    required this.condition,
    required this.status,
    required this.isActive,
    required this.addedDate,
    this.updatedDate,
    required this.numericId,
  });

  factory Badge.fromJson(Map<String, dynamic> json) {
    return Badge(
      id: json['id']?.toString() ?? '',
      name: json['badgename'] ?? '',
      mode: json['mode'] ?? '',
      condition: json['acquisitionConditions'] ?? '',
      status: (json['isActive'] == true) ? '有効' : '無効',
      isActive: json['isActive'] == true,
      addedDate: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      updatedDate: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
      numericId: json['id'] as int? ?? 0,
    );
  }

  Badge copyWith({
    String? id,
    String? name,
    String? mode,
    String? condition,
    String? status,
    bool? isActive,
    DateTime? addedDate,
    DateTime? updatedDate,
    int? numericId,
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
      numericId: numericId ?? this.numericId,
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
  List<bool> selectedRows = [];

  final TextEditingController idController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController conditionController = TextEditingController();

  String modeFilter = 'モード';
  String statusFilter = '状態';
  DateTime? startDate;
  DateTime? endDate;

  bool get hasSelection => selectedRows.any((selected) => selected);

  // API連携用
  List<Badge> badges = [];
  int _currentPage = 0;
  int _totalPages = 1;
  int _totalElements = 0;
  final int _pageSize = 20;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFromApi();
  }

  Future<void> _loadFromApi() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      bool? isActive;
      if (statusFilter == '有効') {
        isActive = true;
      } else if (statusFilter == '無効') {
        isActive = false;
      }

      final response = await AdminApiService.getBadges(
        page: _currentPage,
        size: _pageSize,
        badgeName: nameController.text.trim().isNotEmpty ? nameController.text.trim() : null,
        isActive: isActive,
      );

      final content = response['content'] as List<dynamic>? ?? [];
      final loadedBadges = content.map((json) => Badge.fromJson(json)).toList();

      setState(() {
        badges = loadedBadges;
        _totalPages = response['totalPages'] ?? 1;
        _totalElements = response['totalElements'] ?? 0;
        selectedRows = List.generate(badges.length, (index) => false);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'データの取得に失敗しました: $e';
        _isLoading = false;
      });
    }
  }

  void _applyFilter() {
    _currentPage = 0;
    _loadFromApi();
  }

  void _clearFilter() {
    setState(() {
      idController.clear();
      nameController.clear();
      conditionController.clear();
      modeFilter = 'モード';
      statusFilter = '状態';
      startDate = null;
      endDate = null;
    });
    _currentPage = 0;
    _loadFromApi();
  }

  void _goToPage(int page) {
    if (page >= 0 && page < _totalPages) {
      setState(() {
        _currentPage = page;
      });
      _loadFromApi();
    }
  }

  Future<void> _deactivateSelected() async {
    final selectedIds = <int>[];
    for (int i = 0; i < selectedRows.length; i++) {
      if (selectedRows[i] && i < badges.length) {
        selectedIds.add(badges[i].numericId);
      }
    }

    if (selectedIds.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await AdminApiService.disableBadges(selectedIds);
      await _loadFromApi();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('選択したバッジを無効化しました')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('無効化に失敗しました: $e')),
        );
      }
    }
  }

  Future<void> _activateSelected() async {
    final selectedIds = <int>[];
    for (int i = 0; i < selectedRows.length; i++) {
      if (selectedRows[i] && i < badges.length) {
        selectedIds.add(badges[i].numericId);
      }
    }

    if (selectedIds.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await AdminApiService.enableBadges(selectedIds);
      await _loadFromApi();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('選択したバッジを有効化しました')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('有効化に失敗しました: $e')),
        );
      }
    }
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
        _buildPagination(),
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
                onPressed: _clearFilter,
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
                    value: selectedRows.isNotEmpty &&
                           selectedRows.every((selected) => selected) &&
                           badges.isNotEmpty,
                    onChanged: (value) {
                      setState(() {
                        for (int i = 0; i < selectedRows.length; i++) {
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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildErrorView()
                    : badges.isEmpty
                        ? _buildNoDataFound()
                        : ListView.builder(
                            itemCount: badges.length,
                            itemBuilder: (context, index) {
                              final badge = badges[index];
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
                                      Text(badge.id, style: const TextStyle(fontSize: 13), textAlign: TextAlign.center),
                                      80,
                                    ),
                                    _buildListCell(
                                      GestureDetector(
                                        onTap: () async {
                                          final result = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => BadgeDetailAdmin(
                                                badge: badge,
                                              ),
                                            ),
                                          );
                                          if (result != null) {
                                            _loadFromApi();
                                          }
                                        },
                                        child: Text(
                                          badge.name,
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
                                      Text(badge.mode, style: const TextStyle(fontSize: 13), textAlign: TextAlign.center),
                                      100,
                                    ),
                                    _buildListCell(
                                      Text(
                                        badge.condition,
                                        style: const TextStyle(fontSize: 13),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                      ),
                                      200,
                                    ),
                                    _buildListCell(
                                      Text(
                                        badge.status,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: badge.status == '有効' ? Colors.black : Colors.grey[400],
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

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
            const SizedBox(height: 12),
            Text(
              'エラーが発生しました',
              style: TextStyle(
                fontSize: 14,
                color: Colors.red[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? '',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadFromApi,
              child: const Text('再試行'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataFound() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              '該当するバッジが見つかりません',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '検索条件を変更して再度お試しください',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '全 $_totalElements 件',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.first_page),
                onPressed: _currentPage > 0 ? () => _goToPage(0) : null,
                iconSize: 20,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _currentPage > 0 ? () => _goToPage(_currentPage - 1) : null,
                iconSize: 20,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '${_currentPage + 1} / $_totalPages',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _currentPage < _totalPages - 1 ? () => _goToPage(_currentPage + 1) : null,
                iconSize: 20,
              ),
              IconButton(
                icon: const Icon(Icons.last_page),
                onPressed: _currentPage < _totalPages - 1 ? () => _goToPage(_totalPages - 1) : null,
                iconSize: 20,
              ),
            ],
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
                _loadFromApi();
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
    idController.dispose();
    nameController.dispose();
    conditionController.dispose();
    super.dispose();
  }
}
