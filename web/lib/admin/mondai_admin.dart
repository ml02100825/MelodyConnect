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

  // プルダウンオプション（一覧から抽出）
  List<String> _questionFormatOptions = ['問題形式'];
  List<String> _difficultyLevelOptions = ['難易度'];

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
        if (categoryFilter == '穴埋め') questionFormat = 'FILL_IN_BLANK';
        if (categoryFilter == 'リスニング') questionFormat = 'LISTENING';
      }

      bool? isActive;
      if (statusFilter == '有効') {
        isActive = true;
      } else if (statusFilter == '無効') {
        isActive = false;
      }

      String? idSearch;
      if (idController.text.trim().isNotEmpty) {
        idSearch = idController.text.trim();
      }

      int? artistId;
      if (artistController.text.trim().isNotEmpty) {
        artistId = int.tryParse(artistController.text.trim());
      }

      int? difficultyLevel;
      if (difficultyFilter != '難易度') {
        difficultyLevel = int.tryParse(difficultyFilter);
      }

      final response = await AdminApiService.getQuestions(
        page: _currentPage,
        size: _pageSize,
        idSearch: idSearch,
        artistId: artistId,
        questionFormat: questionFormat,
        difficultyLevel: difficultyLevel,
        isActive: isActive,
      );

      final content = response['questions'] as List<dynamic>? ?? [];
      final loadedQuestions = content.map((json) {
        return {
          'questionId': json['questionId'] ?? 0,
          'songId': json['songId'] ?? 0,
          'songName': json['songName'] ?? '',
          'artistId': json['artistId'] ?? 0,
          'artistName': json['artistName'] ?? '',
          'text': json['text'] ?? '',
          'answer': json['answer'] ?? '',
          'completeSentence': json['completeSentence'] ?? '',
          'questionFormat': json['questionFormat'] ?? '',
          'difficultyLevel': json['difficultyLevel'] ?? '',
          'language': json['language'] ?? '',
          'translationJa': json['translationJa'] ?? '',
          'audioUrl': json['audioUrl'] ?? '',
          'isActive': json['isActive'] ?? false,
          'addingAt': json['addingAt'] != null
              ? DateTime.tryParse(json['addingAt']) ?? DateTime.now()
              : DateTime.now(),
          'status': (json['isActive'] == true) ? '有効' : '無効',
        };
      }).toList();

      // 一覧からユニークな問題形式と難易度を抽出
      final formats = loadedQuestions
          .map((q) => _formatQuestionFormat(q['questionFormat'] as String?))
          .where((f) => f.isNotEmpty)
          .toSet()
          .toList();
      final levels = loadedQuestions
          .map((q) => q['difficultyLevel'])
          .where((l) => l != null)
          .map((l) => int.tryParse(l.toString()))
          .whereType<int>()
          .toSet()
          .toList()
        ..sort();

      setState(() {
        questions = loadedQuestions;
        _totalPages = response['totalPages'] ?? 1;
        _totalElements = response['totalElements'] ?? 0;
        selectedRows = List.generate(questions.length, (index) => false);
        _questionFormatOptions = ['問題形式', ...formats];
        _difficultyLevelOptions = ['難易度', ...levels.map((level) => level.toString())];
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
        selectedIds.add(questions[i]['questionId'] as int);
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
        selectedIds.add(questions[i]['questionId'] as int);
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
                _questionFormatOptions, (value) {
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
                _difficultyLevelOptions, (value) {
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
    final uniqueItems = items.toSet().toList();
    final selectedValue = uniqueItems.contains(value) ? value : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
        ),
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
          value: selectedValue,
          items: uniqueItems
              .map((item) => DropdownMenuItem(
                    value: item,
                    child: Text(
                      item,
                      style: const TextStyle(fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                    ),
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

  String _formatQuestionFormat(String? format) {
    switch (format) {
      case 'FILL_IN_BLANK':
      case 'FILL_IN_THE_BLANK':
        return '穴埋め';
      case 'LISTENING':
        return 'リスニング';
      default:
        return '';
    }
  }

  String _truncateToFiveChars(String text) {
    if (text.length <= 5) return text;
    return '${text.substring(0, 5)}...';
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
                _buildListHeader('ID/問題形式', 80),
                _buildListHeader('問題文\n和訳', 250),
                _buildListHeader('正答', 150),
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
                                          Text(
                                            question['questionId'].toString(),
                                            style: const TextStyle(fontSize: 13),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _truncateToFiveChars(
                                              _formatQuestionFormat(question['questionFormat'] as String?),
                                            ),
                                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            softWrap: false,
                                          ),
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
                                                vocab: {
                                                  'id': question['questionId'].toString(),
                                                  'question': question['text'],
                                                  'correctAnswer': question['answer'],
                                                  'category': _formatQuestionFormat(
                                                      question['questionFormat'] as String?),
                                                  'difficulty': question['difficultyLevel'],
                                                  'status': question['status'],
                                                  'addedDate': question['addingAt'],
                                                  'songName': question['songName'],
                                                  'artist': question['artistName'],
                                                },
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
                                              question['text'].split('\n')[0],
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Colors.blue,
                                                decoration: TextDecoration.underline,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if ((question['translationJa'] ?? '').toString().isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                question['translationJa'] ?? '',
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
                                            question['answer'].split('\n')[0],
                                            style: const TextStyle(fontSize: 13),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (question['answer'].contains('\n')) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              question['answer'].split('\n')[1],
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
                                          Text(question['artistName'],
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
