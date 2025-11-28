import 'package:flutter/material.dart';
import '../bottom_nav.dart';
import 'friend_profile.dart';
 
class FriendListScreen extends StatefulWidget {
  const FriendListScreen({Key? key}) : super(key: key);
 
  @override
  State<FriendListScreen> createState() => _FriendListScreenState();
}
 
class _FriendListScreenState extends State<FriendListScreen> {
  final TextEditingController _searchController = TextEditingController();
 
  // 仮のフレンドリスト
  final List<Friend> friends = [
    Friend(
      id: '100001',
      name: 'カザフスタン斉藤',
      status: '最終ログイン 2時間前',
      avatarColor: Colors.purple[100]!,
    ),
    Friend(
      id: '100002',
      name: 'mattari.s',
      status: '最終ログイン 0分前',
      avatarColor: Colors.purple[100]!,
    ),
    Friend(
      id: '100003',
      name: 'tom',
      status: '最終ログイン 0分前',
      avatarColor: Colors.purple[100]!,
    ),
  ];
 
  // 検索結果リスト
  List<Friend> filteredFriends = [];
 
  @override
  void initState() {
    super.initState();
    filteredFriends = friends;
    _searchController.addListener(_onSearchChanged);
  }
 
  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredFriends = friends;
      } else {
        filteredFriends = friends
            .where((f) => f.name.toLowerCase().contains(query))
            .toList();
      }
    });
  }
 
  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }
 
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
        title: const Text(
          'フレンド一覧',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 検索バー
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'フレンドを検索',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            // 検索結果リスト
            Expanded(
              child: filteredFriends.isEmpty
                  ? Center(
                      child: Text(
                        '検索結果がありません',
                        style: TextStyle(
                          color: Colors.red[600],
                          fontSize: 16,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredFriends.length,
                      itemBuilder: (context, index) {
                        return _buildFriendItem(filteredFriends[index]);
                      },
                    ),
            ),
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
 
  Widget _buildFriendItem(Friend friend) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FriendProfile(
                    userName: friend.name,
                    userId: friend.id,
                    lastLogin: friend.status,
                    isFriend: true,
                  ),
                ),
              );
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: friend.avatarColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.person,
                color: Colors.purple[300],
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  friend.status,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
 
class Friend {
  final String id;
  final String name;
  final String status;
  final Color avatarColor;
 
  Friend({
    required this.id,
    required this.name,
    required this.status,
    required this.avatarColor,
  });
}
 
 