import 'package:flutter/material.dart';
import 'bottom_admin.dart';
import 'services/admin_api_service.dart';

class MusicDetailPage extends StatefulWidget {
  final Map<String, dynamic> music;

  const MusicDetailPage({Key? key, required this.music}) : super(key: key);

  @override
  State<MusicDetailPage> createState() => _MusicDetailPageState();
}

class _MusicDetailPageState extends State<MusicDetailPage> {
  late String status;
  bool _isUpdating = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    status = widget.music['status'] ?? '有効';
  }

  void toggleStatus() {
    _updateStatus();
  }

  int _resolveSongId() {
    return int.tryParse(widget.music['id']?.toString() ?? '') ?? 0;
  }

  Future<void> _updateStatus() async {
    if (_isUpdating) return;
    final songId = _resolveSongId();
    if (songId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('楽曲IDが不正です。')),
      );
      return;
    }
    final nextStatus = status == '有効' ? '無効' : '有効';
    setState(() {
      _isUpdating = true;
    });
    try {
      if (nextStatus == '有効') {
        await AdminApiService.enableSongs([songId]);
      } else {
        await AdminApiService.disableSongs([songId]);
      }
      if (!mounted) return;
      setState(() {
        status = nextStatus;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('楽曲を$nextStatusに更新しました')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('楽曲の状態更新に失敗しました: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Future<void> _deleteSong() async {
    if (_isDeleting) return;
    final songId = _resolveSongId();
    if (songId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('楽曲IDが不正です。')),
      );
      return;
    }
    setState(() {
      _isDeleting = true;
    });
    try {
      await AdminApiService.deleteSong(songId);
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('楽曲を削除しました')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('削除に失敗しました: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return DeleteConfirmationDialog(
          music: widget.music,
          onDelete: () async {
            Navigator.pop(context);
            await _deleteSong();
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

            // 詳細情報
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow('アーティストID', widget.music['artistId'] ?? ''),
                const SizedBox(height: 16),
                _detailRow('geniusソングID', widget.music['geniusSongId'] ?? ''),
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
                  onPressed: _isUpdating ? null : toggleStatus,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: status == '有効' ? Colors.orange : Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    elevation: 0,
                  ),
                  child: Text(status == '有効' ? '楽曲無効化' : '楽曲有効化'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isDeleting ? null : _showDeleteDialog,
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
  final Future<void> Function() onDelete;

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

  bool get canDelete => deleteId && deleteSongName && deleteArtist;

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
            _buildCheckboxRow('アーティスト', widget.music['artistId'] ?? '', deleteArtist, (value) {
              setState(() {
                deleteArtist = value ?? false;
              });
            }),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: canDelete ? () async => widget.onDelete() : null,
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
