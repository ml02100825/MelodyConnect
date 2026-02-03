import 'package:flutter/material.dart';
import '../services/artist_api_service.dart';
import '../services/token_storage_service.dart';
import '../widgets/unified_selection_dialog.dart';

class LikeArtistEditScreen extends StatefulWidget {
  const LikeArtistEditScreen({Key? key}) : super(key: key);

  @override
  State<LikeArtistEditScreen> createState() => _LikeArtistEditScreenState();
}

class _LikeArtistEditScreenState extends State<LikeArtistEditScreen> {
  final _artistApiService = ArtistApiService();
  final _tokenStorage = TokenStorageService();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  List<Map<String, dynamic>> _allArtists = [];
  List<Map<String, dynamic>> _filteredArtists = [];
  String _searchQuery = '';
  String? _selectedGenre;
  bool _sortAscending = false; // デフォルト: 新しい順
  List<String> _genreNames = [];

  @override
  void initState() {
    super.initState();
    _loadLikeArtists();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLikeArtists() async {
    setState(() => _isLoading = true);
    try {
      final token = await _tokenStorage.getAccessToken();
      if (token == null) throw Exception('認証が必要です');

      final data = await _artistApiService.getLikeArtists(token);
      if (mounted) {
        setState(() {
          _allArtists = data;
          _genreNames = data
              .expand((a) => (a['genreNames'] as List<dynamic>).cast<String>())
              .toSet()
              .toList()
            ..sort();
          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('お気に入りアーティスト取得エラー: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _applyFilters() {
    var list = List<Map<String, dynamic>>.from(_allArtists);

    if (_selectedGenre != null) {
      list = list.where((a) => (a['genreNames'] as List<dynamic>).contains(_selectedGenre)).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((a) => (a['artistName'] as String).toLowerCase().contains(q))
          .toList();
    }

    list.sort((a, b) {
      final dateA = DateTime.parse(a['createdAt'] as String);
      final dateB = DateTime.parse(b['createdAt'] as String);
      return _sortAscending ? dateA.compareTo(dateB) : dateB.compareTo(dateA);
    });

    _filteredArtists = list;
  }

  Future<void> _deleteArtist(Map<String, dynamic> artist) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('削除の確認'),
        content: Text('「${artist['artistName']}」をお気に入りから削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('削除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final token = await _tokenStorage.getAccessToken();
      if (token == null) throw Exception('認証が必要です');

      final artistId = artist['artistId'] as int;
      await _artistApiService.deleteLikeArtist(artistId, token);

      if (mounted) {
        setState(() {
          _allArtists.removeWhere((a) => a['artistId'] == artistId);
          _applyFilters();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('削除しました'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('削除に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openAddDialog() async {
    final excludeIds =
        _allArtists.map((a) => a['artistApiId'] as String).toSet();

    await showDialog(
      context: context,
      builder: (context) =>
          UnifiedSelectionDialog(excludeArtistSpotifyIds: excludeIds),
    );

    await _loadLikeArtists();
  }

  String _formatDate(String isoString) {
    final dt = DateTime.parse(isoString);
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.year}年${dt.month}月${dt.day}日 $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('アーティスト編集'),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'sort_header',
                enabled: false,
                child: Text('ソート',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.grey)),
              ),
              PopupMenuItem<String>(
                value: 'sort_desc',
                child: Row(
                  children: [
                    if (!_sortAscending) const Icon(Icons.check),
                    const SizedBox(width: 8),
                    const Text('追加日時: 新しい順'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'sort_asc',
                child: Row(
                  children: [
                    if (_sortAscending) const Icon(Icons.check),
                    const SizedBox(width: 8),
                    const Text('追加日時: 古い順'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'genre_header',
                enabled: false,
                child: Text('ジャンル',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.grey)),
              ),
              PopupMenuItem<String>(
                value: 'genre_all',
                child: Row(
                  children: [
                    if (_selectedGenre == null) const Icon(Icons.check),
                    const SizedBox(width: 8),
                    const Text('全ジャンル'),
                  ],
                ),
              ),
              ..._genreNames.map((name) => PopupMenuItem<String>(
                    value: 'genre_$name',
                    child: Row(
                      children: [
                        if (_selectedGenre == name) const Icon(Icons.check),
                        const SizedBox(width: 8),
                        Text(name),
                      ],
                    ),
                  )),
            ],
            onSelected: (value) {
              setState(() {
                if (value == 'sort_asc') {
                  _sortAscending = true;
                } else if (value == 'sort_desc') {
                  _sortAscending = false;
                } else if (value == 'genre_all') {
                  _selectedGenre = null;
                } else if (value.startsWith('genre_')) {
                  _selectedGenre = value.substring(6);
                }
                _applyFilters();
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _openAddDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'アーティスト名で検索',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                            _applyFilters();
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _applyFilters();
                });
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredArtists.isEmpty
                    ? const Center(
                        child: Text('アーティストがいません',
                            style: TextStyle(color: Colors.grey)),
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black, width: 1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: ListView.builder(
                              itemCount: _filteredArtists.length,
                              itemBuilder: (context, index) =>
                                  _buildArtistTile(_filteredArtists[index]),
                            ),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtistTile(Map<String, dynamic> artist) {
    final imageUrl = artist['imageUrl'] as String?;
    final name = artist['artistName'] as String;
    final genres = (artist['genreNames'] as List<dynamic>).cast<String>();
    final createdAt = artist['createdAt'] as String;

    return Column(
      children: [
        ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Container(
              width: 48,
              height: 48,
              color: Colors.grey[200],
              child: imageUrl != null
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.person, color: Colors.grey),
                    )
                  : const Icon(Icons.person, color: Colors.grey),
            ),
          ),
          title: Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (genres.isNotEmpty)
                Wrap(
                  spacing: 4,
                  children: genres
                      .map((g) => Chip(
                            label: Text(g, style: const TextStyle(fontSize: 11)),
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ))
                      .toList(),
                ),
              Text(_formatDate(createdAt),
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _deleteArtist(artist),
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }
}
