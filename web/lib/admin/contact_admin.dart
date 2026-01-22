import 'package:flutter/material.dart';
import 'bottom_admin.dart';
import 'contact_admin2.dart';

class ContactAdmin extends StatefulWidget {
  const ContactAdmin({Key? key}) : super(key: key);

  @override
  State<ContactAdmin> createState() => _ContactAdminState();
}

class _ContactAdminState extends State<ContactAdmin> {
  String selectedMenu = 'お問い合わせ管理';
  String selectedTab = '未読';

  // サンプルデータ
  final List<Map<String, dynamic>> _contactList = [
    {
      'id': '12',
      'userName': '山田太郎',
      'email': 'yamada@example.com',
      'subject': 'パスワード再設定について',
      'status': '未対応',
      'receivedDate': DateTime(2025, 1, 1, 13, 20),
      'content': 'ログインができず困っています……',
      'adminMemo': '',
    },
    {
      'id': '11',
      'userName': '田中花子',
      'email': 'tanaka@example.com',
      'subject': '決済に関して',
      'status': '対応中',
      'receivedDate': DateTime(2024, 12, 29, 10, 15),
      'content': 'クレジットカードの決済がうまくいきません。',
      'adminMemo': '決済システムを確認中',
    },
    {
      'id': '10',
      'userName': '佐藤健',
      'email': 'sato@example.com',
      'subject': '退会について',
      'status': '完了',
      'receivedDate': DateTime(2024, 12, 28, 16, 30),
      'content': '退会手続きの方法を教えてください。',
      'adminMemo': '退会手順を案内済み',
    },
    {
      'id': '09',
      'userName': '鈴木一郎',
      'email': 'suzuki@example.com',
      'subject': 'アカウント削除について',
      'status': '未対応',
      'receivedDate': DateTime(2024, 12, 27, 9, 45),
      'content': 'アカウントを削除したいです。',
      'adminMemo': '',
    },
    {
      'id': '08',
      'userName': '高橋美咲',
      'email': 'takahashi@example.com',
      'subject': 'サービス利用方法',
      'status': '完了',
      'receivedDate': DateTime(2024, 12, 26, 14, 20),
      'content': '新機能の使い方を教えてください。',
      'adminMemo': 'マニュアル送付済み',
    },
  ];

  List<Map<String, dynamic>> get filteredContactList {
    if (selectedTab == '未読') {
      return _contactList.where((contact) => contact['status'] == '未対応').toList();
    } else if (selectedTab == '進行中') {
      return _contactList.where((contact) => contact['status'] == '対応中').toList();
    } else if (selectedTab == '完了') {
      return _contactList.where((contact) => contact['status'] == '完了').toList();
    }
    return _contactList;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: BottomAdminLayout(
        selectedMenu: selectedMenu,
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
        Expanded(child: _buildDataTable()),
      ],
    );
  }

  Widget _buildTabBar() {
    final tabs = ['未読', '進行中', '完了'];
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

  Widget _buildDataTable() {
    final displayList = filteredContactList;

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
              children: const [
                Expanded(
                  flex: 1,
                  child: Text(
                    'ID',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'ユーザー名',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    '件名',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'ステータス',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '受信日時',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    '詳細',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          // テーブルボディ
          Expanded(
            child: displayList.isEmpty
                ? Center(
                    child: Text(
                      '該当するお問い合わせがありません',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  )
                : ListView.builder(
                    itemCount: displayList.length,
                    itemBuilder: (context, index) {
                      final item = displayList[index];
                      final receivedDate = item['receivedDate'] as DateTime;
                      final dateStr =
                          '${receivedDate.year}/${receivedDate.month.toString().padLeft(2, '0')}/${receivedDate.day.toString().padLeft(2, '0')}';

                      Color statusColor = Colors.black;
                      if (item['status'] == '未対応') {
                        statusColor = Colors.red;
                      } else if (item['status'] == '対応中') {
                        statusColor = Colors.orange;
                      } else if (item['status'] == '完了') {
                        statusColor = Colors.green;
                      }

                      final originalIndex = _contactList.indexOf(item);

                      return Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: Text(
                                item['id'] as String,
                                style: const TextStyle(fontSize: 13),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                item['userName'] as String,
                                style: const TextStyle(fontSize: 13),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                item['subject'] as String,
                                style: const TextStyle(fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                item['status'] as String,
                                style: TextStyle(
                                    fontSize: 13, color: statusColor, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                dateStr,
                                style: const TextStyle(fontSize: 13),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: IconButton(
                                icon: const Icon(Icons.arrow_forward_ios, size: 16),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ContactDetailPage(
                                        contact: item,
                                        onUpdate: (updatedContact) {
                                          setState(() {
                                            _contactList[originalIndex] = updatedContact;
                                          });
                                        },
                                      ),
                                    ),
                                  );
                                },
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
}