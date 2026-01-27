import 'package:flutter/material.dart';
import 'bottom_admin.dart';
import 'contact_admin2.dart';
import 'vocabulary_report_detail.dart';
import 'question_report_detail.dart';
import 'services/admin_api_service.dart';

class ContactAdmin extends StatefulWidget {
  const ContactAdmin({Key? key}) : super(key: key);

  @override
  State<ContactAdmin> createState() => _ContactAdminState();
}

class _ContactAdminState extends State<ContactAdmin> {
  String selectedMenu = 'お問い合わせ管理';
  String selectedTopTab = 'お問い合わせ';
  String selectedTab = '未読';

  // ページング
  int _currentPage = 0;
  int _totalPages = 1;
  int _totalElements = 0;
  final int _pageSize = 20;

  // ローディング・エラー状態
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> _dataList = [];

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
      Map<String, dynamic> response;
      List<Map<String, dynamic>> loadedData;

      switch (selectedTopTab) {
        case 'お問い合わせ':
          response = await AdminApiService.getContacts(
            page: _currentPage,
            size: _pageSize,
            status: _getStatusForTab(),
          );
          final content = response['contacts'] as List<dynamic>? ?? [];
          loadedData = content.map((json) {
            return {
              'id': json['contactId']?.toString() ?? '0',
              'numericId': json['contactId'] ?? 0,
              'userName': json['userEmail'] ?? '',
              'email': json['userEmail'] ?? '',
              'subject': json['title'] ?? '',
              'status': json['status'] ?? '未対応',
              'receivedDate': json['createdAt'] != null
                  ? DateTime.parse(json['createdAt']).toUtc()
                  : DateTime.now().toUtc(),
              'content': json['contactDetail'] ?? '',
              'adminMemo': json['adminMemo'] ?? '',
            };
          }).toList();
          break;

        case '単語報告':
          response = await AdminApiService.getVocabularyReports(
            page: _currentPage,
            size: _pageSize,
            status: _getStatusForTab(),
          );
          final content = response['vocabularyReports'] as List<dynamic>? ?? [];
          loadedData = content.map((json) {
            return {
              'id': json['vocabularyReportId']?.toString() ?? '0',
              'numericId': json['vocabularyReportId'] ?? 0,
              'vocabularyId': json['vocabularyId'] ?? 0,
              'word': json['word'] ?? '',
              'meaningJa': json['meaningJa'] ?? '',
              'userId': json['userId'] ?? 0,
              'userEmail': json['userEmail'] ?? '',
              'reportContent': json['reportContent'] ?? '',
              'status': json['status'] ?? '未対応',
              'adminMemo': json['adminMemo'] ?? '',
              'addedAt': json['addedAt'] != null
                  ? DateTime.parse(json['addedAt']).toUtc()
                  : DateTime.now().toUtc(),
            };
          }).toList();
          break;

        case '問題報告':
          response = await AdminApiService.getQuestionReports(
            page: _currentPage,
            size: _pageSize,
            status: _getStatusForTab(),
          );
          final content = response['questionReports'] as List<dynamic>? ?? [];
          loadedData = content.map((json) {
            return {
              'id': json['questionReportId']?.toString() ?? '0',
              'numericId': json['questionReportId'] ?? 0,
              'questionId': json['questionId'] ?? 0,
              'questionText': json['questionText'] ?? '',
              'answer': json['answer'] ?? '',
              'songName': json['songName'] ?? '',
              'artistName': json['artistName'] ?? '',
              'userId': json['userId'] ?? 0,
              'userEmail': json['userEmail'] ?? '',
              'reportContent': json['reportContent'] ?? '',
              'status': json['status'] ?? '未対応',
              'adminMemo': json['adminMemo'] ?? '',
              'addedAt': json['addedAt'] != null
                  ? DateTime.parse(json['addedAt']).toUtc()
                  : DateTime.now().toUtc(),
            };
          }).toList();
          break;

        default:
          loadedData = [];
          response = {'totalPages': 1, 'totalElements': 0};
      }

      setState(() {
        _dataList = loadedData;
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

  void _onTopTabChanged(String tab) {
    setState(() {
      selectedTopTab = tab;
      selectedTab = '未読';
      _currentPage = 0;
    });
    _loadFromApi();
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
        _buildTopLevelTabs(),
        const SizedBox(height: 16),
        _buildStatusTabBar(),
        const SizedBox(height: 24),
        Expanded(child: _buildDataTable()),
        _buildPagination(),
      ],
    );
  }

  Widget _buildTopLevelTabs() {
    final topTabs = ['お問い合わせ', '単語報告', '問題報告'];
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[400]!, width: 1),
        ),
      ),
      child: Row(
        children: topTabs.map((tab) {
          final isSelected = selectedTopTab == tab;
          return GestureDetector(
            onTap: () => _onTopTabChanged(tab),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue.withOpacity(0.1) : null,
                border: Border(
                  bottom: BorderSide(
                    color: isSelected ? Colors.blue : Colors.transparent,
                    width: 3,
                  ),
                ),
              ),
              child: Text(
                tab,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.blue : Colors.grey[600],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatusTabBar() {
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
    switch (selectedTopTab) {
      case 'お問い合わせ':
        return _buildContactTable();
      case '単語報告':
        return _buildVocabularyReportTable();
      case '問題報告':
        return _buildQuestionReportTable();
      default:
        return _buildContactTable();
    }
  }

  Widget _buildContactTable() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Container(
            color: Colors.grey[200],
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            child: Row(
              children: const [
                Expanded(flex: 1, child: Text('ID', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500), textAlign: TextAlign.center)),
                Expanded(flex: 2, child: Text('ユーザー', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500), textAlign: TextAlign.center)),
                Expanded(flex: 3, child: Text('件名', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500), textAlign: TextAlign.center)),
                Expanded(flex: 2, child: Text('ステータス', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500), textAlign: TextAlign.center)),
                Expanded(flex: 2, child: Text('受信日時', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500), textAlign: TextAlign.center)),
                Expanded(flex: 1, child: Text('詳細', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500), textAlign: TextAlign.center)),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildErrorView()
                    : _dataList.isEmpty
                        ? Center(child: Text('該当するお問い合わせがありません', style: TextStyle(fontSize: 14, color: Colors.grey[600])))
                        : ListView.builder(
                            itemCount: _dataList.length,
                            itemBuilder: (context, index) {
                              final item = _dataList[index];
                              final receivedDate =
                                  (item['receivedDate'] as DateTime).toLocal();
                              final dateStr = '${receivedDate.year}/${receivedDate.month.toString().padLeft(2, '0')}/${receivedDate.day.toString().padLeft(2, '0')}';
                              final statusColor = _getStatusColor(item['status'] as String);

                              return Container(
                                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[300]!))),
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                child: Row(
                                  children: [
                                    Expanded(flex: 1, child: Text(item['id'] as String, style: const TextStyle(fontSize: 13), textAlign: TextAlign.center)),
                                    Expanded(flex: 2, child: Text(item['userName'] as String, style: const TextStyle(fontSize: 13), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis)),
                                    Expanded(flex: 3, child: Text(item['subject'] as String, style: const TextStyle(fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                    Expanded(flex: 2, child: Text(item['status'] as String, style: TextStyle(fontSize: 13, color: statusColor, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                                    Expanded(flex: 2, child: Text(dateStr, style: const TextStyle(fontSize: 13), textAlign: TextAlign.center)),
                                    Expanded(
                                      flex: 1,
                                      child: IconButton(
                                        icon: const Icon(Icons.arrow_forward_ios, size: 16),
                                        onPressed: () async {
                                          final result = await Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (context) => ContactDetailPage(contact: item, onUpdate: (updatedContact) {})),
                                          );
                                          if (result == true) _loadFromApi();
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

  Widget _buildVocabularyReportTable() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Container(
            color: Colors.grey[200],
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            child: Row(
              children: const [
                Expanded(flex: 1, child: Text('ID', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500), textAlign: TextAlign.center)),
                Expanded(flex: 2, child: Text('単語', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500), textAlign: TextAlign.center)),
                Expanded(flex: 2, child: Text('報告者', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500), textAlign: TextAlign.center)),
                Expanded(flex: 3, child: Text('報告内容', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500), textAlign: TextAlign.center)),
                Expanded(flex: 2, child: Text('ステータス', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500), textAlign: TextAlign.center)),
                Expanded(flex: 2, child: Text('報告日時', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500), textAlign: TextAlign.center)),
                Expanded(flex: 1, child: Text('詳細', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500), textAlign: TextAlign.center)),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildErrorView()
                    : _dataList.isEmpty
                        ? Center(child: Text('該当する単語報告がありません', style: TextStyle(fontSize: 14, color: Colors.grey[600])))
                        : ListView.builder(
                            itemCount: _dataList.length,
                            itemBuilder: (context, index) {
                              final item = _dataList[index];
                              final addedAt =
                                  (item['addedAt'] as DateTime).toLocal();
                              final dateStr = '${addedAt.year}/${addedAt.month.toString().padLeft(2, '0')}/${addedAt.day.toString().padLeft(2, '0')}';
                              final statusColor = _getStatusColor(item['status'] as String);

                              return Container(
                                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[300]!))),
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                child: Row(
                                  children: [
                                    Expanded(flex: 1, child: Text(item['id'] as String, style: const TextStyle(fontSize: 13), textAlign: TextAlign.center)),
                                    Expanded(flex: 2, child: Text(item['word'] as String, style: const TextStyle(fontSize: 13), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis)),
                                    Expanded(flex: 2, child: Text(item['userEmail'] as String, style: const TextStyle(fontSize: 13), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis)),
                                    Expanded(flex: 3, child: Text(item['reportContent'] as String, style: const TextStyle(fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                    Expanded(flex: 2, child: Text(item['status'] as String, style: TextStyle(fontSize: 13, color: statusColor, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                                    Expanded(flex: 2, child: Text(dateStr, style: const TextStyle(fontSize: 13), textAlign: TextAlign.center)),
                                    Expanded(
                                      flex: 1,
                                      child: IconButton(
                                        icon: const Icon(Icons.arrow_forward_ios, size: 16),
                                        onPressed: () async {
                                          final result = await Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (context) => VocabularyReportDetailPage(report: item, onUpdate: (updated) {})),
                                          );
                                          if (result == true) _loadFromApi();
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

  Widget _buildQuestionReportTable() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Container(
            color: Colors.grey[200],
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            child: Row(
              children: const [
                Expanded(flex: 1, child: Text('ID', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500), textAlign: TextAlign.center)),
                Expanded(flex: 3, child: Text('問題文', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500), textAlign: TextAlign.center)),
                Expanded(flex: 2, child: Text('曲名', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500), textAlign: TextAlign.center)),
                Expanded(flex: 2, child: Text('報告者', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500), textAlign: TextAlign.center)),
                Expanded(flex: 2, child: Text('ステータス', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500), textAlign: TextAlign.center)),
                Expanded(flex: 2, child: Text('報告日時', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500), textAlign: TextAlign.center)),
                Expanded(flex: 1, child: Text('詳細', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500), textAlign: TextAlign.center)),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildErrorView()
                    : _dataList.isEmpty
                        ? Center(child: Text('該当する問題報告がありません', style: TextStyle(fontSize: 14, color: Colors.grey[600])))
                        : ListView.builder(
                            itemCount: _dataList.length,
                            itemBuilder: (context, index) {
                              final item = _dataList[index];
                              final addedAt =
                                  (item['addedAt'] as DateTime).toLocal();
                              final dateStr = '${addedAt.year}/${addedAt.month.toString().padLeft(2, '0')}/${addedAt.day.toString().padLeft(2, '0')}';
                              final statusColor = _getStatusColor(item['status'] as String);

                              return Container(
                                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[300]!))),
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                child: Row(
                                  children: [
                                    Expanded(flex: 1, child: Text(item['id'] as String, style: const TextStyle(fontSize: 13), textAlign: TextAlign.center)),
                                    Expanded(flex: 3, child: Text(item['questionText'] as String, style: const TextStyle(fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                    Expanded(flex: 2, child: Text(item['songName'] as String, style: const TextStyle(fontSize: 13), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis)),
                                    Expanded(flex: 2, child: Text(item['userEmail'] as String, style: const TextStyle(fontSize: 13), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis)),
                                    Expanded(flex: 2, child: Text(item['status'] as String, style: TextStyle(fontSize: 13, color: statusColor, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                                    Expanded(flex: 2, child: Text(dateStr, style: const TextStyle(fontSize: 13), textAlign: TextAlign.center)),
                                    Expanded(
                                      flex: 1,
                                      child: IconButton(
                                        icon: const Icon(Icons.arrow_forward_ios, size: 16),
                                        onPressed: () async {
                                          final result = await Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (context) => QuestionReportDetailPage(report: item, onUpdate: (updated) {})),
                                          );
                                          if (result == true) _loadFromApi();
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

  Color _getStatusColor(String status) {
    switch (status) {
      case '未対応':
        return Colors.red;
      case '対応中':
        return Colors.orange;
      case '完了':
        return Colors.green;
      default:
        return Colors.black;
    }
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
