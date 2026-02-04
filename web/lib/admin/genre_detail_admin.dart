// genre_detail_admin.dart（ジャンル詳細画面）
import 'package:flutter/material.dart';
import 'bottom_admin.dart';
import 'genre_admin.dart';
import 'services/admin_api_service.dart';

class GenreDetailAdmin extends StatefulWidget {
  final Genre genre;
  final bool isNew;
  final Function(Genre, String)? onStatusChanged;

  const GenreDetailAdmin({
    Key? key,
    required this.genre,
    this.isNew = false,
    this.onStatusChanged,
  }) : super(key: key);

  @override
  State<GenreDetailAdmin> createState() => _GenreDetailAdminState();
}

class _GenreDetailAdminState extends State<GenreDetailAdmin> {
  String selectedMenu = 'コンテンツ管理';
  String selectedTab = 'ジャンル';
  
  // 編集モード管理
  bool _isEditing = false;
  
  // 編集用コントローラー
  late TextEditingController nameController;
  
  // 元の値（キャンセル用）
  late String _originalName;
  late String _originalStatus;
  
  // 選択用状態
  late String selectedStatus;
  bool _isUpdatingStatus = false;
  bool _isDeleting = false;
  
  // 削除確認用チェックボックス
  bool idChecked = false;
  bool nameChecked = false;

  @override
  void initState() {
    super.initState();
    
    // コントローラー初期化
    nameController = TextEditingController(text: widget.genre.name);
    
    // 元の値を保存（キャンセル用）
    _originalName = widget.genre.name;
    _originalStatus = widget.genre.status;
    
    // 選択状態初期化
    selectedStatus = widget.genre.status;
    
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
              
              // ジャンル詳細情報セクション
              _buildGenreDetailSection(),
              
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
                  'ジャンル詳細',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                // ジャンルアイコンセクション
                Container(
                  child: Row(
                    children: [
                      // ジャンルアイコン
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.purple[50],
                          borderRadius: BorderRadius.circular(40),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Icon(
                          Icons.category,
                          size: 40,
                          color: Colors.purple[700],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${widget.genre.name}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'ジャンル名',
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

  Widget _buildGenreDetailSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ID
        _buildDetailRow('ID', widget.genre.id),
        const SizedBox(height: 24),
        
        // 追加日
        _buildDetailRow(
          '追加日',
          '${widget.genre.addedDate.year}/${widget.genre.addedDate.month.toString().padLeft(2, '0')}/${widget.genre.addedDate.day.toString().padLeft(2, '0')}',
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
          width: 100,
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
            onPressed: _isUpdatingStatus ? null : _toggleStatus,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              elevation: 0,
            ),
            child: const Text('ジャンル無効化', style: TextStyle(color: Colors.white)),
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
            child: const Text('ジャンル有効化', style: TextStyle(color: Colors.white)),
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
          child: const Text('ジャンル削除', style: TextStyle(color: Colors.white)),
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
        await AdminApiService.enableGenres([widget.genre.numericId]);
      } else {
        await AdminApiService.disableGenres([widget.genre.numericId]);
      }
      if (!mounted) return;
      setState(() {
        selectedStatus = nextStatus;
      });
      if (widget.onStatusChanged != null) {
        final updatedGenre = Genre(
          id: widget.genre.id,
          name: nameController.text,
          status: selectedStatus,
          isActive: selectedStatus == '有効',
          addedDate: widget.genre.addedDate,
          updatedDate: DateTime.now(),
          numericId: widget.genre.numericId,
        );
        widget.onStatusChanged!(updatedGenre, 'status_changed');
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
    final updatedGenre = Genre(
      id: widget.genre.id,
      name: nameController.text,
      status: selectedStatus,
      isActive: selectedStatus == '有効',
      addedDate: widget.genre.addedDate,
      updatedDate: DateTime.now(),
      numericId: widget.genre.numericId,
    );

    // 元の値を更新
    _originalName = nameController.text;
    _originalStatus = selectedStatus;

    setState(() {
      _isEditing = false;
    });

    Navigator.pop(context, {
      'action': 'save',
      'genre': updatedGenre,
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
          final allChecked = idChecked && nameChecked;
          
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
                          'ID: ${widget.genre.id}',
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
                          'ジャンル名: ${nameController.text}',
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
                        ? () async {
                            Navigator.pop(context);
                            await _deleteGenre();
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: const Text('ジャンルを削除する', style: TextStyle(color: Colors.white)),
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

  Future<void> _deleteGenre() async {
    if (_isDeleting) return;
    setState(() {
      _isDeleting = true;
    });
    try {
      await AdminApiService.deleteGenre(widget.genre.numericId);
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ジャンルを削除しました')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ジャンルの削除に失敗しました: $e')),
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
    super.dispose();
  }
}
