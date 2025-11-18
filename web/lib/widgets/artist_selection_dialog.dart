import 'dart:async';
import 'package:flutter/material.dart';
import '../services/artist_api_service.dart';
import '../services/token_storage_service.dart';

/// お気に入りアーティスト選択ダイアログ
class ArtistSelectionDialog extends StatefulWidget {
  const ArtistSelectionDialog({Key? key}) : super(key: key);

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

      final results = await _artistApiService.searchArtists(query, accessToken);
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
        width: 500,
        height: 600,
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

            // 検索ボックス
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'アーティスト名を入力',
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
              const Text(
                '選択中:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedArtists.map((artist) {
                  return Chip(
                    label: Text(artist.name),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () => _toggleArtist(artist),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // 検索結果
            Expanded(
              child: _searchResults.isEmpty
                  ? const Center(
                      child: Text(
                        'アーティストを検索してください',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
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
}
