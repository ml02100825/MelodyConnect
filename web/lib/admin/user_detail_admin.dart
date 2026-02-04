import 'package:flutter/material.dart';
import 'user_model.dart';
import 'bottom_admin.dart';
import 'services/admin_api_service.dart';

class UserDetailAdmin extends StatefulWidget {
  final User user;

  const UserDetailAdmin({Key? key, required this.user}) : super(key: key);

  @override
  _UserDetailAdminState createState() => _UserDetailAdminState();
}

class _UserDetailAdminState extends State<UserDetailAdmin> {
  late User _user;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
  }

  bool get _isDeleted => _user.deleteFlag;

  void _showDeleteConfirmation() {
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
            onPressed: _isLoading ? null : () async {
              Navigator.pop(context);
              await _toggleDeleteAccount();
            },
            child: const Text('はい'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleDeleteAccount() async {
    final wasDeleted = _isDeleted;
    setState(() {
      _isLoading = true;
    });

    try {
      if (wasDeleted) {
        await AdminApiService.restoreUser(_user.numericId);
        _user.deleteFlag = false;
      } else {
        await AdminApiService.deleteUser(_user.numericId);
        _user.deleteFlag = true;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(wasDeleted ? 'アカウントの削除を解除しました' : 'アカウントを削除しました')),
        );
      }
      if (mounted) {
        Navigator.pop(context, {'action': wasDeleted ? 'updated' : 'delete', 'user': _user});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('アカウントの削除に失敗しました: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _freezeAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('アカウント停止'),
        content: Text('本当にこのアカウントを停止しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('停止', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await AdminApiService.freezeUsers([_user.numericId]);
      setState(() {
        _user.freeze();
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('アカウントを停止しました')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('アカウント停止に失敗しました: $e')),
        );
      }
    }
  }

  Future<void> _unfreezeAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('アカウント復旧'),
        content: Text('本当にこのアカウントを復旧しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('復旧', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await AdminApiService.unfreezeUsers([_user.numericId]);
      setState(() {
        _user.unfreeze();
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('アカウントを復旧しました')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('アカウント復旧に失敗しました: $e')),
        );
      }
    }
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '－';
    return '${dateTime.year}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.day.toString().padLeft(2, '0')} '
           '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Stack(
        children: [
          BottomAdminLayout(
            mainContent: _buildMainContent(),
            selectedMenu: 'ユーザー管理',
            showTabs: false,
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
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
                        _user.username,
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
              _buildInfoRow('ID', _user.id),
              _buildInfoRow('UUID', _user.uuid),
              _buildInfoRow('メールアドレス', _user.email),
              _buildInfoRow('total_play', _user.totalPlay.toString()),
              SizedBox(height: 40),
              _buildInfoRow('サブスク', _user.subscription),
            ],
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            children: [
              _buildInfoRow('アカウント作成日', _formatDateTime(_user.accountCreated)),
              _buildInfoRow('最終ログイン日時', _formatDateTime(_user.lastLogin)),
              _buildInfoRow('サブスク登録日時', _formatDateTime(_user.subscriptionRegistered)),
              _buildInfoRow('サブスク解約日時', _formatDateTime(_user.subscriptionCancelled)),
              SizedBox(height: 40),
              _buildInfoRow('アカウント状態', _user.isFrozen ? '停止中' : '有効'),
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
            Navigator.pop(context, {'action': 'updated'});
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
                onPressed: _isLoading ? null : (_user.isFrozen ? _unfreezeAccount : _freezeAccount),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _user.isFrozen ? Colors.green : Colors.orange,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  _user.isFrozen ? 'アカウント復旧' : 'アカウント停止',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              SizedBox(width: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _showDeleteConfirmation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  elevation: 0,
                ),
                child: Text(_isDeleted ? 'アカウント削除解除' : 'アカウント削除', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
