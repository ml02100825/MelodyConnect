// artist_detail_admin.dart（アーティスト詳細画面）
import 'package:flutter/material.dart';
import 'bottom_admin.dart';
import 'artist_admin.dart';
import 'services/admin_api_service.dart';

class ArtistDetailAdmin extends StatefulWidget {
  final Artist artist;
  final bool isNew;
  final Function(Artist, String)? onStatusChanged;

  const ArtistDetailAdmin({
    Key? key,
    required this.artist,
    this.isNew = false,
    this.onStatusChanged,
  }) : super(key: key);

  @override
  State<ArtistDetailAdmin> createState() => _ArtistDetailAdminState();
}

class _ArtistDetailAdminState extends State<ArtistDetailAdmin> {
  String selectedMenu = 'コンテンツ管理';
  String selectedTab = 'アーティスト';
  
  // 編集モード管理
  bool _isEditing = false;
  
  // 編集用コントローラー
  late TextEditingController nameController;
  late TextEditingController genreController;
  late TextEditingController artistApiIdController;
  late TextEditingController imageUrlController;

  // 元の値（キャンセル用）
  late String _originalName;
  late String _originalGenre;
  late String _originalArtistApiId;
  late String _originalImageUrl;
  late String _originalStatus;

  // 選択用状態
  late String selectedStatus;
  bool _isUpdatingStatus = false;
  bool _isDeleting = false;
  bool _shouldRefresh = false;

  // ジャンルオプション（APIから取得）
  List<String> genreOptions = [];
  

  @override
  void initState() {
    super.initState();
    
    // コントローラー初期化
    nameController = TextEditingController(text: widget.artist.name);
    genreController = TextEditingController(text: widget.artist.genre);
    artistApiIdController = TextEditingController(text: widget.artist.artistApiId ?? '');
    imageUrlController = TextEditingController(text: widget.artist.imageUrl ?? '');

    // 元の値を保存（キャンセル用）
    _originalName = widget.artist.name;
    _originalGenre = widget.artist.genre;
    _originalArtistApiId = widget.artist.artistApiId ?? '';
    _originalImageUrl = widget.artist.imageUrl ?? '';
    _originalStatus = widget.artist.status;

    // 選択状態初期化
    selectedStatus = widget.artist.status;

    // ジャンルオプションを取得
    _loadGenres();

    // 新規作成の場合は編集モードで開始
    if (widget.isNew) {
      _isEditing = true;
    }
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
          // 現在の値がリストにない場合は追加
          if (genreController.text.isNotEmpty && !genres.contains(genreController.text)) {
            genreOptions.insert(0, genreController.text);
          }
        });
      }
    } catch (e) {
      // エラー時は空リストのまま
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: BottomAdminLayout(
        selectedMenu: selectedMenu,
        selectedTab: selectedTab,
        showTabs: false,
        mainContent: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ヘッダー
              _buildHeader(),
              
              const SizedBox(height: 24),
              
              // アーティスト詳細情報セクション
              _buildArtistDetailSection(),
              
              const SizedBox(height: 24),
              
              // 操作ボタン
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'アーティスト詳細',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                // アーティストアイコンセクション
                Container(
                  child: Row(
                    children: [
                      // アーティストアイコン
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.pink[50],
                          borderRadius: BorderRadius.circular(40),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: imageUrlController.text.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(40),
                                child: Image.network(
                                  imageUrlController.text,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.person,
                                      size: 40,
                                      color: Colors.pink[700],
                                    );
                                  },
                                ),
                              )
                            : Icon(
                                Icons.person,
                                size: 40,
                                color: Colors.pink[700],
                              ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${widget.artist.name}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'アーティスト',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[700],
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
          const SizedBox(width: 16),
          // 編集ボタン
          Column(
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      _isEditing ? Icons.save : Icons.edit,
                      size: 24,
                    ),
                    onPressed: _isEditing ? _saveChanges : _toggleEditMode,
                    tooltip: _isEditing ? '保存' : '編集',
                    color: Colors.blue,
                  ),
                  if (_isEditing)
                    IconButton(
                      icon: const Icon(Icons.cancel, size: 24),
                      onPressed: _cancelEdit,
                      tooltip: 'キャンセル',
                      color: Colors.grey[600],
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildArtistDetailSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ID
        _buildDetailRow('ID', widget.artist.id),
        const SizedBox(height: 24),
        
        // ジャンル名
        _buildDetailRow('ジャンル名', genreController.text),
        const SizedBox(height: 24),
        
        // アーティストAPI ID
        _buildDetailRow('アーティストAPI ID', artistApiIdController.text),
        const SizedBox(height: 24),

        // 追加日
        _buildDetailRow(
          '追加日',
          '${widget.artist.addedDate.year}/${widget.artist.addedDate.month.toString().padLeft(2, '0')}/${widget.artist.addedDate.day.toString().padLeft(2, '0')}',
        ),
        const SizedBox(height: 24),
        
        // 状態
        _buildDetailRow('状態', selectedStatus),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _isEditing ? _buildEditableField(label, value) : _buildDisplayField(value),
        ),
      ],
    );
  }

  Widget _buildDisplayField(String value) {
    return Text(
      value,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildEditableField(String label, String currentValue) {
    switch (label) {
      case 'ID':
        return Text(
          currentValue,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        );
      case '状態':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(4),
            color: Colors.white,
          ),
          child: DropdownButton<String>(
            value: selectedStatus,
            underline: const SizedBox(),
            items: ['有効', '無効'].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(value),
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedStatus = value!;
              });
            },
            isExpanded: true,
          ),
        );
      case 'ジャンル名':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(4),
            color: Colors.white,
          ),
          child: DropdownButton<String>(
            value: genreController.text,
            underline: const SizedBox(),
            items: genreOptions.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(value),
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                genreController.text = value!;
              });
            },
            isExpanded: true,
          ),
        );
      default:
        return TextField(
          controller: TextEditingController(text: currentValue),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            fillColor: Colors.white,
            filled: true,
          ),
        );
    }
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 一覧へ戻るボタン
        OutlinedButton(
          onPressed: () {
            Navigator.pop(context, _shouldRefresh ? true : null);
          },
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.grey,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            side: BorderSide.none,
          ),
          child: const Text('一覧へ戻る', style: TextStyle(color: Colors.white)),
        ),
        
        const Spacer(),
        
        // 状態変更ボタン
        if (!_isEditing && selectedStatus == '有効')
          ElevatedButton(
            onPressed: _isUpdatingStatus ? null : _toggleStatus,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              elevation: 0,
            ),
            child: const Text('アーティスト無効化', style: TextStyle(color: Colors.white)),
          ),
        
        if (!_isEditing && selectedStatus == '無効')
          ElevatedButton(
            onPressed: _isUpdatingStatus ? null : _toggleStatus,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              elevation: 0,
            ),
            child: const Text('アーティスト有効化', style: TextStyle(color: Colors.white)),
          ),
        
        const SizedBox(width: 16),
        
        // 削除ボタン
        ElevatedButton(
          onPressed: _isDeleting ? null : _showDeleteDialog,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            elevation: 0,
          ),
          child: Text(_isDeleted ? 'アーティスト削除解除' : 'アーティスト削除', style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  void _toggleEditMode() {
    if (_isEditing) {
      // 編集モードから保存モードへ：保存処理
      _saveChanges();
    } else {
      // 閲覧モードから編集モードへ
      setState(() {
        _isEditing = true;
      });
    }
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;

      // 元の値に戻す
      nameController.text = _originalName;
      genreController.text = _originalGenre;
      artistApiIdController.text = _originalArtistApiId;
      imageUrlController.text = _originalImageUrl;
      selectedStatus = _originalStatus;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('編集をキャンセルしました')),
    );
  }

  Future<void> _toggleStatus() async {
    if (_isUpdatingStatus) return;
    final nextStatus = selectedStatus == '有効' ? '無効' : '有効';
    setState(() {
      _isUpdatingStatus = true;
    });
    try {
      if (nextStatus == '有効') {
        await AdminApiService.enableArtists([widget.artist.numericId]);
      } else {
        await AdminApiService.disableArtists([widget.artist.numericId]);
      }
      if (!mounted) return;
      setState(() {
        selectedStatus = nextStatus;
        _shouldRefresh = true;
      });
      if (widget.onStatusChanged != null) {
        final updatedArtist = Artist(
          id: widget.artist.id,
          name: nameController.text,
          genre: genreController.text,
          status: selectedStatus,
          isActive: selectedStatus == '有効',
          isDeleted: widget.artist.isDeleted,
          addedDate: widget.artist.addedDate,
          updatedDate: DateTime.now(),
          artistApiId: artistApiIdController.text.isEmpty ? null : artistApiIdController.text,
          imageUrl: imageUrlController.text.isEmpty ? null : imageUrlController.text,
          numericId: widget.artist.numericId,
        );
        widget.onStatusChanged!(updatedArtist, 'status_changed');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('状態を$selectedStatusに変更しました')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('状態の変更に失敗しました: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingStatus = false;
        });
      }
    }
  }

  void _saveChanges() {
    final updatedArtist = Artist(
      id: widget.artist.id,
      name: nameController.text,
      genre: genreController.text,
      status: selectedStatus,
      isActive: selectedStatus == '有効',
      isDeleted: widget.artist.isDeleted,
      addedDate: widget.artist.addedDate,
      updatedDate: DateTime.now(),
      artistApiId: artistApiIdController.text.isEmpty ? null : artistApiIdController.text,
      imageUrl: imageUrlController.text.isEmpty ? null : imageUrlController.text,
      numericId: widget.artist.numericId,
    );

    // 元の値を更新
    _originalName = nameController.text;
    _originalGenre = genreController.text;
    _originalArtistApiId = artistApiIdController.text;
    _originalImageUrl = imageUrlController.text;
    _originalStatus = selectedStatus;

    setState(() {
      _isEditing = false;
    });

    Navigator.pop(context, {
      'action': 'save',
      'artist': updatedArtist,
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('変更を保存しました')),
    );
  }

  bool get _isDeleted => widget.artist.isDeleted;

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('削除確認'),
        content: Text(_isDeleted ? '削除を解除しますか？' : '削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('いいえ'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteArtist();
            },
            child: const Text('はい'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteArtist() async {
    if (_isDeleting) return;
    setState(() {
      _isDeleting = true;
    });
    try {
      if (_isDeleted) {
        await AdminApiService.restoreArtist(widget.artist.numericId);
      } else {
        await AdminApiService.deleteArtist(widget.artist.numericId);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isDeleted ? 'アーティストの削除を解除しました' : 'アーティストを削除しました')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('アーティストの削除に失敗しました: $e')),
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

  @override
  void dispose() {
    nameController.dispose();
    genreController.dispose();
    artistApiIdController.dispose();
    imageUrlController.dispose();
    super.dispose();
  }
}
