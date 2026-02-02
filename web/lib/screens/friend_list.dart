import 'package:flutter/material.dart';
import '../services/friend_api_service.dart';
import '../services/token_storage_service.dart';
import 'friend_profile_screen.dart';

class FriendListScreen extends StatefulWidget {
  const FriendListScreen({Key? key}) : super(key: key);

  @override
  State<FriendListScreen> createState() => _FriendListScreenState();
}

class _FriendListScreenState extends State<FriendListScreen> {
  final FriendApiService _friendApiService = FriendApiService();
  final TokenStorageService _tokenStorage = TokenStorageService();

  List<dynamic> _friends = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final accessToken = await _tokenStorage.getAccessToken();
      final userId = await _tokenStorage.getUserId();

      if (accessToken == null || userId == null) {
        throw Exception('ログインが必要です');
      }

      final friends = await _friendApiService.getFriendList(userId, accessToken);
      setState(() {
        _friends = friends;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToProfile(Map<String, dynamic> friend) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FriendProfileScreen(friendUserId: friend['userId']),
      ),
    );
  }

  Future<void> _deleteFriend(Map<String, dynamic> friend) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('フレンド削除'),
        content: Text('${friend['username']}さんをフレンドから削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final accessToken = await _tokenStorage.getAccessToken();
      final userId = await _tokenStorage.getUserId();

      if (accessToken == null || userId == null) {
        throw Exception('ログインが必要です');
      }

      await _friendApiService.deleteFriend(userId, friend['friendId'], accessToken);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('フレンドを削除しました'),
          backgroundColor: Colors.green,
        ),
      );

      _loadFriends();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _loadFriends,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadFriends,
                        child: const Text('再読み込み'),
                      ),
                    ],
                  ),
                )
              : _friends.isEmpty
                  ? Center(
                      child: Text(
                        'フレンドがいません',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadFriends,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _friends.length,
                        itemBuilder: (context, index) {
                          final friend = _friends[index] as Map<String, dynamic>;
                          return _buildFriendItem(friend);
                        },
                      ),
                    ),
    );
  }

  Widget _buildFriendItem(Map<String, dynamic> friend) {
    return GestureDetector(
      onTap: () => _navigateToProfile(friend),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            // アイコン
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.blue.shade50,
              backgroundImage: (friend['imageUrl'] != null && friend['imageUrl'].toString().isNotEmpty)
                  ? NetworkImage(friend['imageUrl'])
                  : null,
              child: (friend['imageUrl'] == null || friend['imageUrl'].toString().isEmpty)
                  ? const Icon(Icons.person, color: Colors.purple)
                  : null,
            ),
            const SizedBox(width: 12),
            // 名前とID
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    friend['username'] ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '@${friend['userUuid'] ?? ''}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            // 削除ボタン
            IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.red[400]),
              onPressed: () => _deleteFriend(friend),
              tooltip: '削除',
            ),
            // 矢印アイコン
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
