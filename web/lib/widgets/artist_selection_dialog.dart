import 'dart:async';
import 'package:flutter/material.dart';
import '../services/artist_api_service.dart';
import '../services/token_storage_service.dart';

/// お気に入りアーティスト選択ダイアログ
class ArtistSelectionDialog extends StatefulWidget {
  final List<String>? selectedGenres;

  const ArtistSelectionDialog({Key? key, this.selectedGenres}) : super(key: key);

  @override
  State<ArtistSelectionDialog> createState() => _ArtistSelectionDialogState();
}

class _ArtistSelectionDialogState extends State<ArtistSelectionDialog> {
  final _artistApiService = ArtistApiService();
  final _tokenStorage = TokenStorageService();
  final _searchController = TextEditingController();

  List<SpotifyArtist> _searchResults = [];
  List<SpotifyArtist> _selectedArtists = [];
  bool _isSearching = false;
  bool _isSubmitting = false;
  Timer? _debounceTimer;

  String? _currentGenre;
  List<String> _genres = [];

  @override
  void initState() {
    super.initState();
    _genres = widget.selectedGenres ?? [];
    if (_genres.isNotEmpty) {
      _currentGenre = _genres.first;
      // 初期ジャンルでアーティストを検索
      _searchArtistsByGenre(_currentGenre!);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// アーティストを検索（デバウンス付き）
  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (query.isNotEmpty) {
        _searchArtists(query);
      } else if (_currentGenre != null) {
        _searchArtistsByGenre(_currentGenre!);
      } else {
        setState(() {
          _searchResults = [];
        });
      }
    });
  }

  /// アーティストを検索
  Future<void> _searchArtists(String query) async {
    setState(() {
      _isSearching = true;
    });

    try {
      final accessToken = await _tokenStorage.getAccessToken();
      if (accessToken == null) {
        throw Exception('認証が必要です');
      }

      // ジャンルが選択されている場合はジャンル付きで検索
      String searchQuery = query;
      if (_currentGenre != null && _currentGenre!.isNotEmpty) {
        searchQuery = '$query genre:$_currentGenre';
      }

      final results = await _artistApiService.searchArtists(searchQuery, accessToken);
      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('検索に失敗しました: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  /// ジャンルでアーティストを検索
  Future<void> _searchArtistsByGenre(String genre) async {
    setState(() {
      _isSearching = true;
    });

    try {
      final accessToken = await _tokenStorage.getAccessToken();
      if (accessToken == null) {
        throw Exception('認証が必要です');
      }

      final results = await _artistApiService.searchArtists('genre:$genre', accessToken);
      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('検索に失敗しました: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  /// アーティストを選択
  void _toggleArtist(SpotifyArtist artist) {
    setState(() {
      if (_selectedArtists.any((a) => a.spotifyId == artist.spotifyId)) {
        _selectedArtists.removeWhere((a) => a.spotifyId == artist.spotifyId);
      } else {
        _selectedArtists.add(artist);
      }
    });
  }

  /// ジャンルを切り替え
  void _selectGenre(String genre) {
    setState(() {
      _currentGenre = genre;
      _searchController.clear();
    });
    _searchArtistsByGenre(genre);
  }

  /// 選択を確定
  Future<void> _submitSelection() async {
    if (_selectedArtists.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('アーティストを1つ以上選択してください'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final accessToken = await _tokenStorage.getAccessToken();
      if (accessToken == null) {
        throw Exception('認証が必要です');
      }

      await _artistApiService.registerLikeArtists(_selectedArtists, accessToken);

      if (mounted) {
        Navigator.of(context).pop(true); // 成功を返す
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('登録に失敗しました: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        height: 700,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // タイトル
            const Text(
              '好きなアーティストを選択',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '学習で使用する曲の生成に使われます',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),

            // ジャンルタブ（選択されている場合）
            if (_genres.isNotEmpty) ...[
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _genres.length,
                  itemBuilder: (context, index) {
                    final genre = _genres[index];
                    final isSelected = genre == _currentGenre;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(_getGenreDisplayName(genre)),
                        selected: isSelected,
                        onSelected: (_) => _selectGenre(genre),
                        selectedColor: Colors.blue.withOpacity(0.3),
                        checkmarkColor: Colors.blue,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 検索ボックス
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: _currentGenre != null
                    ? '${_getGenreDisplayName(_currentGenre!)}のアーティストを検索'
                    : 'アーティスト名を入力',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: _isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
              ),
              onChanged: _onSearchChanged,
            ),
            const SizedBox(height: 16),

            // 選択済みアーティスト
            if (_selectedArtists.isNotEmpty) ...[
              Row(
                children: [
                  const Text(
                    '選択中:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_selectedArtists.length}アーティスト',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedArtists.length,
                  itemBuilder: (context, index) {
                    final artist = _selectedArtists[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Chip(
                        label: Text(artist.name),
                        deleteIcon: const Icon(Icons.close, size: 18),
                        onDeleted: () => _toggleArtist(artist),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 検索結果
            Expanded(
              child: _searchResults.isEmpty && !_isSearching
                  ? Center(
                      child: Text(
                        _genres.isEmpty
                            ? 'アーティストを検索してください'
                            : '上のジャンルタブを選択するか、検索してください',
                        style: const TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : _isSearching && _searchResults.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final artist = _searchResults[index];
                            final isSelected = _selectedArtists
                                .any((a) => a.spotifyId == artist.spotifyId);

                            return ListTile(
                              leading: artist.imageUrl != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: Image.network(
                                        artist.imageUrl!,
                                        width: 48,
                                        height: 48,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(Icons.person, size: 48),
                                      ),
                                    )
                                  : const Icon(Icons.person, size: 48),
                              title: Text(artist.name),
                              subtitle: artist.genres.isNotEmpty
                                  ? Text(
                                      artist.genres.take(2).join(', '),
                                      style: const TextStyle(fontSize: 12),
                                    )
                                  : null,
                              trailing: isSelected
                                  ? const Icon(Icons.check_circle,
                                      color: Colors.green)
                                  : const Icon(Icons.add_circle_outline),
                              onTap: () => _toggleArtist(artist),
                            );
                          },
                        ),
            ),

            // ボタン
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isSubmitting
                      ? null
                      : () => Navigator.of(context).pop(false),
                  child: const Text('スキップ'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitSelection,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text('登録 (${_selectedArtists.length})'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// ジャンル名を表示名に変換
  String _getGenreDisplayName(String genre) {
    switch (genre) {
      case 'pop':
        return 'Pop';
      case 'rock':
        return 'Rock';
      case 'hip-hop':
        return 'Hip Hop';
      case 'r-n-b':
        return 'R&B';
      case 'k-pop':
        return 'K-Pop';
      case 'j-pop':
        return 'J-Pop';
      case 'latin':
        return 'Latin';
      case 'electronic':
        return 'Electronic';
      case 'country':
        return 'Country';
      case 'jazz':
        return 'Jazz';
      default:
        return genre;
    }
  }
}
