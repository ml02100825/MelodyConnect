import 'package:flutter/material.dart';
import 'bottom_admin.dart';
import 'mondai_admin2.dart';
import 'touroku_admin.dart';
import 'services/admin_api_service.dart';

class MondaiAdmin extends StatefulWidget {
  const MondaiAdmin({Key? key}) : super(key: key);

  @override
  State<MondaiAdmin> createState() => _MondaiAdminState();
}

class _MondaiAdminState extends State<MondaiAdmin> {
  String selectedTab = '問題';
  String selectedMenu = 'コンテンツ管理';
  List<bool> selectedRows = [];

  final TextEditingController idController = TextEditingController();
  final TextEditingController questionController = TextEditingController();
  final TextEditingController correctAnswerController = TextEditingController();
  final TextEditingController songNameController = TextEditingController();
  final TextEditingController artistController = TextEditingController();

  String categoryFilter = '問題形式';
  String difficultyFilter = '難易度';
  String statusFilter = '状態';
  DateTime? startDate;
  DateTime? endDate;

  bool get hasSelection => selectedRows.any((selected) => selected);

  // API連携用
  List<Map<String, dynamic>> questions = [];
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
      // 検索パラメータを構築
      String? questionFormat;
      if (categoryFilter != '問題形式') {
        // API側のフォーマットに変換
        if (categoryFilter == '穴埋め') questionFormat = 'FILL_BLANK';
        if (categoryFilter == 'リスニング') questionFormat = 'LISTENING';
        if (categoryFilter == '選択') questionFormat = 'CHOICE';
        if (categoryFilter == '並び替え') questionFormat = 'SORT';
      }

      bool? isActive;
      if (statusFilter == '有効') {
        isActive = true;
      } else if (statusFilter == '無効') {
        isActive = false;
      }

      final response = await AdminApiService.getQuestions(
        page: _currentPage,
        size: _pageSize,
        questionFormat: questionFormat,
        isActive: isActive,
      );

      final content = response['questions'] as List<dynamic>? ?? [];
      final loadedQuestions = content.map((json) {
        // APIレスポンスをUIフォーマットに変換
        String category = '穴埋め';
        final format = json['questionFormat'] as String?;
        if (format == 'FILL_BLANK') category = '穴埋め';
        if (format == 'LISTENING') category = 'リスニング';
        if (format == 'CHOICE') category = '選択';
        if (format == 'SORT') category = '並び替え';

        return {
          'id': json['id']?.toString() ?? '',
          'question': json['questionText'] ?? '',
          'correctAnswer': json['answer'] ?? '',
          'category': category,
          'difficulty': json['difficulty'] ?? '初級',
          'status': (json['isActive'] == true) ? '有効' : '無効',
          'addedDate': json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
              : DateTime.now(),
          'songName': json['songName'] ?? '',
          'artist': json['artistName'] ?? '',
          'numericId': json['id'] as int? ?? 0,
        };
      }).toList();

      setState(() {
        questions = loadedQuestions;
        _totalPages = response['totalPages'] ?? 1;
        _totalElements = response['totalElements'] ?? 0;
        selectedRows = List.generate(questions.length, (index) => false);
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
      questionController.clear();
      correctAnswerController.clear();
      songNameController.clear();
      artistController.clear();
      categoryFilter = '問題形式';
      difficultyFilter = '難易度';
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
      if (selectedRows[i] && i < questions.length) {
        selectedIds.add(questions[i]['numericId'] as int);
      }
    }

    if (selectedIds.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await AdminApiService.disableQuestions(selectedIds);
      await _loadFromApi();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('選択した問題を無効化しました')),
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
      if (selectedRows[i] && i < questions.length) {
        selectedIds.add(questions[i]['numericId'] as int);
      }
    }

    if (selectedIds.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await AdminApiService.enableQuestions(selectedIds);
      await _loadFromApi();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('選択した問題を有効化しました')),
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
              Expanded(flex: 1, child: _buildCompactDropdown('問題形式', categoryFilter,
                ['問題形式', '穴埋め', 'リスニング', '選択', '並び替え'], (value) {
                setState(() {
                  categoryFilter = value ?? '問題形式';
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
              Expanded(flex: 1, child: _buildCompactTextField('問題文', questionController)),
              const SizedBox(width: 12),
              Expanded(flex: 1, child: _buildCompactDropdown('難易度', difficultyFilter,
                ['難易度', '初級', '中級', '上級'], (value) {
                setState(() {
                  difficultyFilter = value ?? '難易度';
                });
              })),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: _buildCompactTextField('楽曲名', songNameController)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 1, child: _buildCompactTextField('正答', correctAnswerController)),
              const SizedBox(width: 12),
              Expanded(flex: 1, child: _buildCompactDropdown('状態', statusFilter,
                ['状態', '有効', '無効'], (value) {
                setState(() {
                  statusFilter = value ?? '状態';
                });
              })),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: _buildCompactTextField('アーティスト名', artistController)),
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
                           questions.isNotEmpty,
                    onChanged: (value) {
                      setState(() {
                        for (int i = 0; i < selectedRows.length; i++) {
                          selectedRows[i] = value ?? false;
                        }
                      });
                    },
                  ),
                ),
                _buildListHeader('ID\n問題形式', 80),
                _buildListHeader('問題文\n知識', 250),
                _buildListHeader('正答\n難易度', 150),
                _buildListHeader('楽曲名\nアーティスト名', 180),
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
                    : questions.isEmpty
                        ? _buildNoDataFound()
                        : ListView.builder(
                            itemCount: questions.length,
                            itemBuilder: (context, index) {
                              final question = questions[index];
                              return Container(
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(color: Colors.grey[300]!),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(question['id'], style: const TextStyle(fontSize: 13)),
                                          const SizedBox(height: 4),
                                          Text(question['category'],
                                            style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                        ],
                                      ),
                                      80,
                                    ),
                                    _buildListCell(
                                      GestureDetector(
                                        onTap: () async {
                                          final result = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => MondaiDetailPage(
                                                vocab: question,
                                              ),
                                            ),
                                          );
                                          if (result != null) {
                                            _loadFromApi();
                                          }
                                        },
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              question['question'].split('\n')[0],
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Colors.blue,
                                                decoration: TextDecoration.underline,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if (question['question'].contains('\n')) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                question['question'].split('\n')[1],
                                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      250,
                                    ),
                                    _buildListCell(
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            question['correctAnswer'].split('\n')[0],
                                            style: const TextStyle(fontSize: 13),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (question['correctAnswer'].contains('\n')) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              question['correctAnswer'].split('\n')[1],
                                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ],
                                      ),
                                      150,
                                    ),
                                    _buildListCell(
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(question['songName'], style: const TextStyle(fontSize: 13)),
                                          const SizedBox(height: 4),
                                          Text(question['artist'],
                                            style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                        ],
                                      ),
                                      180,
                                    ),
                                    _buildListCell(
                                      Center(
                                        child: Text(
                                          question['status'],
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: question['status'] == '有効' ? Colors.black : Colors.grey[400],
                                          ),
                                        ),
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
              '該当する問題が見つかりません',
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
            child: const Text('選択中の問題を無効化', style: TextStyle(fontSize: 14)),
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
            child: const Text('選択中の問題を有効化', style: TextStyle(fontSize: 14)),
          ),
          const SizedBox(width: 12),
        ],
        ElevatedButton(
          onPressed: () {
            showTourokuDialog(
              context,
              'mondai',
              (data) {
                // 追加後にリロード
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
    questionController.dispose();
    correctAnswerController.dispose();
    songNameController.dispose();
    artistController.dispose();
    super.dispose();
  }
}
