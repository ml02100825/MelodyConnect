import 'package:flutter/material.dart';
import 'contact_model.dart';
import 'contact_detail_admin.dart';
import 'buttom_admin.dart';

class ContactListAdmin extends StatefulWidget {
  @override
  _ContactListAdminState createState() => _ContactListAdminState();
}

class _ContactListAdminState extends State<ContactListAdmin> {
  List<Contact> contacts = [];
  List<Contact> filteredContacts = [];

  // 検索条件
  String idSearch = '';
  String nameSearch = '';
  String emailSearch = '';
  String? categoryFilter;
  String? statusFilter;
  DateTime? createdStart;
  DateTime? createdEnd;

  @override
  void initState() {
    super.initState();
    _loadSampleData();
  }

  void _loadSampleData() {
    contacts = [
      Contact(
        id: '00001',
        name: '山田 太郎',
        email: 'yamada@example.com',
        category: '不具合報告',
        status: '未対応',
        createdAt: DateTime(2024, 1, 15),
        content: 'アプリが頻繁にクラッシュします。改善をお願いします。',
      ),
      Contact(
        id: '00002',
        name: '佐藤 花子',
        email: 'sato@example.com',
        category: '機能要望',
        status: '対応中',
        createdAt: DateTime(2024, 1, 14),
        content: '新しい学習モードの追加を希望します。',
        response: 'ご要望いただきありがとうございます。検討させていただきます。',
      ),
      Contact(
        id: '00003',
        name: '鈴木 一郎',
        email: 'suzuki@example.com',
        category: '課金関連',
        status: '対応済',
        createdAt: DateTime(2024, 1, 10),
        content: 'サブスクリプションの解約方法がわかりません。',
        response: '設定画面から解約手続きが可能です。詳細はヘルプをご確認ください。',
      ),
      Contact(
        id: '00004',
        name: '高橋 美咲',
        email: 'takahashi@example.com',
        category: 'その他',
        status: '未対応',
        createdAt: DateTime(2024, 1, 8),
        content: 'パートナー企業からのお問い合わせです。',
      ),
    ];
    filteredContacts = List.from(contacts);
  }

  void _searchContacts() {
    setState(() {
      filteredContacts = contacts.where((contact) {
        bool matches = true;

        if (idSearch.isNotEmpty && !contact.id.contains(idSearch)) {
          matches = false;
        }
        if (nameSearch.isNotEmpty && !contact.name.contains(nameSearch)) {
          matches = false;
        }
        if (emailSearch.isNotEmpty && !contact.email.contains(emailSearch)) {
          matches = false;
        }
        if (categoryFilter != null && categoryFilter != '全て' && contact.category != categoryFilter) {
          matches = false;
        }
        if (statusFilter != null && statusFilter != '全て' && contact.status != statusFilter) {
          matches = false;
        }

        return matches;
      }).toList();
    });
  }

  void _clearSearch() {
    setState(() {
      idSearch = '';
      nameSearch = '';
      emailSearch = '';
      categoryFilter = null;
      statusFilter = null;
      createdStart = null;
      createdEnd = null;
      filteredContacts = List.from(contacts);
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case '未対応':
        return Colors.red;
      case '対応中':
        return Colors.orange;
      case '対応済':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: BottomAdminLayout(
        mainContent: _buildMainContent(),
        selectedMenu: 'お問い合わせ管理',
        onMenuSelected: (_) {},
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
        
        // お問い合わせ一覧テーブル
        Expanded(
          child: _buildContactTable(),
        ),
      ],
    );
  }

  Widget _buildSearchArea() {
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
                      _buildSearchField('ID', (value) => idSearch = value),
                      SizedBox(height: 16),
                      _buildSearchField('お名前', (value) => nameSearch = value),
                      SizedBox(height: 16),
                      _buildSearchField('メールアドレス', (value) => emailSearch = value),
                    ],
                  ),
                ),
                SizedBox(width: 16),
                
                // 2列目
                Expanded(
                  child: Column(
                    children: [
                      _buildDropdown('カテゴリ', ['全て', '不具合報告', '機能要望', '課金関連', 'その他'], (value) => categoryFilter = value),
                      SizedBox(height: 16),
                      _buildDropdown('ステータス', ['全て', '未対応', '対応中', '対応済'], (value) => statusFilter = value),
                      SizedBox(height: 16),
                      _buildDateField('受信日', (date) => createdStart = date, (date) => createdEnd = date),
                    ],
                  ),
                ),
                SizedBox(width: 16),
                
                // 3列目
                Expanded(
                  child: Column(
                    children: [
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
                                onPressed: _searchContacts,
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

  Widget _buildSearchField(String label, Function(String) onChanged) {
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

  Widget _buildDropdown(String label, List<String> options, Function(String?) onChanged) {
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

  Widget _buildDateField(String label, Function(DateTime?) onStartChanged, Function(DateTime?) onEndChanged) {
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
                          initialDate: createdStart ?? DateTime.now(),
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
                              createdStart != null
                                  ? '${createdStart!.year}/${createdStart!.month.toString().padLeft(2, '0')}/${createdStart!.day.toString().padLeft(2, '0')}'
                                  : 'から',
                              style: TextStyle(
                                color: createdStart != null ? Colors.black : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text('〜', style: TextStyle(color: Colors.grey[600])),
                  SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: createdEnd ?? DateTime.now(),
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
                              createdEnd != null
                                  ? '${createdEnd!.year}/${createdEnd!.month.toString().padLeft(2, '0')}/${createdEnd!.day.toString().padLeft(2, '0')}'
                                  : 'まで',
                              style: TextStyle(
                                color: createdEnd != null ? Colors.black : Colors.grey[600],
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

  Widget _buildContactTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          // テーブルヘッダー
          if (filteredContacts.isNotEmpty)
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
                  _buildTableHeader('ID', 1),
                  _buildTableHeader('お名前', 2),
                  _buildTableHeader('メールアドレス', 2),
                  _buildTableHeader('カテゴリ', 2),
                  _buildTableHeader('ステータス', 2),
                  _buildTableHeader('受信日時', 2),
                  _buildTableHeader('内容', 3),
                ],
              ),
            ),
          
          // テーブルデータまたは該当なしメッセージ
          Expanded(
            child: filteredContacts.isEmpty
                ? _buildNoContactsFound()
                : ListView.builder(
                    itemCount: filteredContacts.length,
                    itemBuilder: (context, index) {
                      final contact = filteredContacts[index];
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
                                builder: (context) => ContactDetailAdmin(contact: contact),
                              ),
                            );
                            
                            if (result != null) {
                              setState(() {
                                // ステータス更新を反映
                                final updatedContact = result['contact'] as Contact;
                                final originalIndex = contacts.indexWhere((c) => c.id == updatedContact.id);
                                if (originalIndex != -1) {
                                  contacts[originalIndex] = updatedContact;
                                  filteredContacts = List.from(contacts);
                                }
                              });
                            }
                          },
                          child: Row(
                            children: [
                              _buildTableCell(contact.id, 1, TextAlign.center),
                              _buildTableCell(contact.name, 2, TextAlign.left),
                              _buildTableCell(contact.email, 2, TextAlign.left),
                              _buildTableCell(contact.category, 2, TextAlign.left),
                              _buildTableCell(
                                contact.status, 
                                2, 
                                TextAlign.center,
                                style: TextStyle(
                                  color: _getStatusColor(contact.status),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              _buildTableCell(
                                '${contact.createdAt.year}/${contact.createdAt.month.toString().padLeft(2, '0')}/${contact.createdAt.day.toString().padLeft(2, '0')}',
                                2,
                                TextAlign.center
                              ),
                              _buildTableCell(
                                contact.content.length > 30 
                                    ? '${contact.content.substring(0, 30)}...' 
                                    : contact.content,
                                3,
                                TextAlign.left
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoContactsFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            '該当のお問い合わせが見つかりません',
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

  Widget _buildTableHeader(String text, int flex) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          border: Border(right: BorderSide(color: Colors.grey[300]!)),
        ),
        child: Text(
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

  Widget _buildTableCell(String text, int flex, TextAlign align, {TextStyle? style}) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          border: Border(right: BorderSide(color: Colors.grey[300]!)),
        ),
        child: Text(
          text,
          style: style ?? TextStyle(color: Colors.grey[700]),
          textAlign: align,
        ),
      ),
    );
  }
}