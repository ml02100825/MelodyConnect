import 'dart:async';
import 'package:flutter/material.dart';
import '../services/artist_api_service.dart';
import '../services/token_storage_service.dart';

/// ジャンル情報定義
class GenreInfo {
  final int id;
  final String name;
  final String displayName;
  final IconData icon;

  const GenreInfo({
    required this.id,
    required this.name,
    required this.displayName,
    required this.icon,
  });
}

class UnifiedSelectionDialog extends StatefulWidget {
  final Set<String>? excludeArtistSpotifyIds;
  const UnifiedSelectionDialog({Key? key, this.excludeArtistSpotifyIds}) : super(key: key);

  @override
  State<UnifiedSelectionDialog> createState() => _UnifiedSelectionDialogState();
}

class _UnifiedSelectionDialogState extends State<UnifiedSelectionDialog> {
  final _artistApiService = ArtistApiService();
  final _tokenStorage = TokenStorageService();

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  String _headerTitle = '好きなジャンルを選択';
  bool _showGenreGrid = true;

  List<GenreInfo> _availableGenres = [];
  bool _isLoadingGenres = true;

  List<SpotifyArtist> _searchResults = [];
  final List<SpotifyArtist> _selectedPendingArtists = [];
  final Set<String> _registeredArtistIds = {}; 

  static const int _genrePageSize = 20;
  bool _isGenreSearchResults = false;
  int _currentGenrePage = 0;

  bool _isSearching = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_onFocusChange);
    _fetchGenres();
  }

  void _onFocusChange() {
    if (_searchFocusNode.hasFocus) {
      setState(() {
        _headerTitle = 'アーティストを検索';
        _showGenreGrid = false;
      });
    } else {
      if (_searchController.text.isEmpty) {
        setState(() {
          _headerTitle = '好きなジャンルを選択';
          _showGenreGrid = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.removeListener(_onFocusChange);
    _searchFocusNode.dispose();
    super.dispose();
  }

  /// APIからジャンル一覧を取得
  Future<void> _fetchGenres() async {
    try {
      final accessToken = await _tokenStorage.getAccessToken();
      if (accessToken == null) return;

      final genresData = await _artistApiService.getGenres(accessToken);

      if (mounted) {
        setState(() {
          _availableGenres = genresData.map((data) {
            // ★修正: バックエンドのフィールド名変更に合わせて 'genreId' を取得
            // 以前の曖昧な処理 (data['genreId'] ?? data['id']) を廃止し明確化
            final id = data['genreId'] as int? ?? 0;
            
            final name = data['name'] as String? ?? 'Unknown';
            return GenreInfo(
              id: id,
              name: name,
              displayName: _capitalize(name),
              icon: _getIconForGenre(name),
            );
          }).toList();
          _isLoadingGenres = false;
        });
      }
    } catch (e) {
      debugPrint('ジャンル取得エラー: $e');
      if (mounted) {
        setState(() => _isLoadingGenres = false);
      }
    }
  }

  String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  IconData _getIconForGenre(String name) {
    final n = name.toLowerCase();
    if (n.contains('rock') || n.contains('metal') || n.contains('punk') || n.contains('grunge')) return Icons.electric_bolt;
    if (n.contains('pop') || n.contains('k-pop') || n.contains('j-pop')) return Icons.music_note;
    if (n.contains('hip') || n.contains('rap') || n.contains('r&b') || n.contains('trap')) return Icons.mic;
    if (n.contains('jazz') || n.contains('blues') || n.contains('soul') || n.contains('bossa')) return Icons.piano;
    if (n.contains('classic') || n.contains('piano') || n.contains('orchestra')) return Icons.music_note_outlined;
    if (n.contains('dance') || n.contains('electro') || n.contains('edm') || n.contains('house')) return Icons.speaker;
    if (n.contains('acoustic') || n.contains('folk') || n.contains('country')) return Icons.landscape;
    if (n.contains('anime') || n.contains('game')) return Icons.smart_toy;
    if (n.contains('reggae') || n.contains('latin') || n.contains('salsa')) return Icons.sunny;
    if (n.contains('indie') || n.contains('alternative')) return Icons.headphones;
    return Icons.album;
  }

  /// Spotify検索用のキーワード変換ロジック
  String _convertToSpotifySearchTerm(String dbGenreName) {
    String term = dbGenreName.toLowerCase();

    // 特殊なケース
    if (term == 'r-n-b' || term == 'r_n_b') return 'r&b';
    
    // ハイフン処理
    if (term.contains('-')) {
       if (!term.endsWith('pop') && !term.endsWith('rock')) { 
         term = term.replaceAll('-', ' ');
       }
    }
    return term;
  }

  /// ジャンルタップ時の検索処理
  void _onGenreTap(GenreInfo genre) {
    final term = _convertToSpotifySearchTerm(genre.name);
    _searchController.text = genre.displayName;
    _searchFocusNode.requestFocus();
    
    _searchArtistsByGenre(term);
  }

  /// アーティスト検索実行
  Future<void> _searchArtistsByGenre(String genreName) async {
    final query = genreName.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _showGenreGrid = false;
      _headerTitle = 'アーティストを検索';
    });

    try {
      final accessToken = await _tokenStorage.getAccessToken();
      if (accessToken == null) throw Exception('認証が必要です');

      final results = await _artistApiService.searchArtistsByGenre(query, accessToken);
      
      if (mounted) {
        setState(() {
          _searchResults = widget.excludeArtistSpotifyIds != null
              ? results.where((a) => !widget.excludeArtistSpotifyIds!.contains(a.spotifyId)).toList()
              : results;
          _isGenreSearchResults = true;
          _currentGenrePage = 0;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('検索エラー: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  Future<void> _searchArtistsByName() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _showGenreGrid = false;
      _headerTitle = 'アーティストを検索';
    });

    try {
      final accessToken = await _tokenStorage.getAccessToken();
      if (accessToken == null) throw Exception('認証が必要です');

      final results = await _artistApiService.searchArtists(query, accessToken);
      
      if (mounted) {
        setState(() {
          _searchResults = widget.excludeArtistSpotifyIds != null
              ? results.where((a) => !widget.excludeArtistSpotifyIds!.contains(a.spotifyId)).toList()
              : results;
          _isGenreSearchResults = false;
          _currentGenrePage = 0;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('検索エラー: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  void _toggleArtistSelection(SpotifyArtist artist) {
    setState(() {
      if (_selectedPendingArtists.any((a) => a.spotifyId == artist.spotifyId)) {
        _selectedPendingArtists.removeWhere((a) => a.spotifyId == artist.spotifyId);
      } else {
        _selectedPendingArtists.add(artist);
      }
    });
  }

  Future<void> _registerArtists() async {
    if (_selectedPendingArtists.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('アーティストを選択してください'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final accessToken = await _tokenStorage.getAccessToken();
      if (accessToken == null) throw Exception('認証が必要です');
      
      await _artistApiService.registerLikeArtists(_selectedPendingArtists, accessToken);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedPendingArtists.length}件のアーティストを登録しました！'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        setState(() {
          _registeredArtistIds.addAll(
            _selectedPendingArtists.map((a) => a.spotifyId)
          );
          _selectedPendingArtists.clear();
        });

        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('登録失敗: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _clearSearch() {
    _searchController.clear();
    _searchFocusNode.unfocus();
    setState(() {
      _headerTitle = '好きなジャンルを選択';
      _showGenreGrid = true;
      _searchResults = [];
      _isSearching = false;
      _isGenreSearchResults = false;
      _currentGenrePage = 0;
    });
  }


  int _totalGenrePages() {
    if (_searchResults.isEmpty) return 0;
    return (_searchResults.length / _genrePageSize).ceil();
  }

  void _goToGenrePage(int page) {
    final total = _totalGenrePages();
    if (total == 0) return;
    final next = page.clamp(0, total - 1);
    setState(() {
      _currentGenrePage = next;
    });
  }

  List<SpotifyArtist> _currentPageResults() {
    if (!_isGenreSearchResults) return _searchResults;
    final start = _currentGenrePage * _genrePageSize;
    if (start >= _searchResults.length) return [];
    var end = start + _genrePageSize;
    if (end > _searchResults.length) end = _searchResults.length;
    return _searchResults.sublist(start, end);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        height: 700,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (!_showGenreGrid)
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    tooltip: '戻る',
                    onPressed: _clearSearch,
                  ),
                Expanded(
                  child: Text(
                    _headerTitle,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _searchArtistsByName(),
              decoration: InputDecoration(
                hintText: 'アーティスト名を入力',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                suffixIcon: _isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : _searchController.text.isNotEmpty || !_showGenreGrid
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: _clearSearch,
                          )
                        : const Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 16),

            if (_selectedPendingArtists.isNotEmpty) ...[
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedPendingArtists.length,
                  itemBuilder: (context, index) {
                    final artist = _selectedPendingArtists[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Chip(
                        label: Text(artist.name),
                        deleteIcon: const Icon(Icons.close, size: 18),
                        onDeleted: () => _toggleArtistSelection(artist),
                        backgroundColor: Colors.blue.shade50,
                        labelStyle: TextStyle(color: Colors.blue.shade900),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],

            Expanded(
              child: _showGenreGrid
                  ? _buildGenreGrid()
                  : _buildSearchResultsList(),
            ),

            if (!_showGenreGrid && _isGenreSearchResults && _searchResults.length > _genrePageSize) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _currentGenrePage > 0
                        ? () => _goToGenrePage(_currentGenrePage - 1)
                        : null,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text('${_currentGenrePage + 1} / ${_totalGenrePages()}'),
                  IconButton(
                    onPressed: _currentGenrePage < _totalGenrePages() - 1
                        ? () => _goToGenrePage(_currentGenrePage + 1)
                        : null,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('終了'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _isSubmitting || _selectedPendingArtists.isEmpty 
                      ? null 
                      : _registerArtists,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20, 
                          height: 20, 
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                        )
                      : Text('登録 (${_selectedPendingArtists.length})'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenreGrid() {
    if (_isLoadingGenres) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_availableGenres.isEmpty) {
      return const Center(
        child: Text(
          'ジャンル情報を取得できませんでした',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ジャンルから探す',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.8,
            ),
            itemCount: _availableGenres.length,
            itemBuilder: (context, index) {
              final genre = _availableGenres[index];
              return InkWell(
                onTap: () => _onGenreTap(genre),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.transparent, width: 2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(genre.icon, color: Colors.grey),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          genre.displayName,
                          style: const TextStyle(fontWeight: FontWeight.normal),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResultsList() {
    final displayedResults = _currentPageResults();
    if (_searchResults.isEmpty && !_isSearching) {
      return const Center(
        child: Text(
          'アーティストが見つかりませんでした\n別のキーワードを試してください',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: displayedResults.length,
      itemBuilder: (context, index) {
        final artist = displayedResults[index];
        final isSelected = _selectedPendingArtists.any((a) => a.spotifyId == artist.spotifyId);
        final isRegistered = _registeredArtistIds.contains(artist.spotifyId);

        return ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Container(
              width: 48,
              height: 48,
              color: Colors.grey[200],
              child: artist.imageUrl != null
                  ? Image.network(
                      artist.imageUrl!,
                      fit: BoxFit.cover,
                      color: isRegistered ? Colors.white.withOpacity(0.5) : null,
                      colorBlendMode: isRegistered ? BlendMode.modulate : null,
                      errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.grey),
                    )
                  : const Icon(Icons.person, color: Colors.grey),
            ),
          ),
          
          title: Text(
            artist.name,
            style: TextStyle(
              color: isRegistered ? Colors.grey : Colors.black,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          
          subtitle: Text(
            artist.genres.isNotEmpty 
                ? artist.genres.take(2).join(', ') 
                : ' ', 
            style: const TextStyle(fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          
          trailing: isRegistered
              ? const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("登録済", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    SizedBox(width: 4),
                    Icon(Icons.check, color: Colors.grey),
                  ],
                )
              : isSelected
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : const Icon(Icons.add_circle_outline),
          
          onTap: isRegistered 
              ? null 
              : () => _toggleArtistSelection(artist),
        );
      },
    );
  }
}
