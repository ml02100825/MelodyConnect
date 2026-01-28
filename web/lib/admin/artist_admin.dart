import 'package:flutter/material.dart';
import 'bottom_admin.dart';
import 'artist_detail_admin.dart';
import 'touroku_admin.dart';
import 'services/admin_api_service.dart';

class Artist {
  final String id;
  final String name;
  final String genre;
  final String status;
  final bool isActive;
  final DateTime addedDate;
  final DateTime? updatedDate;
  final String? artistApiId;
  final String? imageUrl;
  final int numericId;

  Artist({
    required this.id,
    required this.name,
    required this.genre,
    required this.status,
    required this.isActive,
    required this.addedDate,
    this.updatedDate,
    this.artistApiId,
    this.imageUrl,
    required this.numericId,
  });

  factory Artist.fromJson(Map<String, dynamic> json) {
    return Artist(
      id: json['artistId']?.toString() ?? '',
      name: json['artistName'] ?? '',
      genre: json['genreName'] ?? '',
      status: (json['isActive'] == true) ? '有効' : '無効',
      isActive: json['isActive'] == true,
      addedDate: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      updatedDate: json['lastSyncedAt'] != null
          ? DateTime.tryParse(json['lastSyncedAt'])
          : null,
      artistApiId: json['artistApiId'],
      imageUrl: json['imageUrl'],
      numericId: json['artistId'] as int? ?? 0,
    );
  }

  Artist copyWith({
    String? id,
    String? name,
    String? genre,
    String? status,
    bool? isActive,
    DateTime? addedDate,
    DateTime? updatedDate,
    String? artistApiId,
    String? imageUrl,
    int? numericId,
  }) {
    return Artist(
      id: id ?? this.id,
      name: name ?? this.name,
      genre: genre ?? this.genre,
      status: status ?? this.status,
      isActive: isActive ?? this.isActive,
      addedDate: addedDate ?? this.addedDate,
      updatedDate: updatedDate ?? this.updatedDate,
      artistApiId: artistApiId ?? this.artistApiId,
      imageUrl: imageUrl ?? this.imageUrl,
      numericId: numericId ?? this.numericId,
    );
  }
}

class ArtistAdmin extends StatefulWidget {
  const ArtistAdmin({Key? key}) : super(key: key);

  @override
  State<ArtistAdmin> createState() => _ArtistAdminState();
}

class _ArtistAdminState extends State<ArtistAdmin> {
  String selectedTab = 'アーティスト';
  String selectedMenu = 'コンテンツ管理';

  List<Artist> artists = [];
  List<bool> selectedRows = [];
  bool hasSelection = false;

  // 検索条件
  String idSearch = '';
  String artistSearch = '';
  String? genreFilter;
  String? statusFilter;
  DateTime? addedStart;
  DateTime? addedEnd;
  bool _sortAscending = false;

  // API連携用
  int _currentPage = 0;
  int _totalPages = 1;
  int _totalElements = 0;
  final int _pageSize = 20;
  bool _isLoading = false;
  String? _error;

  // ジャンルオプション（APIから取得）
  List<String> genreOptions = [];

  @override
  void initState() {
    super.initState();
    _loadGenres();
    _loadFromApi();
  }

  Future<void> _loadGenres() async {
    try {
      final response = await AdminApiService.getGenres(size: 100);
      final genres = (response['genres'] as List<dynamic>? ?? [])
          .map((g) => g['name'] as String)
          .toList();
      if (mounted) {
        setState(() {
          genreOptions = genres;
        });
      }
    } catch (e) {
      // エラー時は空リストのまま
    }
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

      final response = await AdminApiService.getArtists(
        page: _currentPage,
        size: _pageSize,
        idSearch: idSearch.trim().isNotEmpty ? idSearch.trim() : null,
        artistName: artistSearch.trim().isNotEmpty ? artistSearch.trim() : null,
        isActive: isActive,
        genreName: genreFilter,
        createdFrom: addedStart,
        createdTo: addedEnd,
        sortDirection: _sortAscending ? 'asc' : 'desc',
      );

      final content = response['artists'] as List<dynamic>? ?? [];
      final loadedArtists = content.map((json) => Artist.fromJson(json)).toList();

      setState(() {
        artists = loadedArtists;
        _totalPages = response['totalPages'] ?? 1;
        _totalElements = response['totalElements'] ?? 0;
        selectedRows = List.generate(artists.length, (index) => false);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'データの取得に失敗しました: $e';
        _isLoading = false;
      });
    }
  }

  void _searchArtists() {
    _currentPage = 0;
    _loadFromApi();
  }

  void _clearSearch() {
    setState(() {
      idSearch = '';
      artistSearch = '';
      genreFilter = null;
      statusFilter = null;
      addedStart = null;
      addedEnd = null;
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
        selectedRows = List.generate(artists.length, (index) => true);
      } else {
        selectedRows = List.generate(artists.length, (index) => false);
      }
      _updateSelectionState();
    });
  }

  void _toggleArtistSelection(int index, bool? value) {
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

  Future<void> _deactivateSelected() async {
    final selectedIds = <int>[];
    for (int i = 0; i < selectedRows.length; i++) {
      if (selectedRows[i] && i < artists.length) {
        selectedIds.add(artists[i].numericId);
      }
    }

    if (selectedIds.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await AdminApiService.disableArtists(selectedIds);
      await _loadFromApi();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('選択したアーティストを無効化しました')),
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
      if (selectedRows[i] && i < artists.length) {
        selectedIds.add(artists[i].numericId);
      }
    }

    if (selectedIds.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await AdminApiService.enableArtists(selectedIds);
      await _loadFromApi();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('選択したアーティストを有効化しました')),
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

  Future<void> _navigateToDetailPage(Artist artist, {bool isNew = false}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ArtistDetailAdmin(
          artist: artist,
          isNew: isNew,
          onStatusChanged: (updatedArtist, action) {
            _loadFromApi();
          },
        ),
      ),
    );

    if (result != null) {
      _loadFromApi();
    }
  }

  void _showTourokuDialog() {
    showTourokuDialog(
      context,
      'artist',
      (data) {
        _loadFromApi();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('アーティストを登録しました')),
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
        selectedTab: selectedTab,
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
        Align(
          alignment: Alignment.centerRight,
          child: _buildSortToggle(),
        ),
        const SizedBox(height: 16),

        // アーティスト一覧テーブル
        Expanded(
          child: _buildArtistTable(),
        ),

        // ページネーション
        _buildPagination(),
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
                      _buildVerticalSearchField('アーティスト', (value) => artistSearch = value),
                    ],
                  ),
                ),
                const SizedBox(width: 32),

                // 2列目
                Expanded(
                  child: Column(
                    children: [
                      _buildVerticalDropdown('ジャンル', ['全て', ...genreOptions], (value) => genreFilter = value),
                      const SizedBox(height: 16),
                      _buildVerticalDateField(
                        '追加日',
                        (date) => addedStart = date,
                        (date) => addedEnd = date,
                        addedStart,
                        addedEnd,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // 3列目
                Expanded(
                  child: Column(
                    children: [
                      _buildVerticalDropdown('状態', ['全て', '有効', '無効'], (value) => statusFilter = value),
                      const SizedBox(height: 16),
                      // ボタンエリア
                      Container(
                        padding: const EdgeInsets.only(top: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            SizedBox(
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
                            SizedBox(
                              width: 100,
                              child: ElevatedButton(
                                onPressed: _searchArtists,
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
          width: 100,
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
                          lastDate: endDate ?? DateTime(2100),
                        );
                        if (date != null) {
                          onStartChanged(date);
                          if (endDate != null && date.isAfter(endDate)) {
                            onEndChanged(date);
                          }
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
                                  ? '${startDate.year}/${startDate.month.toString().padLeft(2, '0')}/${startDate.day.toString().padLeft(2, '0')}'
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
                          firstDate: startDate ?? DateTime(2000),
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
                                  ? '${endDate.year}/${endDate.month.toString().padLeft(2, '0')}/${endDate.day.toString().padLeft(2, '0')}'
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

  Widget _buildVerticalDropdown(
      String label, List<String> options, Function(String?) onChanged) {
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
          child: DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 8),
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

  Widget _buildArtistTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          // テーブルヘッダー
          if (artists.isNotEmpty || _isLoading)
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
                  _buildTableHeader('ID', 1),
                  _buildTableHeader('アーティスト', 2),
                  _buildTableHeader('ジャンル', 2),
                  _buildTableHeader('状態', 1),
                ],
              ),
            ),

          // テーブルデータまたは該当なしメッセージ
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildErrorView()
                    : artists.isEmpty
                        ? _buildNoArtistsFound()
                        : ListView.builder(
                            itemCount: artists.length,
                            itemBuilder: (context, index) {
                              final artist = artists[index];
                              return Container(
                                decoration: BoxDecoration(
                                  border: Border(
                                    left: const BorderSide(color: Colors.grey),
                                    right: const BorderSide(color: Colors.grey),
                                    bottom: BorderSide(color: Colors.grey[300]!),
                                  ),
                                ),
                                child: InkWell(
                                  onTap: () => _navigateToDetailPage(artist),
                                  child: Row(
                                    children: [
                                      _buildTableCell(
                                        '',
                                        1,
                                        TextAlign.center,
                                        child: Checkbox(
                                          value: selectedRows[index],
                                          onChanged: (value) => _toggleArtistSelection(index, value),
                                        ),
                                      ),
                                      _buildTableCell(artist.id, 1, TextAlign.center),
                                      _buildTableCell(artist.name, 2, TextAlign.left),
                                      _buildTableCell(artist.genre, 2, TextAlign.left),
                                      _buildTableCell('', 1, TextAlign.center,
                                          child: _buildStatusIndicator(artist.status)),
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

  Widget _buildNoArtistsFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            '該当アーティストが見つかりません',
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

  Widget _buildButtonsArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // 選択中のアーティストを無効化ボタン
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
                child: const Text('選択中のアーティストを無効化', style: TextStyle(color: Colors.white)),
              ),
            ),

          // 選択中のアーティストを有効化ボタン
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
                onPressed: _activateSelected,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: const Text('選択中のアーティストを有効化', style: TextStyle(color: Colors.white)),
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
                value: selectedRows.isNotEmpty &&
                    selectedRows.every((element) => element) &&
                    artists.isNotEmpty,
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
