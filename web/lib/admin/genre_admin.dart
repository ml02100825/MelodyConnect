import 'package:flutter/material.dart';
import 'bottom_admin.dart';
import 'genre_detail_admin.dart';
import 'touroku_admin.dart';

class Genre {
  final String id;
  final String name;
  final String status;
  final bool isActive;
  final DateTime addedDate;
  final DateTime? updatedDate;

  Genre({
    required this.id,
    required this.name,
    required this.status,
    required this.isActive,
    required this.addedDate,
    this.updatedDate,
  });

  Genre copyWith({
    String? id,
    String? name,
    String? status,
    bool? isActive,
    DateTime? addedDate,
    DateTime? updatedDate,
  }) {
    return Genre(
      id: id ?? this.id,
      name: name ?? this.name,
      status: status ?? this.status,
      isActive: isActive ?? this.isActive,
      addedDate: addedDate ?? this.addedDate,
      updatedDate: updatedDate ?? this.updatedDate,
    );
  }
}

class GenreAdmin extends StatefulWidget {
  const GenreAdmin({Key? key}) : super(key: key);

  @override
  State<GenreAdmin> createState() => _GenreAdminState();
}

class _GenreAdminState extends State<GenreAdmin> {
  String selectedTab = 'ジャンル';
  String selectedMenu = 'コンテンツ管理';
  
  List<Genre> genres = [];
  List<Genre> filteredGenres = [];
  List<bool> selectedRows = [];
  bool hasSelection = false;

  // 検索条件
  String idSearch = '';
  String genreSearch = '';
  DateTime? addedStart;
  DateTime? addedEnd;

  @override
  void initState() {
    super.initState();
    _loadSampleData();
  }

  void _loadSampleData() {
    genres = [
      Genre(
        id: '00001',
        name: 'ジャンル01',
        status: '有効',
        isActive: true,
        addedDate: DateTime(2024, 1, 1),
        updatedDate: DateTime(2024, 1, 1),
      ),
      Genre(
        id: '00002',
        name: 'ジャンル02',
        status: '有効',
        isActive: true,
        addedDate: DateTime(2024, 1, 15),
        updatedDate: DateTime(2024, 1, 15),
      ),
      Genre(
        id: '00003',
        name: 'ジャンル03',
        status: '有効',
        isActive: true,
        addedDate: DateTime(2024, 2, 1),
        updatedDate: DateTime(2024, 2, 1),
      ),
      Genre(
        id: '00004',
        name: 'ジャンル04',
        status: '無効',
        isActive: false,
        addedDate: DateTime(2024, 2, 15),
        updatedDate: DateTime(2024, 2, 15),
      ),
    ];
    filteredGenres = List.from(genres);
    selectedRows = List.generate(filteredGenres.length, (index) => false);
  }

  void _searchGenres() {
    setState(() {
      filteredGenres = genres.where((genre) {
        bool matches = true;

        if (idSearch.isNotEmpty && !genre.id.contains(idSearch)) {
          matches = false;
        }
        if (genreSearch.isNotEmpty && !genre.name.contains(genreSearch)) {
          matches = false;
        }

        // 追加日フィルター
        if (addedStart != null && addedEnd != null) {
          final isWithinRange = genre.addedDate.isAfter(addedStart!.subtract(const Duration(days: 1))) &&
                               genre.addedDate.isBefore(addedEnd!.add(const Duration(days: 1)));
          if (!isWithinRange) {
            matches = false;
          }
        }

        return matches;
      }).toList();

      selectedRows = List.generate(filteredGenres.length, (index) => false);
      _updateSelectionState();
    });
  }

  void _clearSearch() {
    setState(() {
      idSearch = '';
      genreSearch = '';
      addedStart = null;
      addedEnd = null;

      filteredGenres = List.from(genres);
      selectedRows = List.generate(filteredGenres.length, (index) => false);
      _updateSelectionState();
    });
  }

  void _toggleAllSelection(bool? value) {
    setState(() {
      if (value == true) {
        selectedRows = List.generate(filteredGenres.length, (index) => true);
      } else {
        selectedRows = List.generate(filteredGenres.length, (index) => false);
      }
      _updateSelectionState();
    });
  }

  void _toggleGenreSelection(int index, bool? value) {
    setState(() {
      selectedRows[index] = value ?? false;
      _updateSelectionState();
    });
  }

  void _updateSelectionState() {
    setState(() {
      hasSelection = selectedRows.any((selected) => selected);
    });
  }

  void _deactivateSelected() {
    setState(() {
      for (int i = 0; i < selectedRows.length; i++) {
        if (selectedRows[i]) {
          final genreId = filteredGenres[i].id;
          final originalIndex = genres.indexWhere((g) => g.id == genreId);
          if (originalIndex != -1) {
            genres[originalIndex] = genres[originalIndex].copyWith(
              status: '無効',
              isActive: false,
              updatedDate: DateTime.now(),
            );
          }
          filteredGenres[i] = filteredGenres[i].copyWith(
            status: '無効',
            isActive: false,
            updatedDate: DateTime.now(),
          );
        }
      }
      _updateSelectionState();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('選択したジャンルを無効化しました')),
    );
  }

  void _activateSelected() {
    setState(() {
      for (int i = 0; i < selectedRows.length; i++) {
        if (selectedRows[i]) {
          final genreId = filteredGenres[i].id;
          final originalIndex = genres.indexWhere((g) => g.id == genreId);
          if (originalIndex != -1) {
            genres[originalIndex] = genres[originalIndex].copyWith(
              status: '有効',
              isActive: true,
              updatedDate: DateTime.now(),
            );
          }
          filteredGenres[i] = filteredGenres[i].copyWith(
            status: '有効',
            isActive: true,
            updatedDate: DateTime.now(),
          );
        }
      }
      _updateSelectionState();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('選択したジャンルを有効化しました')),
    );
  }

  Future<void> _navigateToDetailPage(Genre genre, {bool isNew = false}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GenreDetailAdmin(
          genre: genre,
          isNew: isNew,
          onStatusChanged: (updatedGenre, action) {
            // 状態変更を即時反映
            _handleGenreUpdate(updatedGenre, action);
          },
        ),
      ),
    );

    if (result != null) {
      _handleGenreUpdate(result['genre'] as Genre, result['action']);
    }
  }

  void _handleGenreUpdate(Genre updatedGenre, String action) {
    setState(() {
      switch (action) {
        case 'save':
          if (genres.any((g) => g.id == updatedGenre.id)) {
            // 既存のジャンルを更新
            final index = genres.indexWhere((g) => g.id == updatedGenre.id);
            if (index != -1) {
              genres[index] = updatedGenre;
            }
          } else {
            // 新規ジャンルを追加
            genres.add(updatedGenre);
          }
          break;
        case 'delete':
          // ジャンルを削除
          genres.removeWhere((g) => g.id == updatedGenre.id);
          break;
        case 'status_changed':
          // 状態変更のみ
          final index = genres.indexWhere((g) => g.id == updatedGenre.id);
          if (index != -1) {
            genres[index] = updatedGenre;
          }
          break;
      }

      // フィルター適用
      filteredGenres = genres.where((genre) {
        bool matches = true;

        if (idSearch.isNotEmpty && !genre.id.contains(idSearch)) {
          matches = false;
        }
        if (genreSearch.isNotEmpty && !genre.name.contains(genreSearch)) {
          matches = false;
        }

        if (addedStart != null && addedEnd != null) {
          final isWithinRange = genre.addedDate.isAfter(addedStart!.subtract(const Duration(days: 1))) &&
                               genre.addedDate.isBefore(addedEnd!.add(const Duration(days: 1)));
          if (!isWithinRange) {
            matches = false;
          }
        }

        return matches;
      }).toList();

      selectedRows = List.generate(filteredGenres.length, (index) => false);
      _updateSelectionState();

      // スナックバー表示
      String message = '';
      switch (action) {
        case 'save':
          message = 'ジャンルを保存しました';
          break;
        case 'delete':
          message = 'ジャンルを削除しました';
          break;
        case 'status_changed':
          message = '状態を変更しました';
          break;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    });
  }

  void _showTourokuDialog() {
    showTourokuDialog(
      context,
      'genre',
      (data) {
        final newGenre = Genre(
          id: '${(genres.length + 1).toString().padLeft(5, '0')}',
          name: data['name'],
          status: '有効',
          isActive: true,
          addedDate: DateTime.now(),
        );

        genres.add(newGenre);
        filteredGenres = List.from(genres);
        selectedRows = List.generate(filteredGenres.length, (index) => false);
        _updateSelectionState();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ジャンルを登録しました')),
        );
      },
    );
  }

  Widget _buildStatusIndicator(String status) {
    final isActive = status == '有効';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.green[100] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          color: isActive ? Colors.green[800] : Colors.grey[800],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: BottomAdminLayout(
        selectedMenu: selectedMenu,
        onMenuSelected: (menu) {
          setState(() {
            selectedMenu = menu;
          });
        },
        selectedTab: selectedTab,
        onTabSelected: (tab) {
          if (tab != null) {
            setState(() {
              selectedTab = tab;
            });
          }
        },
        showTabs: true,
        mainContent: _buildMainContent(),
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        // 検索条件エリア
        _buildVerticalSearchArea(),
        const SizedBox(height: 16),
        
        // ジャンル一覧テーブル
        Expanded(
          child: _buildGenreTable(),
        ),
      ],
    );
  }

  Widget _buildVerticalSearchArea() {
    return Container(
      padding: const EdgeInsets.all(16),
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
                      const SizedBox(height: 16),
                      _buildVerticalSearchField('ジャンル名', (value) => genreSearch = value),
                    ],
                  ),
                ),
                const SizedBox(width: 32),
                
                // 2列目
                Expanded(
                  child: Column(
                    children: [
                      _buildVerticalDateField(
                        '追加日',
                        (date) => addedStart = date,
                        (date) => addedEnd = date,
                        addedStart,
                        addedEnd,
                      ),
                      const SizedBox(height: 32), // 高さ調整用
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                
                // 3列目
                Expanded(
                  child: Column(
                    children: [
                      // ボタンエリア
                      Container(
                        padding: const EdgeInsets.only(top: 68), // 高さ調整
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              width: 100,
                              child: OutlinedButton(
                                onPressed: _clearSearch,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.grey[700],
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: const Text('クリア', style: TextStyle(color: Colors.black)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 100,
                              child: ElevatedButton(
                                onPressed: _searchGenres,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue[700],
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: const Text('検索', style: TextStyle(color: Colors.white)),
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
          width: 80,
          padding: const EdgeInsets.only(top: 12),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            decoration: const InputDecoration(
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
          width: 80,
          padding: const EdgeInsets.only(top: 12),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
        ),
        const SizedBox(width: 8),
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
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[400]!),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Text(
                              startDate != null
                                  ? '${startDate!.year}/${startDate!.month.toString().padLeft(2, '0')}/${startDate!.day.toString().padLeft(2, '0')}'
                                  : '',
                              style: TextStyle(
                                color: startDate != null
                                    ? Colors.black
                                    : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '〜',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 8),
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
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[400]!),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Text(
                              endDate != null
                                  ? '${endDate!.year}/${endDate!.month.toString().padLeft(2, '0')}/${endDate!.day.toString().padLeft(2, '0')}'
                                  : '',
                              style: TextStyle(
                                color: endDate != null
                                    ? Colors.black
                                    : Colors.grey[600],
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

  Widget _buildGenreTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          // テーブルヘッダー
          if (filteredGenres.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  _buildTableHeader('', 1),
                  _buildTableHeader('ID', 2),
                  _buildTableHeader('ジャンル名', 3),
                  _buildTableHeader('状態', 2),
                ],
              ),
            ),
          
          // テーブルデータまたは該当なしメッセージ
          Expanded(
            child: filteredGenres.isEmpty
                ? _buildNoGenresFound()
                : ListView.builder(
                    itemCount: filteredGenres.length,
                    itemBuilder: (context, index) {
                      final genre = filteredGenres[index];
                      return Container(
                        decoration: BoxDecoration(
                          border: Border(
                            left: const BorderSide(color: Colors.grey),
                            right: const BorderSide(color: Colors.grey),
                            bottom: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        child: InkWell(
                          onTap: () => _navigateToDetailPage(genre),
                          child: Row(
                            children: [
                              _buildTableCell(
                                '',
                                1,
                                TextAlign.center,
                                child: Checkbox(
                                  value: selectedRows[index],
                                  onChanged: (value) => _toggleGenreSelection(index, value),
                                ),
                              ),
                              _buildTableCell(genre.id, 2, TextAlign.center),
                              _buildTableCell(genre.name, 3, TextAlign.left),
                              _buildTableCell('', 2, TextAlign.center, 
                                child: _buildStatusIndicator(genre.status)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          
          // 全てのボタンを同じ行に表示
          _buildButtonsArea(),
        ],
      ),
    );
  }

  Widget _buildNoGenresFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.category, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            '該当ジャンルが見つかりません',
            style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '検索条件を変更して再度お試しください',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildButtonsArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // 選択中のジャンルを無効化ボタン
          if (hasSelection)
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(2, 2),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _deactivateSelected,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: const Text('選択中のジャンルを無効化', style: TextStyle(color: Colors.white)),
              ),
            ),
          
          // 選択中のジャンルを有効化ボタン
          if (hasSelection)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(2, 2),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _activateSelected,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: const Text('選択中のジャンルを有効化', style: TextStyle(color: Colors.white)),
              ),
            ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(2, 2),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _showTourokuDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: const Text('追加作成', style: TextStyle(color: Colors.white)),
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
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          border: Border(right: BorderSide(color: Colors.grey[300]!)),
        ),
        child: text.isEmpty
            ? Checkbox(
                value: selectedRows.every((element) => element) &&
                    selectedRows.isNotEmpty,
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
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
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