import 'package:flutter/material.dart';
import 'user_model.dart';
import 'user_detail_admin.dart';
import 'buttom_admin.dart';

class UserListAdmin extends StatefulWidget {
  @override
  _UserListAdminState createState() => _UserListAdminState();
}

class _UserListAdminState extends State<UserListAdmin> {
  List<User> users = [];
  List<User> filteredUsers = [];
  List<bool> selectedUsers = [];
  bool hasSelection = false;

  // 検索条件
  String idSearch = '';
  String uuidSearch = '';
  String usernameSearch = '';
  String emailSearch = '';
  DateTime? createdStart;
  DateTime? createdEnd;
  DateTime? lastLoginStart;
  DateTime? lastLoginEnd;
  DateTime? subscRegistStart;
  DateTime? subscRegistEnd;
  DateTime? subscCancelStart;
  DateTime? subscCancelEnd;
  String? freezeStatus;
  String? language;
  String? subscStatus;

  @override
  void initState() {
    super.initState();
    _loadSampleData();
  }

  void _loadSampleData() {
    users = [
      User(
        id: '00001',
        uuid: 'sample_01',
        username: 'サンプル01',
        email: 'sample01@example.com',
        lastLogin: DateTime(2026, 1, 1),
        subscription: '加入中',
        isFrozen: false,
      ),
      User(
        id: '00002',
        uuid: 'sample_02',
        username: 'サンプル02',
        email: 'sample02@example.com',
        lastLogin: DateTime(2026, 2, 2),
        subscription: '×',
        isFrozen: false,
      ),
      User(
        id: '00003',
        uuid: 'sample_03',
        username: 'サンプル03',
        email: 'sample03@example.com',
        lastLogin: DateTime(2026, 3, 3),
        subscription: '×',
        isFrozen: true,
      ),
      User(
        id: '00004',
        uuid: 'sample_04',
        username: 'サンプル04',
        email: 'sample04@example.com',
        lastLogin: DateTime(2026, 4, 4),
        subscription: '加入中',
        isFrozen: false,
      ),
    ];
    filteredUsers = List.from(users);
    selectedUsers = List.generate(filteredUsers.length, (index) => false);
  }

  void _searchUsers() {
    setState(() {
      filteredUsers = users.where((user) {
        bool matches = true;

        if (idSearch.isNotEmpty && !user.id.contains(idSearch)) {
          matches = false;
        }
        if (uuidSearch.isNotEmpty && !user.uuid.contains(uuidSearch)) {
          matches = false;
        }
        if (usernameSearch.isNotEmpty && !user.username.contains(usernameSearch)) {
          matches = false;
        }
        if (emailSearch.isNotEmpty && !user.email.contains(emailSearch)) {
          matches = false;
        }
        if (freezeStatus != null && user.isFrozen != (freezeStatus == '停止中')) {
          matches = false;
        }
        if (subscStatus != null) {
          if (subscStatus == '加入中' && user.subscription != '加入中') {
            matches = false;
          } else if (subscStatus == '解約' && user.subscription != '×') {
            matches = false;
          }
        }

        return matches;
      }).toList();

      selectedUsers = List.generate(filteredUsers.length, (index) => false);
      _updateSelectionState();
    });
  }

  void _clearSearch() {
    setState(() {
      idSearch = '';
      uuidSearch = '';
      usernameSearch = '';
      emailSearch = '';
      createdStart = null;
      createdEnd = null;
      lastLoginStart = null;
      lastLoginEnd = null;
      subscRegistStart = null;
      subscRegistEnd = null;
      subscCancelStart = null;
      subscCancelEnd = null;
      freezeStatus = null;
      language = null;
      subscStatus = null;

      filteredUsers = List.from(users);
      selectedUsers = List.generate(filteredUsers.length, (index) => false);
      _updateSelectionState();
    });
  }

  void _toggleAllSelection(bool? value) {
    setState(() {
      if (value == true) {
        selectedUsers = List.generate(filteredUsers.length, (index) => true);
      } else {
        selectedUsers = List.generate(filteredUsers.length, (index) => false);
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

  void _freezeSelectedUsers() {
    setState(() {
      for (int i = 0; i < selectedUsers.length; i++) {
        if (selectedUsers[i]) {
          filteredUsers[i].freeze();
        }
      }
      _updateSelectionState();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('選択したユーザーを停止しました')),
    );
  }

  void _unfreezeSelectedUsers() {
    setState(() {
      for (int i = 0; i < selectedUsers.length; i++) {
        if (selectedUsers[i]) {
          filteredUsers[i].unfreeze();
        }
      }
      _updateSelectionState();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('選択したユーザーを復旧しました')),
    );
  }

  Widget _buildFreezeIndicator(bool isFrozen) {
    return isFrozen
        ? Icon(Icons.circle, color: Colors.red, size: 16)
        : Text('-', style: TextStyle(color: Colors.grey));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: BottomAdminLayout(
        mainContent: _buildMainContent(),
        selectedMenu: 'ユーザー管理',
        onMenuSelected: (_) {}, // 空のコールバックで十分
        showTabs: false,
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        // 検索条件エリア
        _buildVerticalSearchArea(),
        SizedBox(height: 16),
        
        // ユーザー一覧テーブル
        Expanded(
          child: _buildUserTable(),
        ),
      ],
    );
  }

  Widget _buildVerticalSearchArea() {
    return Container(
      padding: EdgeInsets.all(16),
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
                      SizedBox(height: 16),
                      _buildVerticalSearchField('UUID', (value) => uuidSearch = value),
                      SizedBox(height: 16),
                      _buildVerticalSearchField('ユーザー名', (value) => usernameSearch = value),
                      SizedBox(height: 16),
                      _buildVerticalSearchField('メールアドレス', (value) => emailSearch = value),
                    ],
                  ),
                ),
                SizedBox(width: 16),
                
                // 2列目
                Expanded(
                  child: Column(
                    children: [
                      _buildVerticalDateField(
                        'アカウント作成日',
                        (date) => createdStart = date,
                        (date) => createdEnd = date,
                        createdStart,
                        createdEnd,
                      ),
                      SizedBox(height: 16),
                      _buildVerticalDateField(
                        '最終ログイン日',
                        (date) => lastLoginStart = date,
                        (date) => lastLoginEnd = date,
                        lastLoginStart,
                        lastLoginEnd,
                      ),
                      SizedBox(height: 16),
                      _buildVerticalDateField(
                        'サブスク登録日',
                        (date) => subscRegistStart = date,
                        (date) => subscRegistEnd = date,
                        subscRegistStart,
                        subscRegistEnd,
                      ),
                      SizedBox(height: 16),
                      _buildVerticalDateField(
                        'サブスク解約日',
                        (date) => subscCancelStart = date,
                        (date) => subscCancelEnd = date,
                        subscCancelStart,
                        subscCancelEnd,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 16),
                
                // 3列目
                Expanded(
                  child: Column(
                    children: [
                      _buildVerticalDropdown('停止中', ['全て', '停止中', '有効'], (value) => freezeStatus = value),
                      SizedBox(height: 16),
                      _buildVerticalDropdown('言語設定', ['全て', '日本語', 'English'], (value) => language = value),
                      SizedBox(height: 16),
                      _buildVerticalDropdown('サブスク', ['全て', '加入中', '解約'], (value) => subscStatus = value),
                      SizedBox(height: 16),
                      // ボタンエリア
                      Container(
                        padding: EdgeInsets.only(top: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              width: 100,
                              child: OutlinedButton(
                                onPressed: _clearSearch,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.grey[700],
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: Text('クリア', style: TextStyle(color: Colors.black)),
                              ),
                            ),
                            SizedBox(width: 8),
                            Container(
                              width: 100,
                              child: ElevatedButton(
                                onPressed: _searchUsers,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue[700],
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: Text('検索', style: TextStyle(color: Colors.white)),
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
          width: 120, // ラベルの固定幅
          padding: EdgeInsets.only(top: 12), // 入力フィールドとの高さ調整
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: TextField(
            decoration: InputDecoration(
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
          width: 120,
          padding: EdgeInsets.only(top: 12),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
        ),
        SizedBox(width: 8),
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
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[400]!),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Text(
                              startDate != null
                                  ? '${startDate.year}/${startDate.month.toString().padLeft(2, '0')}/${startDate.day.toString().padLeft(2, '0')}'
                                  : '',
                              style: TextStyle(
                                color: startDate != null
                                    ? Colors.black
                                    : Colors.grey[600],
                                fontWeight: startDate != null
                                    ? FontWeight.normal
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    '〜',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  SizedBox(width: 8),
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
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[400]!),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Text(
                              endDate != null
                                  ? '${endDate.year}/${endDate.month.toString().padLeft(2, '0')}/${endDate.day.toString().padLeft(2, '0')}'
                                  : '',
                              style: TextStyle(
                                color: endDate != null
                                    ? Colors.black
                                    : Colors.grey[600],
                                fontWeight: endDate != null
                                    ? FontWeight.normal
                                    : FontWeight.normal,
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
          width: 120, // ラベルの固定幅
          padding: EdgeInsets.only(top: 12), // 入力フィールドとの高さ調整
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: DropdownButtonFormField<String>(
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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

  Widget _buildUserTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          // テーブルヘッダー
          if (filteredUsers.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  _buildTableHeader('', 1),
                  _buildTableHeader('ID', 1),
                  _buildTableHeader('UUID', 2),
                  _buildTableHeader('ユーザー名', 2),
                  _buildTableHeader('メールアドレス', 3),
                  _buildTableHeader('最終ログイン', 2),
                  _buildTableHeader('サブスク', 1),
                  _buildTableHeader('停止中', 1),
                ],
              ),
            ),
          
          // テーブルデータまたは該当なしメッセージ
          Expanded(
            child: filteredUsers.isEmpty
                ? _buildNoUsersFound()
                : ListView.builder(
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      return Container(
                        decoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(color: Colors.grey[300]!),
                            right: BorderSide(color: Colors.grey[300]!),
                            bottom: BorderSide(color: Colors.grey[300]!),
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
                              setState(() {
                                users.remove(result['user']);
                                filteredUsers.remove(result['user']);
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('ユーザーを削除しました')),
                              );
                            } else {
                              setState(() {});
                            }
                          },
                          child: Row(
                            children: [
                              _buildTableCell(
                                '',
                                1,
                                TextAlign.center,
                                child: Checkbox(
                                  value: selectedUsers[index],
                                  onChanged: (value) => _toggleUserSelection(index, value),
                                ),
                              ),
                              _buildTableCell(user.id, 1, TextAlign.center),
                              _buildTableCell(user.uuid, 2, TextAlign.left),
                              _buildTableCell(user.username, 2, TextAlign.left),
                              _buildTableCell(user.email, 3, TextAlign.left),
                              _buildTableCell(
                                '${user.lastLogin.year}/${user.lastLogin.month.toString().padLeft(2, '0')}/${user.lastLogin.day.toString().padLeft(2, '0')}',
                                2,
                                TextAlign.center
                              ),
                              _buildTableCell(user.subscription, 1, TextAlign.center),
                              _buildTableCell('', 1, TextAlign.center, 
                                child: _buildFreezeIndicator(user.isFrozen)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          
          // 選択中の操作ボタン
          if (hasSelection) _buildSelectionActionButtons(),
        ],
      ),
    );
  }

  Widget _buildNoUsersFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            '該当ユーザーが見つかりません',
            style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            '検索条件を変更して再度お試しください',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionActionButtons() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: Offset(2, 2),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _freezeSelectedUsers,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: Text('選択中のユーザーのアカウントを停止', style: TextStyle(color: Colors.white)),
            ),
          ),
          SizedBox(width: 16),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: Offset(2, 2),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _unfreezeSelectedUsers,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: Text('選択中のユーザーのアカウントを復旧', style: TextStyle(color: Colors.white)),
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
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          border: Border(right: BorderSide(color: Colors.grey[300]!)),
        ),
        child: text.isEmpty
            ? Checkbox(
                value: selectedUsers.every((element) => element) &&
                    selectedUsers.isNotEmpty,
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
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
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
