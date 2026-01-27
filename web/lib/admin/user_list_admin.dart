import 'package:flutter/material.dart';
import 'user_model.dart';
import 'user_detail_admin.dart';
import 'bottom_admin.dart';
import 'services/admin_api_service.dart';

class UserListAdmin extends StatefulWidget {
  @override
  _UserListAdminState createState() => _UserListAdminState();
}

class _UserListAdminState extends State<UserListAdmin> {
  List<User> users = [];
  List<bool> selectedUsers = [];
  bool hasSelection = false;

  // ページング
  int _currentPage = 0;
  int _totalPages = 1;
  int _totalElements = 0;
  final int _pageSize = 20;

  // ローディング・エラー状態
  bool _isLoading = false;
  String? _error;

  // 検索条件
  final TextEditingController idController = TextEditingController();
  final TextEditingController uuidController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  // 日付フィールド
  DateTime? createdStart;
  DateTime? createdEnd;
  DateTime? lastLoginStart;
  DateTime? lastLoginEnd;
  DateTime? subscRegistStart;
  DateTime? subscRegistEnd;
  DateTime? subscCancelStart;
  DateTime? subscCancelEnd;

  // ドロップダウン選択
  String freezeStatus = '全て';
  String subscStatus = '全て';
  bool _sortAscending = false;

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
      // 検索パラメータを構築
      int? searchId;
      if (idController.text.trim().isNotEmpty) {
        searchId = int.tryParse(idController.text.trim());
      }

      bool? banFlag;
      if (freezeStatus == '有効') {
        banFlag = true;
      } else if (freezeStatus == '有効') {
        banFlag = false;
      }

      bool? subscribeFlag;
      if (subscStatus == '加入中') {
        subscribeFlag = true;
      } else if (subscStatus == '解約') {
        subscribeFlag = false;
      }

      final response = await AdminApiService.getUsers(
        page: _currentPage,
        size: _pageSize,
        id: searchId,
        userUuid: uuidController.text.trim().isNotEmpty ? uuidController.text.trim() : null,
        username: usernameController.text.trim().isNotEmpty ? usernameController.text.trim() : null,
        email: emailController.text.trim().isNotEmpty ? emailController.text.trim() : null,
        banFlag: banFlag,
        subscribeFlag: subscribeFlag,
        createdFrom: createdStart,
        createdTo: createdEnd,
        offlineFrom: lastLoginStart,
        offlineTo: lastLoginEnd,
        sortDirection: _sortAscending ? 'asc' : 'desc',
      );

      final content = response['users'] as List<dynamic>? ?? [];
      final loadedUsers = content.map((json) => User.fromJson(json)).toList();

      setState(() {
        users = loadedUsers;
        _totalPages = response['totalPages'] ?? 1;
        _totalElements = response['totalElements'] ?? 0;
        selectedUsers = List.generate(users.length, (index) => false);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'データの取得に失敗しました: $e';
        _isLoading = false;
      });
    }
  }

  void _applySearch() {
    _currentPage = 0;
    _loadFromApi();
  }

  void _clearSearch() {
    setState(() {
      idController.clear();
      uuidController.clear();
      usernameController.clear();
      emailController.clear();

      createdStart = null;
      createdEnd = null;
      lastLoginStart = null;
      lastLoginEnd = null;
      subscRegistStart = null;
      subscRegistEnd = null;
      subscCancelStart = null;
      subscCancelEnd = null;

      freezeStatus = '全て';
      subscStatus = '全て';
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

  void _toggleAllSelection(bool? value) {
    setState(() {
      if (value == true) {
        selectedUsers = List.generate(users.length, (index) => true);
      } else {
        selectedUsers = List.generate(users.length, (index) => false);
      }
      _updateSelectionState();
    });
  }

  void _toggleUserSelection(int index, bool? value) {
    setState(() {
      selectedUsers[index] = value ?? false;
      _updateSelectionState();
    });
  }

  void _updateSelectionState() {
    setState(() {
      hasSelection = selectedUsers.any((selected) => selected);
    });
  }

  Future<void> _freezeSelectedUsers() async {
    final selectedIds = <int>[];
    for (int i = 0; i < selectedUsers.length; i++) {
      if (selectedUsers[i]) {
        selectedIds.add(users[i].numericId);
      }
    }

    if (selectedIds.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await AdminApiService.freezeUsers(selectedIds);
      await _loadFromApi();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('選択したユーザーを停止しました')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('停止処理に失敗しました: $e')),
        );
      }
    }
  }

  Future<void> _unfreezeSelectedUsers() async {
    final selectedIds = <int>[];
    for (int i = 0; i < selectedUsers.length; i++) {
      if (selectedUsers[i]) {
        selectedIds.add(users[i].numericId);
      }
    }

    if (selectedIds.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await AdminApiService.unfreezeUsers(selectedIds);
      await _loadFromApi();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('選択したユーザーを復旧しました')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('復旧処理に失敗しました: $e')),
        );
      }
    }
  }

  Widget _buildFreezeIndicator(bool isFrozen) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isFrozen ? Colors.red : Colors.green,
      ),
      child: Center(
        child: Icon(
          isFrozen ? Icons.block : Icons.check,
          color: Colors.white,
          size: 12,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: BottomAdminLayout(
        mainContent: _buildMainContent(),
        selectedMenu: 'ユーザー管理',
        showTabs: false,
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        // 検索条件エリア
        _buildSearchArea(),
        SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: _buildSortToggle(),
        ),
        SizedBox(height: 12),

        // ユーザー一覧テーブル
        Expanded(
          child: _buildUserTable(),
        ),
      ],
    );
  }

  Widget _buildSearchArea() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          // 1行目: ID + アカウント作成日 + 停止中
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ID', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                    SizedBox(height: 4),
                    _buildCompactTextFieldRow(idController),
                  ],
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('アカウント作成日', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                    SizedBox(height: 4),
                    _buildCompactDateFieldRow(createdStart, createdEnd, (start) {
                      setState(() => createdStart = start);
                    }, (end) {
                      setState(() => createdEnd = end);
                    }),
                  ],
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('有効', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                    SizedBox(height: 4),
                    _buildCompactDropdownRow(freezeStatus, ['全て', '停止中', '有効'], (value) {
                      setState(() => freezeStatus = value ?? '全て');
                    }),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),

          // 2行目: UUID + 最終ログイン日 + サブスク
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('UUID', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                    SizedBox(height: 4),
                    _buildCompactTextFieldRow(uuidController),
                  ],
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('最終ログイン日', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                    SizedBox(height: 4),
                    _buildCompactDateFieldRow(lastLoginStart, lastLoginEnd, (start) {
                      setState(() => lastLoginStart = start);
                    }, (end) {
                      setState(() => lastLoginEnd = end);
                    }),
                  ],
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('サブスク', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                    SizedBox(height: 4),
                    _buildCompactDropdownRow(subscStatus, ['全て', '加入中', '解約'], (value) {
                      setState(() => subscStatus = value ?? '全て');
                    }),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),

          // 3行目: ユーザー名 + サブスク登録日
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ユーザー名', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                    SizedBox(height: 4),
                    _buildCompactTextFieldRow(usernameController),
                  ],
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('サブスク登録日', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                    SizedBox(height: 4),
                    _buildCompactDateFieldRow(subscRegistStart, subscRegistEnd, (start) {
                      setState(() => subscRegistStart = start);
                    }, (end) {
                      setState(() => subscRegistEnd = end);
                    }),
                  ],
                ),
              ),
              SizedBox(width: 16),
              Expanded(flex: 1, child: SizedBox()),
            ],
          ),
          SizedBox(height: 12),

          // 4行目: メールアドレス + サブスク解約日
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('メールアドレス', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                    SizedBox(height: 4),
                    _buildCompactTextFieldRow(emailController),
                  ],
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('サブスク解約日', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                    SizedBox(height: 4),
                    _buildCompactDateFieldRow(subscCancelStart, subscCancelEnd, (start) {
                      setState(() => subscCancelStart = start);
                    }, (end) {
                      setState(() => subscCancelEnd = end);
                    }),
                  ],
                ),
              ),
              SizedBox(width: 16),
              Expanded(flex: 1, child: SizedBox()),
            ],
          ),
          SizedBox(height: 20),

          // ボタン行
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 100,
                child: ElevatedButton(
                  onPressed: _clearSearch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.grey[700],
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: Text('クリア', style: TextStyle(fontSize: 13)),
                ),
              ),
              SizedBox(width: 12),
              Container(
                width: 100,
                child: ElevatedButton(
                  onPressed: _applySearch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: Text('検索', style: TextStyle(fontSize: 13)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // コンパクトなテキストフィールド（行用）
  Widget _buildCompactTextFieldRow(TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: Colors.grey[400]!),
        ),
        filled: true,
        fillColor: Colors.white,
        isDense: true,
      ),
      style: TextStyle(fontSize: 12),
    );
  }

  // コンパクトな日付フィールド（行用）
  Widget _buildCompactDateFieldRow(
    DateTime? startDate,
    DateTime? endDate,
    Function(DateTime?) onStartChanged,
    Function(DateTime?) onEndChanged,
  ) {
    return Container(
      height: 36,
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: startDate ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: endDate ?? DateTime(2100),
                );
                if (date != null) {
                  onStartChanged(date);
                  if (endDate != null && date.isAfter(endDate)) {
                    onEndChanged(date);
                  }
                }
              },
              child: Container(
                height: 36,
                padding: EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[400]!),
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.white,
                ),
                alignment: Alignment.centerLeft,
                child: Text(
                  startDate != null
                      ? '${startDate.year}/${startDate.month}/${startDate.day}'
                      : '',
                  style: TextStyle(
                    fontSize: 11,
                    color: startDate != null ? Colors.black : Colors.grey[500],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '〜',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: endDate ?? startDate ?? DateTime.now(),
                  firstDate: startDate ?? DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (date != null) {
                  onEndChanged(date);
                }
              },
              child: Container(
                height: 36,
                padding: EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[400]!),
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.white,
                ),
                alignment: Alignment.centerLeft,
                child: Text(
                  endDate != null
                      ? '${endDate.year}/${endDate.month}/${endDate.day}'
                      : '',
                  style: TextStyle(
                    fontSize: 11,
                    color: endDate != null ? Colors.black : Colors.grey[500],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortToggle() {
    return OutlinedButton.icon(
      onPressed: () {
        setState(() {
          _sortAscending = !_sortAscending;
        });
        _loadFromApi();
      },
      icon: Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward, size: 16),
      label: Text(_sortAscending ? '昇順' : '降順', style: const TextStyle(fontSize: 12)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    );
  }

  // コンパクトなドロップダウン（行用）
  Widget _buildCompactDropdownRow(
    String value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return Container(
      height: 36,
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(color: Colors.grey[400]!),
          ),
          filled: true,
          fillColor: Colors.white,
          isDense: true,
        ),
        value: value,
        items: items.map((item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(
              item,
              style: TextStyle(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildUserTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          // テーブルヘッダー
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Row(
              children: [
                // チェックボックス列
                Container(
                  width: 50,
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: Center(
                    child: Checkbox(
                      value: selectedUsers.length == users.length &&
                            selectedUsers.isNotEmpty &&
                            selectedUsers.every((element) => element),
                      onChanged: (value) => _toggleAllSelection(value),
                    ),
                  ),
                ),

                // ID列
                _buildTableHeader('ID', 2),

                // UUID列
                _buildTableHeader('UUID', 3),

                // ユーザー名列
                _buildTableHeader('ユーザー名', 3),

                // メールアドレス列
                _buildTableHeader('メールアドレス', 4),

                // 最終ログイン日列
                _buildTableHeader('最終ログイン日', 3),

                // サブスク列
                _buildTableHeader('サブスク', 2),

                // 停止中列
                _buildTableHeader('有効', 2),
              ],
            ),
          ),

          // テーブルデータ
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildErrorView()
                    : users.isEmpty
                        ? _buildNoUsersFound()
                        : ListView.builder(
                            itemCount: users.length,
                            itemBuilder: (context, index) {
                              final user = users[index];
                              final lastLoginLocal = user.lastLogin.toLocal();
                              return Container(
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(color: Colors.grey[200]!),
                                  ),
                                ),
                                child: InkWell(
                                  onTap: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => UserDetailAdmin(user: user),
                                      ),
                                    );

                                    if (result != null && result['action'] == 'delete') {
                                      _loadFromApi();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('ユーザーを削除しました')),
                                      );
                                    } else if (result != null && result['action'] == 'updated') {
                                      _loadFromApi();
                                    }
                                  },
                                  child: Row(
                                    children: [
                                      // チェックボックス
                                      Container(
                                        width: 50,
                                        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                        child: Center(
                                          child: Checkbox(
                                            value: selectedUsers[index],
                                            onChanged: (value) => _toggleUserSelection(index, value),
                                          ),
                                        ),
                                      ),

                                      // ID
                                      _buildTableCell(user.id, 2, TextAlign.center),

                                      // UUID
                                      _buildTableCell(user.uuid, 3, TextAlign.left),

                                      // ユーザー名
                                      _buildTableCell(user.username, 3, TextAlign.left),

                                      // メールアドレス
                                      _buildTableCell(user.email, 4, TextAlign.left),

                                      // 最終ログイン日
                                      _buildTableCell(
                                        '${lastLoginLocal.year}/${lastLoginLocal.month.toString().padLeft(2, '0')}/${lastLoginLocal.day.toString().padLeft(2, '0')}',
                                        3,
                                        TextAlign.center
                                      ),

                                      // サブスク
                                      _buildTableCell(user.subscription, 2, TextAlign.center),

                                      // 停止中
                                      Expanded(
                                        flex: 2,
                                        child: Container(
                                          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                          child: Center(
                                            child: _buildFreezeIndicator(user.isFrozen),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),

          // ページネーション
          _buildPagination(),

          // 選択中の操作ボタン
          if (hasSelection) _buildSelectionActionButtons(),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
            SizedBox(height: 12),
            Text(
              'エラーが発生しました',
              style: TextStyle(
                fontSize: 14,
                color: Colors.red[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              _error ?? '',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadFromApi,
              child: Text('再試行'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoUsersFound() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
            SizedBox(height: 12),
            Text(
              '該当ユーザーが見つかりません',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
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
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
                icon: Icon(Icons.first_page),
                onPressed: _currentPage > 0 ? () => _goToPage(0) : null,
                iconSize: 20,
              ),
              IconButton(
                icon: Icon(Icons.chevron_left),
                onPressed: _currentPage > 0 ? () => _goToPage(_currentPage - 1) : null,
                iconSize: 20,
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '${_currentPage + 1} / $_totalPages',
                  style: TextStyle(fontSize: 12),
                ),
              ),
              IconButton(
                icon: Icon(Icons.chevron_right),
                onPressed: _currentPage < _totalPages - 1 ? () => _goToPage(_currentPage + 1) : null,
                iconSize: 20,
              ),
              IconButton(
                icon: Icon(Icons.last_page),
                onPressed: _currentPage < _totalPages - 1 ? () => _goToPage(_totalPages - 1) : null,
                iconSize: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionActionButtons() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton(
            onPressed: _freezeSelectedUsers,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: Text(
              '選択中のユーザーを停止',
              style: TextStyle(fontSize: 12),
            ),
          ),
          SizedBox(width: 8),
          ElevatedButton(
            onPressed: _unfreezeSelectedUsers,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: Text(
              '選択中のユーザーを復旧',
              style: TextStyle(fontSize: 12),
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
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildTableCell(String text, int flex, TextAlign align) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),

        child: Text(
          text,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[800],
          ),
          textAlign: align,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  @override
  void dispose() {
    idController.dispose();
    uuidController.dispose();
    usernameController.dispose();
    emailController.dispose();
    super.dispose();
  }
}
