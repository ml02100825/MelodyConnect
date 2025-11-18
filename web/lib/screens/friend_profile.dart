import 'package:flutter/material.dart';
import '../bottom_nav.dart';

class FriendProfile extends StatelessWidget {
  final String userName;
  final String userId;
  final String lastLogin;
  final bool isFriend; // フレンドかどうかを判定

  const FriendProfile({
    Key? key,
    required this.userName,
    required this.userId,
    required this.lastLogin,
    this.isFriend = false, // デフォルトはfalse（申請中）
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.account_circle, color: Colors.black, size: 20),
            const SizedBox(width: 4),
            Text(
              'ユーザID',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: Center(
              child: Text(
                userId,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Colors.black),
            onPressed: () {
              _showProfileMenu(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 16),
            
            // アバター
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.purple[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person,
                color: Colors.purple[300],
                size: 70,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // ユーザー名
            Text(
              userName,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // 現在のレート
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                '現在のレート',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // レート
            Text(
              '1400pt',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.blue[700],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // バッジ
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.amber[200]!),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.emoji_events, color: Colors.amber[700], size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'バッジ',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.amber[900],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // バッジグリッド
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1,
              ),
              itemCount: 6,
              itemBuilder: (context, index) {
                return _buildBadgeSlot(index == 0);
              },
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 3,
        onTap: (index) {
          // TODO: 画面遷移処理を書く
        },
      ),
    );
  }

  Widget _buildBadgeSlot(bool hasBadge) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: hasBadge ? Colors.amber[300]! : Colors.grey[300]!,
          width: 2,
        ),
        boxShadow: hasBadge
            ? [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.2),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: hasBadge
          ? Center(
              child: Icon(
                Icons.emoji_events,
                color: Colors.amber[700],
                size: 40,
              ),
            )
          : null,
    );
  }

  void _showProfileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // フレンドの場合のみ表示
              if (isFriend) ...[
                ListTile(
                  leading: const Icon(Icons.message, color: Colors.blue),
                  title: const Text('メッセージを送る'),
                  onTap: () {
                    Navigator.pop(context);
                    _sendMessage(context);
                  },
                ),
              ],
              ListTile(
                leading: const Icon(Icons.share, color: Colors.green),
                title: const Text('プロフィールを共有'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('プロフィールを共有しました'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              // フレンドの場合のみ表示
              if (isFriend) ...[
                ListTile(
                  leading: const Icon(Icons.person_remove, color: Colors.orange),
                  title: const Text('フレンドを解除'),
                  onTap: () {
                    Navigator.pop(context);
                    _removeFriend(context);
                  },
                ),
              ],
              ListTile(
                leading: const Icon(Icons.report, color: Colors.red),
                title: const Text('報告する'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('報告を送信しました'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              // フレンドの場合のみ表示
              if (isFriend) ...[
                ListTile(
                  leading: const Icon(Icons.block, color: Colors.red),
                  title: const Text('ブロックする'),
                  onTap: () {
                    Navigator.pop(context);
                    _blockUser(context);
                  },
                ),
              ],
              const Divider(),
              ListTile(
                leading: const Icon(Icons.close, color: Colors.grey),
                title: const Text('キャンセル'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _sendMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$userNameさんにメッセージを送信します'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _removeFriend(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'フレンドを解除',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            '$userNameさんをフレンドから解除しますか？',
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'キャンセル',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$userNameさんをフレンドから解除しました'),
                    duration: const Duration(seconds: 2),
                    backgroundColor: Colors.orange,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                '解除する',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _blockUser(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'ユーザーをブロック',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            '$userNameさんをブロックしますか？',
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'キャンセル',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$userNameさんをブロックしました'),
                    duration: const Duration(seconds: 2),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'ブロックする',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}