import 'package:flutter/material.dart';
import '../services/room_invitation_service.dart';
import '../services/token_storage_service.dart';
import '../services/room_api_service.dart';

/// ルーム招待一覧画面
/// 受信した招待を一覧表示し、受理/拒否できます
class RoomInvitationsScreen extends StatefulWidget {
  const RoomInvitationsScreen({Key? key}) : super(key: key);

  @override
  State<RoomInvitationsScreen> createState() => _RoomInvitationsScreenState();
}

class _RoomInvitationsScreenState extends State<RoomInvitationsScreen> {
  final RoomInvitationService _invitationService = RoomInvitationService();
  final RoomApiService _roomApiService = RoomApiService();
  final TokenStorageService _tokenStorage = TokenStorageService();

  List<Map<String, dynamic>> _invitations = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchInvitations();
  }

  Future<void> _fetchInvitations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId = await _tokenStorage.getUserId();
      final accessToken = await _tokenStorage.getAccessToken();

      if (userId == null || accessToken == null) {
        throw Exception('認証情報がありません');
      }

      final invitations = await _roomApiService.getInvitations(
        userId: userId,
        accessToken: accessToken,
      );

      if (mounted) {
        setState(() {
          _invitations = invitations;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _acceptInvitation(Map<String, dynamic> invitation) async {
    final roomId = invitation['roomId'] as int;

    try {
      final result = await _invitationService.acceptInvitation(roomId);

      if (result != null && mounted) {
        // 招待リストを更新
        await _invitationService.refreshInvitations();

        // alreadyJoined の場合は isGuest=false で遷移（既に参加済み）
        final bool alreadyJoined = result['alreadyJoined'] ?? false;

        // ルームマッチ画面に遷移
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/room-match?roomId=$roomId${alreadyJoined ? '' : '&isGuest=true'}',
          (route) => route.isFirst,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
        // リストを更新
        _fetchInvitations();
      }
    }
  }

  Future<void> _rejectInvitation(Map<String, dynamic> invitation) async {
    final roomId = invitation['roomId'] as int;
    final inviterName = invitation['inviter']?['username'] ?? '不明';

    // 確認ダイアログ
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('招待を拒否'),
        content: Text('$inviterName さんからの招待を拒否しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('拒否'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _invitationService.rejectInvitation(roomId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('招待を拒否しました'),
            backgroundColor: Colors.orange,
          ),
        );

        // リストを更新
        setState(() {
          _invitations.removeWhere((inv) => inv['roomId'] == roomId);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
        _fetchInvitations();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('受信した招待'),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red[700]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchInvitations,
              child: const Text('再試行'),
            ),
          ],
        ),
      );
    }

    if (_invitations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mail_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '招待はありません',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'フレンドからの招待がここに表示されます',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchInvitations,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _invitations.length,
        itemBuilder: (context, index) {
          return _buildInvitationCard(_invitations[index]);
        },
      ),
    );
  }

  Widget _buildInvitationCard(Map<String, dynamic> invitation) {
    final inviter = invitation['inviter'] as Map<String, dynamic>?;
    final inviterName = inviter?['username'] ?? '不明なユーザー';
    final inviterImageUrl = inviter?['imageUrl'];
    final invitedAt = invitation['invitedAt'];

    String timeAgo = '';
    if (invitedAt != null) {
      try {
        final invitedTime = DateTime.parse(invitedAt);
        final diff = DateTime.now().difference(invitedTime);
        if (diff.inMinutes < 1) {
          timeAgo = 'たった今';
        } else if (diff.inMinutes < 60) {
          timeAgo = '${diff.inMinutes}分前';
        } else if (diff.inHours < 24) {
          timeAgo = '${diff.inHours}時間前';
        } else {
          timeAgo = '${diff.inDays}日前';
        }
      } catch (e) {
        timeAgo = '';
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // アバター
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.blue.shade50,
                  backgroundImage: inviterImageUrl != null
                      ? NetworkImage(inviterImageUrl)
                      : null,
                  child: inviterImageUrl == null
                      ? const Icon(Icons.person, color: Colors.blue)
                      : null,
                ),
                const SizedBox(width: 12),

                // ユーザー情報
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        inviterName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (timeAgo.isNotEmpty)
                        Text(
                          timeAgo,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),

                // 招待アイコン
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.videogame_asset,
                        size: 16,
                        color: Colors.green.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Room Match',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // メッセージ
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.mail,
                    color: Colors.blue,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$inviterName さんから対戦の招待が届いています',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // アクションボタン
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _rejectInvitation(invitation),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: const Text('拒否'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () => _acceptInvitation(invitation),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text('参加する'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
