import 'package:flutter/material.dart';
import 'bottom_admin.dart';
import 'vocabulary_admin2.dart';
import 'touroku_admin.dart';
import 'services/admin_api_service.dart';

class VocabularyAdmin extends StatefulWidget {
  const VocabularyAdmin({Key? key}) : super(key: key);

  @override
  State<VocabularyAdmin> createState() => _VocabularyAdminState();
}

class _VocabularyAdminState extends State<VocabularyAdmin> {
  String selectedTab = '単語';
  String selectedMenu = 'コンテンツ管理';
  List<bool> selectedRows = [];

  // ページング
  int _currentPage = 0;
  int _totalPages = 1;
  int _totalElements = 0;
  final int _pageSize = 20;

  // ローディング・エラー状態
  bool _isLoading = false;
  String? _error;

  // 検索用のコントローラー
  final TextEditingController idController = TextEditingController();
  final TextEditingController wordController = TextEditingController();
  final TextEditingController partOfSpeechController = TextEditingController();

  String statusFilter = 'すべて';
  DateTime? startDate;
  DateTime? endDate;

  bool get hasSelection => selectedRows.any((selected) => selected);

  List<Map<String, dynamic>> vocabularies = [];

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

      final response = await AdminApiService.getVocabularies(
        page: _currentPage,
        size: _pageSize,
        word: wordController.text.trim().isNotEmpty ? wordController.text.trim() : null,
        isActive: isActive,
      );

      final content = response['vocabularies'] as List<dynamic>? ?? [];
      final loadedVocabularies = content.map((json) {
        return {
          'id': json['id']?.toString().padLeft(4, '0') ?? '0000',
          'numericId': json['id'] ?? 0,
          'word': json['word'] ?? '',
          'meaning': json['meaning'] ?? '',
          'pronunciation': json['pronunciation'] ?? '',
          'partOfSpeech': json['partOfSpeech'] ?? '',
          'status': json['isActive'] == true ? '有効' : '無効',
          'isActive': json['isActive'] ?? false,
          'addedDate': json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
          'exampleSentence': json['exampleSentence'] ?? '',
          'exampleTranslation': json['exampleTranslation'] ?? '',
        };
      }).toList();

      setState(() {
        vocabularies = loadedVocabularies;
        _totalPages = response['totalPages'] ?? 1;
        _totalElements = response['totalElements'] ?? 0;
        selectedRows = List.generate(vocabularies.length, (index) => false);
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
      wordController.clear();
      partOfSpeechController.clear();
      statusFilter = 'すべて';
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
      if (selectedRows[i]) {
        selectedIds.add(vocabularies[i]['numericId']);
      }
    }

    if (selectedIds.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await AdminApiService.disableVocabularies(selectedIds);
      await _loadFromApi();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('選択した単語を無効化しました')),
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
      if (selectedRows[i]) {
        selectedIds.add(vocabularies[i]['numericId']);
      }
    }

    if (selectedIds.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await AdminApiService.enableVocabularies(selectedIds);
      await _loadFromApi();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('選択した単語を有効化しました')),
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
        Expanded(child: _buildTable()),
        _buildPagination(),
        const SizedBox(height: 16),
        _buildActionButtons(),
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
            children: [
              Expanded(flex: 1, child: _buildTextField('ID', idController)),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: _buildTextField('単語', wordController)),
              const SizedBox(width: 12),
              Expanded(flex: 1, child: _buildTextField('品詞', partOfSpeechController)),
              const SizedBox(width: 12),
              Expanded(flex: 1, child: _buildDropdown('状態')),
              const SizedBox(width: 12),
              Expanded(flex: 3, child: _buildDateRangeField('追加日')),
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

  Widget _buildTextField(String label, TextEditingController controller) {
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
        ),
      ],
    );
  }

  Widget _buildDropdown(String label) {
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
          value: statusFilter,
          items: ['すべて', '有効', '無効']
              .map((item) => DropdownMenuItem(
                    value: item,
                    child: Text(item, style: const TextStyle(fontSize: 13)),
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

  Widget _buildTable() {
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
                    value: selectedRows.isNotEmpty && selectedRows.every((selected) => selected),
                    onChanged: (value) {
                      setState(() {
                        for (int i = 0; i < selectedRows.length; i++) {
                          selectedRows[i] = value ?? false;
                        }
                      });
                    },
                  ),
                ),
                _buildTableHeader('ID', 80),
                _buildTableHeader('単語\n意味', 200),
                _buildTableHeader('発音', 150),
                _buildTableHeader('品詞', 100),
                _buildTableHeader('状態', 100),
              ],
            ),
          ),
          // データ行
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildErrorView()
                    : vocabularies.isEmpty
                        ? _buildNoDataView()
                        : ListView.builder(
                            itemCount: vocabularies.length,
                            itemBuilder: (context, index) {
                              final vocab = vocabularies[index];
                              return Container(
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(color: Colors.grey[300]!),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 50,
                                      padding: const EdgeInsets.all(12),
                                      child: Checkbox(
                                        value: selectedRows[index],
                                        onChanged: (value) {
                                          setState(() {
                                            selectedRows[index] = value ?? false;
                                          });
                                        },
                                      ),
                                    ),
                                    _buildTableCell(
                                      Text(vocab['id'], style: const TextStyle(fontSize: 13)),
                                      80,
                                    ),
                                    _buildTableCell(
                                      GestureDetector(
                                        onTap: () async {
                                          final result = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => VocabularyDetailPage(
                                                vocab: {
                                                  'id': vocab['id'],
                                                  'numericId': vocab['numericId'],
                                                  'word': vocab['word'],
                                                  'meaning': vocab['meaning'],
                                                  'pronunciation': vocab['pronunciation'],
                                                  'partOfSpeech': vocab['partOfSpeech'],
                                                  'exampleSentence': vocab['exampleSentence'],
                                                  'exampleTranslation': vocab['exampleTranslation'],
                                                  'createdAt': vocab['addedDate'].toString(),
                                                  'updatedAt': DateTime.now().toString(),
                                                  'status': vocab['status'],
                                                },
                                              ),
                                            ),
                                          );
                                          if (result == true) {
                                            _loadFromApi();
                                          }
                                        },
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              vocab['word'],
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Colors.blue,
                                                decoration: TextDecoration.underline,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(vocab['meaning'],
                                              style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                          ],
                                        ),
                                      ),
                                      200,
                                    ),
                                    _buildTableCell(
                                      Text(vocab['pronunciation'], style: const TextStyle(fontSize: 13)),
                                      150,
                                    ),
                                    _buildTableCell(
                                      Text(vocab['partOfSpeech'], style: const TextStyle(fontSize: 13)),
                                      100,
                                    ),
                                    _buildTableCell(
                                      Center(
                                        child: Text(
                                          vocab['status'],
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: vocab['isActive'] ? Colors.black : Colors.grey[400],
                                          ),
                                        ),
                                      ),
                                      100,
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

  Widget _buildNoDataView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text('該当する単語が見つかりません', style: TextStyle(color: Colors.grey[600])),
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

  Widget _buildTableHeader(String text, double width) {
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

  Widget _buildTableCell(Widget child, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(12),
      child: child,
    );
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
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: const Text('選択中の単語を無効化', style: TextStyle(fontSize: 14)),
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
            child: const Text('選択中の単語を有効化', style: TextStyle(fontSize: 14)),
          ),
          const SizedBox(width: 12),
        ],
        ElevatedButton(
          onPressed: () {
            showTourokuDialog(
              context,
              'vocabulary',
              (data) async {
                try {
                  await AdminApiService.createVocabulary(data);
                  _loadFromApi();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('単語を追加しました')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('単語の追加に失敗しました: $e')),
                    );
                  }
                }
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
    wordController.dispose();
    partOfSpeechController.dispose();
    super.dispose();
  }
}
