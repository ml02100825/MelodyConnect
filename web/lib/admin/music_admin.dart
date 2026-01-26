import 'package:flutter/material.dart';
import 'bottom_admin.dart';
import 'music_admin2.dart';
import 'touroku_admin.dart';
import 'services/admin_api_service.dart';

class MusicAdmin extends StatefulWidget {
  const MusicAdmin({super.key});

  @override
  State<MusicAdmin> createState() => _MusicAdminState();
}

class _MusicAdminState extends State<MusicAdmin> {
  String selectedTab = '楽曲';
  String selectedMenu = 'コンテンツ管理';

  // 検索フォームのコントローラー
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _songNameController = TextEditingController();
  final TextEditingController _artistController = TextEditingController();
  final TextEditingController _languageController = TextEditingController();
  DateTime? startDate;
  DateTime? endDate;

  String? _selectedGenre;
  String? _selectedStatus;

  // API連携用
  List<Map<String, dynamic>> _musicList = [];
  final Set<int> _selectedIds = {};
  int _currentPage = 0;
  int _totalPages = 1;
  int _totalElements = 0;
  final int _pageSize = 20;
  bool _isLoading = false;
  String? _error;

  // ジャンルオプション（APIから取得）
  List<String> _genreOptions = [];

  bool get hasSelection => _selectedIds.isNotEmpty;

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
          _genreOptions = genres;
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
      if (_selectedStatus == '有効') {
        isActive = true;
      } else if (_selectedStatus == '無効') {
        isActive = false;
      }

      int? artistId;
      if (_artistController.text.trim().isNotEmpty) {
        artistId = int.tryParse(_artistController.text.trim());
      }

      final response = await AdminApiService.getSongs(
        page: _currentPage,
        size: _pageSize,
        songname: _songNameController.text.trim().isNotEmpty ? _songNameController.text.trim() : null,
        artistId: artistId,
        language: _languageController.text.trim().isNotEmpty ? _languageController.text.trim() : null,
        isActive: isActive,
      );

      final content = response['songs'] as List<dynamic>? ?? [];
      final loadedSongs = content.map((json) {
        return {
          'songId': json['songId'] ?? 0,
          'artistId': json['artistId'] ?? 0,
          'artistName': json['artistName'] ?? '',
          'songname': json['songname'] ?? '',
          'spotifyTrackId': json['spotifyTrackId'] ?? '',
          'geniusSongId': json['geniusSongId'] ?? '',
          'language': json['language'] ?? '',
          'isActive': json['isActive'] ?? false,
          'createdAt': json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
          'status': (json['isActive'] == true) ? '有効' : '無効',
        };
      }).toList();

      setState(() {
        _musicList = loadedSongs;
        _totalPages = response['totalPages'] ?? 1;
        _totalElements = response['totalElements'] ?? 0;
        _selectedIds.clear();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'データの取得に失敗しました: $e';
        _isLoading = false;
      });
    }
  }

  void _performSearch() {
    _currentPage = 0;
    _loadFromApi();
  }

  void _clearSearch() {
    setState(() {
      _idController.clear();
      _songNameController.clear();
      _artistController.clear();
      _languageController.clear();
      startDate = null;
      endDate = null;
      _selectedGenre = null;
      _selectedStatus = null;
      _selectedIds.clear();
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
    if (_selectedIds.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await AdminApiService.disableSongs(_selectedIds.toList());
      await _loadFromApi();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('選択した楽曲を無効化しました')),
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
    if (_selectedIds.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await AdminApiService.enableSongs(_selectedIds.toList());
      await _loadFromApi();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('選択した楽曲を有効化しました')),
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
        Expanded(child: _buildDataTable()),
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
              Expanded(
                child: _buildSearchField('ID', _idController),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdown('ジャンル', _selectedGenre, _genreOptions, (value) {
                  setState(() {
                    _selectedGenre = value;
                  });
                }),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdown('状態', _selectedStatus, const ['有効', '無効'], (value) {
                  setState(() {
                    _selectedStatus = value;
                  });
                }),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildSearchField('楽曲名', _songNameController),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSearchField('言語', _languageController),
              ),
              const SizedBox(width: 12),
              const Expanded(child: SizedBox()),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildSearchField('アーティスト', _artistController),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateRangeCompact('追加日'),
              ),
              const SizedBox(width: 12),
              const Expanded(child: SizedBox()),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: _clearSearch,
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
                onPressed: _performSearch,
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

  Widget _buildSearchField(String label, TextEditingController controller) {
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

  Widget _buildDropdown(String label, String? value, List<String> items, Function(String?) onChanged) {
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
              children: [
                SizedBox(
                  width: 40,
                  child: Checkbox(
                    value: _selectedIds.length == _musicList.length && _musicList.isNotEmpty,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedIds.addAll(_musicList.map((e) => e['songId'] as int));
                        } else {
                          _selectedIds.clear();
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  flex: 1,
                  child: Text(
                    'ID',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                ),
                const Expanded(
                  flex: 3,
                  child: Text(
                    '楽曲名',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                ),
                const Expanded(
                  flex: 2,
                  child: Text(
                    'アーティスト',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                ),
                const Expanded(
                  flex: 1,
                  child: Text(
                    '状態',
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
                    : _musicList.isEmpty
                        ? _buildNoDataFound()
                        : ListView.builder(
                            itemCount: _musicList.length,
                            itemBuilder: (context, index) {
                              final item = _musicList[index];
                              final numericId = item['songId'] as int;
                              final isSelected = _selectedIds.contains(numericId);
                              return Container(
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(color: Colors.grey[300]!),
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 40,
                                      child: Checkbox(
                                        value: isSelected,
                                        onChanged: (value) {
                                          setState(() {
                                            if (value == true) {
                                              _selectedIds.add(numericId);
                                            } else {
                                              _selectedIds.remove(numericId);
                                            }
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      flex: 1,
                                      child: Text(
                                        item['songId'].toString(),
                                        style: const TextStyle(fontSize: 13),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: GestureDetector(
                                        onTap: () async {
                                          final result = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => MusicDetailPage(
                                                music: {
                                                  'id': item['songId'].toString(),
                                                  'songName': item['songname'],
                                                  'artistId': item['artistId'].toString(),
                                                  'status': item['status'],
                                                  'addedDate': item['createdAt']?.toString(),
                                                  'geniusSongId': item['geniusSongId']?.toString(),
                                                },
                                              ),
                                            ),
                                          );
                                          if (result != null) {
                                            _loadFromApi();
                                          }
                                        },
                                        child: Text(
                                          item['songname'] as String,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.blue,
                                            decoration: TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        item['artistName'] as String,
                                        style: const TextStyle(fontSize: 13),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Text(
                                        item['status'] as String,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: item['status'] == '有効' ? Colors.black : Colors.grey[400],
                                        ),
                                        textAlign: TextAlign.center,
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
              '該当する楽曲が見つかりません',
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
            child: const Text('選択中の楽曲を無効化', style: TextStyle(fontSize: 14)),
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
            child: const Text('選択中の楽曲を有効化', style: TextStyle(fontSize: 14)),
          ),
          const SizedBox(width: 12),
        ],
        ElevatedButton(
          onPressed: () {
            showTourokuDialog(
              context,
              'music',
              (data) {
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
    _idController.dispose();
    _songNameController.dispose();
    _artistController.dispose();
    _languageController.dispose();
    super.dispose();
  }
}
