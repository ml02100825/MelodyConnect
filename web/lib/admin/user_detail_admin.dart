import 'package:flutter/material.dart';
import 'user_model.dart';
import 'user_list_admin.dart';
import 'bottom_admin.dart';

class UserDetailAdmin extends StatefulWidget {
  final User user;

  const UserDetailAdmin({Key? key, required this.user}) : super(key: key);

  @override
  _UserDetailAdminState createState() => _UserDetailAdminState();
}

class _UserDetailAdminState extends State<UserDetailAdmin> {
  // 削除確認用チェックボックス
  bool usernameChecked = false;
  bool idChecked = false;
  bool uuidChecked = false;
  bool emailChecked = false;
  bool refundChecked = false;

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Container(
              child: Icon(
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
                  _buildDeleteCheckbox(
                    'ユーザー名: ${widget.user.username}',
                    usernameChecked,
                    (value) => setDialogState(() => usernameChecked = value ?? false),
                  ),
                  _buildDeleteCheckbox(
                    'ID: ${widget.user.id}',
                    idChecked,
                    (value) => setDialogState(() => idChecked = value ?? false),
                  ),
                  _buildDeleteCheckbox(
                    'UUID: ${widget.user.uuid}',
                    uuidChecked,
                    (value) => setDialogState(() => uuidChecked = value ?? false),
                  ),
                  _buildDeleteCheckbox(
                    'メールアドレス: ${widget.user.email}',
                    emailChecked,
                    (value) => setDialogState(() => emailChecked = value ?? false),
                  ),
                  if (widget.user.subscription == '加入中')
                    _buildDeleteCheckbox(
                      'サブスク加入中のため、返金処理を行う',
                      refundChecked,
                      (value) => setDialogState(() => refundChecked = value ?? false),
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange[800]),
                    ),
                ],
              ),
            ),            
            actions: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: (usernameChecked && idChecked && uuidChecked && emailChecked && 
                              (widget.user.subscription != '加入中' || refundChecked))
                        ? () {
                            _deleteAccount();
                            Navigator.pop(context);
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      minimumSize: Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('アカウントを削除する', style: TextStyle(color: Colors.white)),
                  ),
                  
                  SizedBox(height: 8),
                  
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _resetDeleteCheckboxes();
                    },
                    child: Text('キャンセル', style: TextStyle(color: Colors.grey[700])),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDeleteCheckbox(String label, bool value, Function(bool?) onChanged, {TextStyle? style}) {
    return CheckboxListTile(
      title: Text(label, style: style ?? TextStyle(fontSize: 14)),
      value: value,
      onChanged: onChanged,
      controlAffinity: ListTileControlAffinity.leading,
      dense: true,
    );
  }

  void _resetDeleteCheckboxes() {
    setState(() {
      usernameChecked = false;
      idChecked = false;
      uuidChecked = false;
      emailChecked = false;
      refundChecked = false;
    });
  }

  void _deleteAccount() {
    // 削除前に結果を返す
    Navigator.pop(context, {'action': 'delete', 'user': widget.user});
  }

  void _freezeAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('アカウント停止'),
        content: Text('本当にこのアカウントを停止しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              // アカウント停止処理
              widget.user.freeze();
              setState(() {}); // 画面を更新
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('アカウントを停止しました')),
              );
            },
            child: Text('停止', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _unfreezeAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('アカウント復旧'),
        content: Text('本当にこのアカウントを復旧しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              // アカウント復旧処理
              widget.user.unfreeze();
              setState(() {}); // 画面を更新
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('アカウントを復旧しました')),
              );
            },
            child: Text('復旧', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: BottomAdminLayout(
        mainContent: _buildMainContent(),
        selectedMenu: 'ユーザー管理',
        showTabs: false,
      ),
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ユーザー基本情報
          _buildUserHeader(),
          SizedBox(height: 24),

          // ユーザー詳細情報
          _buildUserDetails(),
          SizedBox(height: 32),

          // 操作ボタン
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildUserHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ユーザー詳細',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            // アイコン画像
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.grey[300],
              child: Icon(Icons.person, size: 40, color: Colors.grey[600]),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        widget.user.username,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUserDetails() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: [
              _buildInfoRow('ID', widget.user.id),
              _buildInfoRow('UUID', widget.user.uuid),
              _buildInfoRow('メールアドレス', widget.user.email),
              SizedBox(height: 40),
              _buildInfoRow('サブスク', widget.user.subscription),
              _buildInfoRow('オンラインステータス', '公開'),
              _buildInfoRow('累計プレイ回数', '123456'),
              _buildInfoRow('ライフ', '4'),
              _buildInfoRow('音量', '65'),
            ],
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            children: [
              _buildInfoRow('アカウント作成日', '2026/01/01 00:00:00'),
              _buildInfoRow('最終ログイン日時', '2026/01/01 00:00:00'),
              _buildInfoRow('最終オフライン日時', '2026/01/01 00:00:00'),
              _buildInfoRow('サブスク登録日時', '2026/01/01 00:00:00'),
              _buildInfoRow('サブスク解約日時', '－'),
              SizedBox(height: 144),
              _buildInfoRow('アカウント状態', widget.user.isFrozen ? '停止中' : '有効'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 50, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 150,
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        // 左端：一覧へ戻る
        OutlinedButton(
          onPressed: () {
            Navigator.pop(context);
          },
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.grey,
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          child: Text('一覧へ戻る', style: TextStyle(color: Colors.white)),
        ),
        // 右端のボタン群
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: widget.user.isFrozen ? _unfreezeAccount : _freezeAccount,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.user.isFrozen ? Colors.green : Colors.orange,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  widget.user.isFrozen ? 'アカウント復旧' : 'アカウント停止',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              SizedBox(width: 16),
              ElevatedButton(
                onPressed: _showDeleteConfirmation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  elevation: 0,
                ),
                child: Text('アカウント削除', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}