import 'package:flutter/material.dart';
import 'bottom_admin.dart';
import 'artist_detail_admin.dart';
import 'touroku_admin.dart';

class Artist {
  final String id;
  final String name;
  final String genre;
  final String status;
  final bool isActive;
  final DateTime addedDate;
  final DateTime? updatedDate;
  final String? genreId;
  final String? artistApiId;
  final String? imageUrl;

  Artist({
    required this.id,
    required this.name,
    required this.genre,
    required this.status,
    required this.isActive,
    required this.addedDate,
    this.updatedDate,
    this.genreId,
    this.artistApiId,
    this.imageUrl,
  });

  Artist copyWith({
    String? id,
    String? name,
    String? genre,
    String? status,
    bool? isActive,
    DateTime? addedDate,
    DateTime? updatedDate,
    String? genreId,
    String? artistApiId,
    String? imageUrl,
  }) {
    return Artist(
      id: id ?? this.id,
      name: name ?? this.name,
      genre: genre ?? this.genre,
      status: status ?? this.status,
      isActive: isActive ?? this.isActive,
      addedDate: addedDate ?? this.addedDate,
      updatedDate: updatedDate ?? this.updatedDate,
      genreId: genreId ?? this.genreId,
      artistApiId: artistApiId ?? this.artistApiId,
      imageUrl: imageUrl ?? this.imageUrl,
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
  List<Artist> filteredArtists = [];
  List<bool> selectedRows = [];
  bool hasSelection = false;

  // 検索条件
  String idSearch = '';
  String artistSearch = '';
  String? genreFilter;
  String? statusFilter;
  DateTime? addedStart;
  DateTime? addedEnd;

  // ジャンルオプション
  final List<String> genreOptions = [
    'ジャンル01',
    'ジャンル02',
    'ジャンル03',
    'ジャンル04',
  ];

  @override
  void initState() {
    super.initState();
    _loadSampleData();
  }

  void _loadSampleData() {
    artists = [
      Artist(
        id: '00001',
        name: 'アーティスト01',
        genre: 'ジャンル01',
        status: '有効',
        isActive: true,
        addedDate: DateTime(2024, 1, 1),
        updatedDate: DateTime(2024, 1, 1),
        genreId: '00001',
        artistApiId: 'API001',
        imageUrl: 'https://example.com/artist1.png',
      ),
      Artist(
        id: '00002',
        name: 'アーティスト02',
        genre: 'ジャンル02',
        status: '有効',
        isActive: true,
        addedDate: DateTime(2024, 1, 15),
        updatedDate: DateTime(2024, 1, 15),
        genreId: '00002',
        artistApiId: 'API002',
        imageUrl: 'https://example.com/artist2.png',
      ),
      Artist(
        id: '00003',
        name: 'アーティスト03',
        genre: 'ジャンル03',
        status: '有効',
        isActive: true,
        addedDate: DateTime(2024, 2, 1),
        updatedDate: DateTime(2024, 2, 1),
        genreId: '00003',
        artistApiId: 'API003',
        imageUrl: 'https://example.com/artist3.png',
      ),
      Artist(
        id: '00004',
        name: 'アーティスト04',
        genre: 'ジャンル04',
        status: '無効',
        isActive: false,
        addedDate: DateTime(2024, 2, 15),
        updatedDate: DateTime(2024, 2, 15),
        genreId: '00004',
        artistApiId: 'API004',
        imageUrl: 'https://example.com/artist4.png',
      ),
    ];
    filteredArtists = List.from(artists);
    selectedRows = List.generate(filteredArtists.length, (index) => false);
  }

  void _searchArtists() {
    setState(() {
      filteredArtists = artists.where((artist) {
        bool matches = true;

        if (idSearch.isNotEmpty && !artist.id.contains(idSearch)) {
          matches = false;
        }
        if (artistSearch.isNotEmpty && !artist.name.contains(artistSearch)) {
          matches = false;
        }
        if (genreFilter != null && artist.genre != genreFilter) {
          matches = false;
        }
        if (statusFilter != null && artist.status != statusFilter) {
          matches = false;
        }

        // 追加日フィルター
        if (addedStart != null && addedEnd != null) {
          final isWithinRange = artist.addedDate.isAfter(addedStart!.subtract(const Duration(days: 1))) &&
                               artist.addedDate.isBefore(addedEnd!.add(const Duration(days: 1)));
          if (!isWithinRange) {
            matches = false;
          }
        }

        return matches;
      }).toList();

      selectedRows = List.generate(filteredArtists.length, (index) => false);
      _updateSelectionState();
    });
  }

  void _clearSearch() {
    setState(() {
      idSearch = '';
      artistSearch = '';
      genreFilter = null;
      statusFilter = null;
      addedStart = null;
      addedEnd = null;

      filteredArtists = List.from(artists);
      selectedRows = List.generate(filteredArtists.length, (index) => false);
      _updateSelectionState();
    });
  }

  void _toggleAllSelection(bool? value) {
    setState(() {
      if (value == true) {
        selectedRows = List.generate(filteredArtists.length, (index) => true);
      } else {
        selectedRows = List.generate(filteredArtists.length, (index) => false);
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

  void _deactivateSelected() {
    setState(() {
      for (int i = 0; i < selectedRows.length; i++) {
        if (selectedRows[i]) {
          final artistId = filteredArtists[i].id;
          final originalIndex = artists.indexWhere((a) => a.id == artistId);
          if (originalIndex != -1) {
            artists[originalIndex] = artists[originalIndex].copyWith(
              status: '無効',
              isActive: false,
              updatedDate: DateTime.now(),
            );
          }
          filteredArtists[i] = filteredArtists[i].copyWith(
            status: '無効',
            isActive: false,
            updatedDate: DateTime.now(),
          );
        }
      }
      _updateSelectionState();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('選択したアーティストを無効化しました')),
    );
  }

  void _activateSelected() {
    setState(() {
      for (int i = 0; i < selectedRows.length; i++) {
        if (selectedRows[i]) {
          final artistId = filteredArtists[i].id;
          final originalIndex = artists.indexWhere((a) => a.id == artistId);
          if (originalIndex != -1) {
            artists[originalIndex] = artists[originalIndex].copyWith(
              status: '有効',
              isActive: true,
              updatedDate: DateTime.now(),
            );
          }
          filteredArtists[i] = filteredArtists[i].copyWith(
            status: '有効',
            isActive: true,
            updatedDate: DateTime.now(),
          );
        }
      }
      _updateSelectionState();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('選択したアーティストを有効化しました')),
    );
  }

  Future<void> _navigateToDetailPage(Artist artist, {bool isNew = false}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ArtistDetailAdmin(
          artist: artist,
          isNew: isNew,
          onStatusChanged: (updatedArtist, action) {
            // 状態変更を即時反映
            _handleArtistUpdate(updatedArtist, action);
          },
        ),
      ),
    );

    if (result != null) {
      _handleArtistUpdate(result['artist'] as Artist, result['action']);
    }
  }

  void _handleArtistUpdate(Artist updatedArtist, String action) {
    setState(() {
      switch (action) {
        case 'save':
          if (artists.any((a) => a.id == updatedArtist.id)) {
            // 既存のアーティストを更新
            final index = artists.indexWhere((a) => a.id == updatedArtist.id);
            if (index != -1) {
              artists[index] = updatedArtist;
            }
          } else {
            // 新規アーティストを追加
            artists.add(updatedArtist);
          }
          break;
        case 'delete':
          // アーティストを削除
          artists.removeWhere((a) => a.id == updatedArtist.id);
          break;
        case 'status_changed':
          // 状態変更のみ
          final index = artists.indexWhere((a) => a.id == updatedArtist.id);
          if (index != -1) {
            artists[index] = updatedArtist;
          }
          break;
      }

      // フィルター適用
      filteredArtists = artists.where((artist) {
        bool matches = true;

        if (idSearch.isNotEmpty && !artist.id.contains(idSearch)) {
          matches = false;
        }
        if (artistSearch.isNotEmpty && !artist.name.contains(artistSearch)) {
          matches = false;
        }
        if (genreFilter != null && artist.genre != genreFilter) {
          matches = false;
        }
        if (statusFilter != null && artist.status != statusFilter) {
          matches = false;
        }

        if (addedStart != null && addedEnd != null) {
          final isWithinRange = artist.addedDate.isAfter(addedStart!.subtract(const Duration(days: 1))) &&
                               artist.addedDate.isBefore(addedEnd!.add(const Duration(days: 1)));
          if (!isWithinRange) {
            matches = false;
          }
        }

        return matches;
      }).toList();

      selectedRows = List.generate(filteredArtists.length, (index) => false);
      _updateSelectionState();

      // スナックバー表示
      String message = '';
      switch (action) {
        case 'save':
          message = 'アーティストを保存しました';
          break;
        case 'delete':
          message = 'アーティストを削除しました';
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
      'artist',
      (data) {
        final newArtist = Artist(
          id: 'NEW${(artists.length + 1).toString().padLeft(5, '0')}',
          name: data['name'],
          genre: data['genre'],
          status: '有効',
          isActive: true,
          addedDate: DateTime.now(),
          genreId: data['genreId'].isNotEmpty ? data['genreId'] : null,
          artistApiId: data['artistApiId'].isNotEmpty ? data['artistApiId'] : null,
          imageUrl: data['imageUrl'].isNotEmpty ? data['imageUrl'] : null,
        );

        artists.add(newArtist);
        filteredArtists = List.from(artists);
        selectedRows = List.generate(filteredArtists.length, (index) => false);
        _updateSelectionState();

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
        
        // アーティスト一覧テーブル
        Expanded(
          child: _buildArtistTable(),
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
          if (filteredArtists.isNotEmpty)
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
            child: filteredArtists.isEmpty
                ? _buildNoArtistsFound()
                : ListView.builder(
                    itemCount: filteredArtists.length,
                    itemBuilder: (context, index) {
                      final artist = filteredArtists[index];
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