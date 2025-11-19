import 'package:flutter/material.dart';

/// ジャンル情報
class GenreInfo {
  final String id;
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

/// 利用可能なジャンルリスト
const List<GenreInfo> availableGenres = [
  GenreInfo(id: 'pop', name: 'pop', displayName: 'Pop', icon: Icons.music_note),
  GenreInfo(id: 'rock', name: 'rock', displayName: 'Rock', icon: Icons.electric_bolt),
  GenreInfo(id: 'hip-hop', name: 'hip-hop', displayName: 'Hip Hop', icon: Icons.mic),
  GenreInfo(id: 'r-n-b', name: 'r-n-b', displayName: 'R&B', icon: Icons.nightlife),
  GenreInfo(id: 'k-pop', name: 'k-pop', displayName: 'K-Pop', icon: Icons.star),
  GenreInfo(id: 'j-pop', name: 'j-pop', displayName: 'J-Pop', icon: Icons.filter_vintage),
  GenreInfo(id: 'latin', name: 'latin', displayName: 'Latin', icon: Icons.sunny),
  GenreInfo(id: 'electronic', name: 'electronic', displayName: 'Electronic', icon: Icons.speaker),
  GenreInfo(id: 'country', name: 'country', displayName: 'Country', icon: Icons.landscape),
  GenreInfo(id: 'jazz', name: 'jazz', displayName: 'Jazz', icon: Icons.piano),
];

/// ジャンル選択ダイアログ
class GenreSelectionDialog extends StatefulWidget {
  const GenreSelectionDialog({Key? key}) : super(key: key);

  @override
  State<GenreSelectionDialog> createState() => _GenreSelectionDialogState();
}

class _GenreSelectionDialogState extends State<GenreSelectionDialog> {
  final Set<String> _selectedGenres = {};

  void _toggleGenre(String genreId) {
    setState(() {
      if (_selectedGenres.contains(genreId)) {
        _selectedGenres.remove(genreId);
      } else {
        _selectedGenres.add(genreId);
      }
    });
  }

  void _submitSelection() {
    if (_selectedGenres.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ジャンルを1つ以上選択してください'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // 選択されたジャンル名のリストを返す
    final selectedGenreNames = availableGenres
        .where((g) => _selectedGenres.contains(g.id))
        .map((g) => g.name)
        .toList();

    Navigator.of(context).pop(selectedGenreNames);
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
              '好きなジャンルを選択',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '選択したジャンルからアーティストを検索できます',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),

            // ジャンルグリッド
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.5,
                ),
                itemCount: availableGenres.length,
                itemBuilder: (context, index) {
                  final genre = availableGenres[index];
                  final isSelected = _selectedGenres.contains(genre.id);

                  return InkWell(
                    onTap: () => _toggleGenre(genre.id),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.blue.withOpacity(0.2)
                            : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? Colors.blue : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            genre.icon,
                            color: isSelected ? Colors.blue : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            genre.displayName,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected ? Colors.blue : Colors.black87,
                            ),
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.check_circle,
                              color: Colors.blue,
                              size: 18,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // 選択済みジャンル表示
            if (_selectedGenres.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                '選択中: ${_selectedGenres.length}ジャンル',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],

            // ボタン
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: const Text('スキップ'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _submitSelection,
                  child: Text('次へ (${_selectedGenres.length})'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
