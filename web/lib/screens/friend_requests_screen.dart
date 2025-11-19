import 'package:flutter/material.dart';
import '../services/friend_api_service.dart';
import '../services/token_storage_service.dart';

class FriendRequestsScreen extends StatefulWidget {
  const FriendRequestsScreen({Key? key}) : super(key: key);

  @override
  State<FriendRequestsScreen> createState() => _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends State<FriendRequestsScreen> {
  final FriendApiService _friendApiService = FriendApiService();
  final TokenStorageService _tokenStorage = TokenStorageService();

  List<dynamic> _requests = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
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

      final requests = await _friendApiService.getPendingRequests(userId, accessToken);
      setState(() {
        _requests = requests;
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

  Future<void> _acceptRequest(int friendId) async {
    try {
      final accessToken = await _tokenStorage.getAccessToken();
      final userId = await _tokenStorage.getUserId();

      if (accessToken == null || userId == null) {
        throw Exception('ログインが必要です');
      }

      await _friendApiService.acceptFriendRequest(userId, friendId, accessToken);

      setState(() {
        _requests.removeWhere((r) => r['friendId'] == friendId);
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('フレンド申請を承認しました'),
          backgroundColor: Colors.green,
        ),
      );
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

  Future<void> _rejectRequest(int friendId) async {
    try {
      final accessToken = await _tokenStorage.getAccessToken();
      final userId = await _tokenStorage.getUserId();

      if (accessToken == null || userId == null) {
        throw Exception('ログインが必要です');
      }

      await _friendApiService.rejectFriendRequest(userId, friendId, accessToken);

      setState(() {
        _requests.removeWhere((r) => r['friendId'] == friendId);
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('フレンド申請を拒否しました'),
          backgroundColor: Colors.orange,
        ),
      );
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('フレンド申請一覧', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _loadRequests,
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
                        onPressed: _loadRequests,
                        child: const Text('再読み込み'),
                      ),
                    ],
                  ),
                )
              : _requests.isEmpty
                  ? Center(
                      child: Text(
                        'フレンド申請がありません',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadRequests,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _requests.length,
                        itemBuilder: (context, index) {
                          return _requestCard(_requests[index]);
                        },
                      ),
                    ),
    );
  }

  Widget _requestCard(Map<String, dynamic> request) {
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
            backgroundImage: request['requesterImageUrl'] != null
                ? NetworkImage(request['requesterImageUrl'])
                : null,
            child: request['requesterImageUrl'] == null
                ? const Icon(Icons.person, color: Colors.purple)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request['requesterUsername'] ?? '',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '@${request['requesterUserUuid'] ?? ''}',
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
                side: const BorderSide(color: Colors.green),
              ),
              onPressed: () => _acceptRequest(request['friendId']),
              child: const Icon(Icons.check, color: Colors.green),
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
                side: const BorderSide(color: Colors.red),
              ),
              onPressed: () => _rejectRequest(request['friendId']),
              child: const Icon(Icons.close, color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
