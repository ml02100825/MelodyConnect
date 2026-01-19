import 'package:flutter/material.dart';
import '../services/friend_api_service.dart';
import '../services/token_storage_service.dart';

/// ユーザ検索画面
class UserSearchScreen extends StatefulWidget {
  const UserSearchScreen({Key? key}) : super(key: key);

  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final FriendApiService _friendApiService = FriendApiService();
  final TokenStorageService _tokenStorage = TokenStorageService();

  Map<String, dynamic>? _searchResult;
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasSearched = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _searchUser() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _hasSearched = true;
    });

    try {
      final accessToken = await _tokenStorage.getAccessToken();
      if (accessToken == null) {
        throw Exception('ログインが必要です');
      }

      final result = await _friendApiService.searchUser(query, accessToken);
      setState(() {
        _searchResult = result;
      });
    } catch (e) {
      setState(() {
        _searchResult = null;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendFriendRequest() async {
    if (_searchResult == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final accessToken = await _tokenStorage.getAccessToken();
      final userId = await _tokenStorage.getUserId();

      if (accessToken == null || userId == null) {
        throw Exception('ログインが必要です');
      }

      await _friendApiService.sendFriendRequest(
        userId,
        _searchResult!['userUuid'],
        accessToken,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('「${_searchResult!['username']}」にフレンド申請を送信しました'),
          backgroundColor: Colors.green,
        ),
      );

      // 検索結果をクリア
      setState(() {
        _searchResult = null;
        _controller.clear();
        _hasSearched = false;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ユーザー検索'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isWide ? 24 : 16),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isWide ? 500 : double.infinity),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                // 検索入力
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          decoration: const InputDecoration(
                            hintText: 'ユーザーIDを入力',
                            border: InputBorder.none,
                          ),
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) => _searchUser(),
                          enabled: !_isLoading,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: _isLoading ? null : _searchUser,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 検索結果
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  )
                else if (_searchResult != null)
                  _buildUserCard()
                else if (_hasSearched)
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Text(
                      'ユーザーが見つかりません',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard() {
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
          // アイコン
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.blue.shade50,
            backgroundImage: _searchResult!['imageUrl'] != null
                ? NetworkImage(_searchResult!['imageUrl'])
                : null,
            child: _searchResult!['imageUrl'] == null
                ? const Icon(Icons.person, color: Colors.purple)
                : null,
          ),
          const SizedBox(width: 12),

          // ユーザー情報
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _searchResult!['username'] ?? '',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '@${_searchResult!['userUuid']}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),

          // 追加ボタン
          SizedBox(
            width: 40,
            height: 40,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                shape: const CircleBorder(),
                padding: EdgeInsets.zero,
                side: BorderSide(color: Colors.grey.shade400),
              ),
              onPressed: _isLoading ? null : _sendFriendRequest,
              child: const Icon(Icons.person_add),
            ),
          ),
        ],
      ),
    );
  }
}