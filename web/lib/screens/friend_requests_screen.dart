import 'package:flutter/material.dart';
import '../bottom_nav.dart';

class FriendRequestsScreen extends StatefulWidget {
  const FriendRequestsScreen({Key? key}) : super(key: key);

  @override
  State<FriendRequestsScreen> createState() => _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends State<FriendRequestsScreen> {
  // ダミーの申請リスト（将来 API で取得）
  final List<Map<String, String>> _requests = [
    {
      'id': 'r1',
      'name': '斎藤１２３',
      'lastLogin': '最終ログイン  2時間前',
    },{
      'id': 'r2',
      'name': '斎藤４５６',
      'lastLogin': '最終ログイン  1時間前',
    },
  ];

  String? _toastMessage; // '許可しました' / '拒否しました'

  void _showToast(String message) {
    setState(() => _toastMessage = message);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _toastMessage = null);
    });
  }

  void _acceptRequest(String id) {
    setState(() {
      _requests.removeWhere((r) => r['id'] == id);
    });
    _showToast('許可しました');
  }

  void _declineRequest(String id) {
    setState(() {
      _requests.removeWhere((r) => r['id'] == id);
    });
    _showToast('拒否しました');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('フレンド申請一覧', style: TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          _requests.isEmpty
              ? Center(
                  child: Text(
                    'まだ何も来ていません...',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _requests.length,
                  itemBuilder: (context, index) {
                    final r = _requests[index];
                    return _requestCard(r['id']!, r['name']!, r['lastLogin']!);
                  },
                ),

          // トースト風バナー（上部中央）
          if (_toastMessage != null)
            Positioned(
              top: 12,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade600),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(_toastMessage!),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 3,
        onTap: (index) {},
      ),
    );
  }

  Widget _requestCard(String id, String name, String lastLogin) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        color: Colors.white,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.blue.shade50,
            child: const Icon(Icons.person, color: Colors.purple),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  lastLogin,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          // 承認ボタン
          SizedBox(
            width: 40,
            height: 40,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                shape: const CircleBorder(),
                padding: EdgeInsets.zero,
                side: BorderSide(color: Colors.grey.shade400),
              ),
              onPressed: () => _acceptRequest(id),
              child: const Icon(Icons.check),
            ),
          ),
          const SizedBox(width: 8),
          // 拒否ボタン
          SizedBox(
            width: 40,
            height: 40,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                shape: const CircleBorder(),
                padding: EdgeInsets.zero,
                side: BorderSide(color: Colors.grey.shade400),
              ),
              onPressed: () => _declineRequest(id),
              child: const Icon(Icons.close),
            ),
          ),
        ],
      ),
    );
  }
}
