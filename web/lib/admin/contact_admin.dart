import 'package:flutter/material.dart';
import 'bottom_admin.dart';
import 'contact_admin2.dart';
import 'services/admin_api_service.dart';

class ContactAdmin extends StatefulWidget {
  const ContactAdmin({Key? key}) : super(key: key);

  @override
  State<ContactAdmin> createState() => _ContactAdminState();
}

class _ContactAdminState extends State<ContactAdmin> {
  String selectedMenu = 'お問い合わせ管理';
  String selectedTab = '未読';

  // ページング
  int _currentPage = 0;
  int _totalPages = 1;
  int _totalElements = 0;
  final int _pageSize = 20;

  // ローディング・エラー状態
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> _contactList = [];

  @override
  void initState() {
    super.initState();
    _loadFromApi();
  }

  String _getStatusForTab() {
    switch (selectedTab) {
      case '未読':
        return '未対応';
      case '進行中':
        return '対応中';
      case '完了':
        return '完了';
      default:
        return '';
    }
  }

  Future<void> _loadFromApi() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await AdminApiService.getContacts(
        page: _currentPage,
        size: _pageSize,
        status: _getStatusForTab(),
      );

      final content = response['content'] as List<dynamic>? ?? [];
      final loadedContacts = content.map((json) {
        return {
          'id': json['id']?.toString() ?? '0',
          'numericId': json['id'] ?? 0,
          'userName': json['userName'] ?? '',
          'email': json['email'] ?? '',
          'subject': json['subject'] ?? '',
          'status': json['status'] ?? '未対応',
          'receivedDate': json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : DateTime.now(),
          'content': json['content'] ?? '',
          'adminMemo': json['adminMemo'] ?? '',
        };
      }).toList();

      setState(() {
        _contactList = loadedContacts;
        _totalPages = response['totalPages'] ?? 1;
        _totalElements = response['totalElements'] ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'データの取得に失敗しました: $e';
        _isLoading = false;
      });
    }
  }

  void _onTabChanged(String tab) {
    setState(() {
      selectedTab = tab;
      _currentPage = 0;
    });
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
        _buildPagination(),
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
            onTap: () => _onTabChanged(tab),
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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildErrorView()
                    : _contactList.isEmpty
                        ? Center(
                            child: Text(
                              '該当するお問い合わせがありません',
                              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _contactList.length,
                            itemBuilder: (context, index) {
                              final item = _contactList[index];
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
                                        onPressed: () async {
                                          final result = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => ContactDetailPage(
                                                contact: item,
                                                onUpdate: (updatedContact) {
                                                  // API経由で更新されるので、リロードする
                                                },
                                              ),
                                            ),
                                          );
                                          if (result == true) {
                                            _loadFromApi();
                                          }
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

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
          const SizedBox(height: 12),
          Text(_error ?? '', style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadFromApi,
            child: const Text('再試行'),
          ),
        ],
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
}
