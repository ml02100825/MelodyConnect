import 'package:flutter/material.dart';
import 'bottom_admin.dart';

class MusicDetailPage extends StatefulWidget {
  final Map<String, dynamic> music;

  const MusicDetailPage({Key? key, required this.music}) : super(key: key);

  @override
  State<MusicDetailPage> createState() => _MusicDetailPageState();
}

class _MusicDetailPageState extends State<MusicDetailPage> {
  late String status;

  @override
  void initState() {
    super.initState();
    status = widget.music['status'] ?? '有効';
  }

  void toggleStatus() {
    setState(() {
      status = (status == '有効') ? '無効' : '有効';
    });
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return DeleteConfirmationDialog(
          music: widget.music,
          onDelete: () {
            // 削除処理
            Navigator.pop(context); // ダイアログを閉じる
            Navigator.pop(context); // 詳細画面を閉じる
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BottomAdminLayout(
        mainContent: _buildMainContent(),
        selectedMenu: 'コンテンツ管理',
        selectedTab: '楽曲',
        showTabs: false,
      ),
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '楽曲詳細',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),

            // アイコンと楽曲名
            Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.album,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 24),
                Text(
                  widget.music['songName'] ?? '',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // 詳細情報
            _detailRow('ID', widget.music['id']),
            const SizedBox(height: 24),

            // 2列レイアウト
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _detailRow('名称', widget.music['songName']),
                      const SizedBox(height: 16),
                      _detailRow('アーティスト名', widget.music['artist']),
                      const SizedBox(height: 16),
                      _detailRow('アーティストID', widget.music['artistId'] ?? '00001'),
                      const SizedBox(height: 16),
                      _detailRow('ジャンル', widget.music['genre'] ?? 'ジャンル01'),
                      const SizedBox(height: 16),
                      _detailRow('ジャンルID', widget.music['genreId'] ?? '00001'),
                      const SizedBox(height: 16),
                      _detailRow('geniusソングID', widget.music['geniusSongId'] ?? '00000000'),
                    ],
                  ),
                ),
                const SizedBox(width: 60),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _detailRow('楽曲', widget.music['songName']),
                      const SizedBox(height: 16),
                      _detailRow('アーティスト01', widget.music['artist']),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),
            _detailRow('追加日時', widget.music['addedDate'] ?? '2026/01/01'),
            const SizedBox(height: 16),
            _detailRow('状態', status),

            const SizedBox(height: 40),

            // ボタン
            Row(
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[400],
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    elevation: 0,
                  ),
                  child: const Text('一覧へ戻る'),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: toggleStatus,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    elevation: 0,
                  ),
                  child: const Text('楽曲無効化'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _showDeleteDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    elevation: 0,
                  ),
                  child: const Text('楽曲削除'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String title, dynamic value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 150,
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value?.toString() ?? '',
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }
}

class DeleteConfirmationDialog extends StatefulWidget {
  final Map<String, dynamic> music;
  final VoidCallback onDelete;

  const DeleteConfirmationDialog({
    Key? key,
    required this.music,
    required this.onDelete,
  }) : super(key: key);

  @override
  State<DeleteConfirmationDialog> createState() => _DeleteConfirmationDialogState();
}

class _DeleteConfirmationDialogState extends State<DeleteConfirmationDialog> {
  bool deleteId = false;
  bool deleteSongName = false;
  bool deleteArtist = false;
  bool deleteGenre = false;

  bool get canDelete => deleteId && deleteSongName && deleteArtist && deleteGenre;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      backgroundColor: Colors.white,
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.warning_rounded,
              color: Colors.red,
              size: 64,
            ),
            const SizedBox(height: 24),
            _buildCheckboxRow('ID', widget.music['id'], deleteId, (value) {
              setState(() {
                deleteId = value ?? false;
              });
            }),
            const SizedBox(height: 16),
            _buildCheckboxRow('楽曲名', widget.music['songName'], deleteSongName, (value) {
              setState(() {
                deleteSongName = value ?? false;
              });
            }),
            const SizedBox(height: 16),
            _buildCheckboxRow('アーティスト', widget.music['artist'], deleteArtist, (value) {
              setState(() {
                deleteArtist = value ?? false;
              });
            }),
            const SizedBox(height: 16),
            _buildCheckboxRow('ジャンル', widget.music['genre'] ?? 'ジャンル01', deleteGenre, (value) {
              setState(() {
                deleteGenre = value ?? false;
              });
            }),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: canDelete ? widget.onDelete : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: canDelete ? Colors.red : Colors.grey[300],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                elevation: 0,
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('楽曲を削除する', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[600],
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('キャンセル', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckboxRow(String label, String value, bool checked, Function(bool?) onChanged) {
    return Row(
      children: [
        Checkbox(
          value: checked,
          onChanged: onChanged,
          activeColor: Colors.blue,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            children: [
              SizedBox(
                width: 100,
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              Text(
                value,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }
}