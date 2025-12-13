// artist_detail_admin.dart（アーティスト詳細画面）
import 'package:flutter/material.dart' hide Artist;
import 'bottom_admin.dart';
import 'artist_admin.dart';

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
  late TextEditingController genreIdController;
  late TextEditingController artistApiIdController;
  late TextEditingController descriptionController;
  late TextEditingController imageUrlController;
  
  // 元の値（キャンセル用）
  late String _originalName;
  late String _originalGenre;
  late String _originalGenreId;
  late String _originalArtistApiId;
  late String _originalDescription;
  late String _originalImageUrl;
  late String _originalStatus;
  
  // 選択用状態
  late String selectedStatus;
  
  // ジャンルオプション
  final List<String> genreOptions = [
    'ジャンル01',
    'ジャンル02',
    'ジャンル03',
    'ジャンル04',
  ];
  
  // 削除確認用チェックボックス
  bool idChecked = false;
  bool nameChecked = false;
  bool genreChecked = false;

  @override
  void initState() {
    super.initState();
    
    // コントローラー初期化
    nameController = TextEditingController(text: widget.artist.name);
    genreController = TextEditingController(text: widget.artist.genre);
    genreIdController = TextEditingController(text: widget.artist.genreId ?? '');
    artistApiIdController = TextEditingController(text: widget.artist.artistApiId ?? '');
    descriptionController = TextEditingController(text: widget.artist.description ?? '');
    imageUrlController = TextEditingController(text: widget.artist.imageUrl ?? '');
    
    // 元の値を保存（キャンセル用）
    _originalName = widget.artist.name;
    _originalGenre = widget.artist.genre;
    _originalGenreId = widget.artist.genreId ?? '';
    _originalArtistApiId = widget.artist.artistApiId ?? '';
    _originalDescription = widget.artist.description ?? '';
    _originalImageUrl = widget.artist.imageUrl ?? '';
    _originalStatus = widget.artist.status;
    
    // 選択状態初期化
    selectedStatus = widget.artist.status;
    
    // 新規作成の場合は編集モードで開始
    if (widget.isNew) {
      _isEditing = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: BottomAdminLayout(
        selectedMenu: selectedMenu,
        onMenuSelected: (menu) {
          setState(() {
            selectedMenu = menu;
          });
        },
        selectedTab: selectedTab,
        onTabSelected: (tab) {
          if (tab != null) {
            setState(() {
              selectedTab = tab;
            });
          }
        },
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
        
        // ジャンルID
        _buildDetailRow('ジャンルID', genreIdController.text),
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
            Navigator.pop(context);
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
            onPressed: _toggleStatus,
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
            onPressed: _toggleStatus,
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
          onPressed: _showDeleteDialog,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            elevation: 0,
          ),
          child: const Text('アーティスト削除', style: TextStyle(color: Colors.white)),
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
      genreIdController.text = _originalGenreId;
      artistApiIdController.text = _originalArtistApiId;
      descriptionController.text = _originalDescription;
      imageUrlController.text = _originalImageUrl;
      selectedStatus = _originalStatus;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('編集をキャンセルしました')),
    );
  }

  void _toggleStatus() {
    setState(() {
      selectedStatus = selectedStatus == '有効' ? '無効' : '有効';
      
      // 状態変更を通知
      if (widget.onStatusChanged != null) {
        final updatedArtist = Artist(
          id: widget.artist.id,
          name: nameController.text,
          genre: genreController.text,
          status: selectedStatus,
          isActive: selectedStatus == '有効',
          addedDate: widget.artist.addedDate,
          updatedDate: DateTime.now(),
          genreId: genreIdController.text.isEmpty ? null : genreIdController.text,
          artistApiId: artistApiIdController.text.isEmpty ? null : artistApiIdController.text,
          description: descriptionController.text.isEmpty ? null : descriptionController.text,
          imageUrl: imageUrlController.text.isEmpty ? null : imageUrlController.text,
        );
        widget.onStatusChanged!(updatedArtist, 'status_changed');
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('状態を${selectedStatus}に変更しました')),
    );
  }

  void _saveChanges() {
    final updatedArtist = Artist(
      id: widget.artist.id,
      name: nameController.text,
      genre: genreController.text,
      status: selectedStatus,
      isActive: selectedStatus == '有効',
      addedDate: widget.artist.addedDate,
      updatedDate: DateTime.now(),
      genreId: genreIdController.text.isEmpty ? null : genreIdController.text,
      artistApiId: artistApiIdController.text.isEmpty ? null : artistApiIdController.text,
      description: descriptionController.text.isEmpty ? null : descriptionController.text,
      imageUrl: imageUrlController.text.isEmpty ? null : imageUrlController.text,
    );

    // 元の値を更新
    _originalName = nameController.text;
    _originalGenre = genreController.text;
    _originalGenreId = genreIdController.text;
    _originalArtistApiId = artistApiIdController.text;
    _originalDescription = descriptionController.text;
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

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // すべてのチェックボックスがチェックされているか確認
          final allChecked = idChecked && nameChecked && genreChecked;
          
          return AlertDialog(
            title: Container(
              alignment: Alignment.center,
              child: const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 100,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '削除確認',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '以下の項目をすべてチェックして、削除を確認してください:',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Column(
                    children: [
                      CheckboxListTile(
                        title: Text(
                          'ID: ${widget.artist.id}',
                          style: const TextStyle(fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                        value: idChecked,
                        onChanged: (value) => setDialogState(() => idChecked = value ?? false),
                        controlAffinity: ListTileControlAffinity.leading,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      CheckboxListTile(
                        title: Text(
                          'アーティスト: ${nameController.text}',
                          style: const TextStyle(fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                        value: nameChecked,
                        onChanged: (value) => setDialogState(() => nameChecked = value ?? false),
                        controlAffinity: ListTileControlAffinity.leading,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      CheckboxListTile(
                        title: Text(
                          'ジャンル: ${genreController.text}',
                          style: const TextStyle(fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                        value: genreChecked,
                        onChanged: (value) => setDialogState(() => genreChecked = value ?? false),
                        controlAffinity: ListTileControlAffinity.leading,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (!allChecked)
                    Text(
                      '※すべての項目にチェックを入れてください',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: allChecked
                        ? () {
                            _deleteArtist();
                            Navigator.pop(context);
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: const Text('アーティストを削除する', style: TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: TextButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text('キャンセル', style: TextStyle(color: Colors.grey)),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  void _deleteArtist() {
    final deletedArtist = Artist(
      id: widget.artist.id,
      name: nameController.text,
      genre: genreController.text,
      status: selectedStatus,
      isActive: selectedStatus == '有効',
      addedDate: widget.artist.addedDate,
      genreId: genreIdController.text.isEmpty ? null : genreIdController.text,
      artistApiId: artistApiIdController.text.isEmpty ? null : artistApiIdController.text,
      description: descriptionController.text.isEmpty ? null : descriptionController.text,
      imageUrl: imageUrlController.text.isEmpty ? null : imageUrlController.text,
    );
    
    Navigator.pop(context, {
      'action': 'delete',
      'artist': deletedArtist,
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    genreController.dispose();
    genreIdController.dispose();
    artistApiIdController.dispose();
    descriptionController.dispose();
    imageUrlController.dispose();
    super.dispose();
  }
}