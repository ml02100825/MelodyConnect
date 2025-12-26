import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../services/token_storage_service.dart';
import '../services/room_api_service.dart';

/// ルームマッチ画面
/// フレンドとのプライベート対戦を行います
class RoomMatchScreen extends StatefulWidget {
  final int? roomId;  // 招待から参加する場合は roomId を受け取る
  final bool isGuest; // ゲストとして参加する場合 true

  const RoomMatchScreen({
    Key? key,
    this.roomId,
    this.isGuest = false,
  }) : super(key: key);

  @override
  State<RoomMatchScreen> createState() => _RoomMatchScreenState();
}

class _RoomMatchScreenState extends State<RoomMatchScreen> {
  final _tokenStorage = TokenStorageService();
  final _roomApiService = RoomApiService();
  StompClient? _stompClient;

  int? _userId;
  String? _accessToken;
  Map<String, dynamic>? _room;
  List<Map<String, dynamic>> _invitedUsers = [];
  bool _isLoading = true;
  bool _isReady = false;
  String _statusMessage = '';

  // 設定（ホストのみ）
  int _matchType = 5; // 先取数
  String _language = 'english';

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _stompClient?.deactivate();
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      _userId = await _tokenStorage.getUserId();
      _accessToken = await _tokenStorage.getAccessToken();

      if (_userId == null || _accessToken == null) {
        throw Exception('認証情報が見つかりません');
      }

      if (widget.roomId != null && widget.isGuest) {
        // 招待から参加する場合
        await _joinRoom(widget.roomId!);
      } else if (widget.roomId != null) {
        // 既存の部屋に戻る場合
        await _loadRoom(widget.roomId!);
      } else {
        // 新規部屋作成
        await _createRoom();
      }

      _connectWebSocket();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _statusMessage = 'エラー: $e';
      });
    }
  }

  /// 部屋を作成
  Future<void> _createRoom() async {
    try {
      final room = await _roomApiService.createRoom(
        hostId: _userId!,
        matchType: _matchType,
        language: _language,
        accessToken: _accessToken!,
      );

      setState(() {
        _room = room;
        _isLoading = false;
        _statusMessage = 'フレンドを招待してください';
      });
    } catch (e) {
      rethrow;
    }
  }

  /// 部屋情報を読み込む
  Future<void> _loadRoom(int roomId) async {
    try {
      final room = await _roomApiService.getRoom(
        roomId: roomId,
        accessToken: _accessToken!,
      );

      setState(() {
        _room = room;
        _matchType = room['matchType'] ?? 5;
        _language = room['language'] ?? 'english';
        _isLoading = false;
      });

      await _loadInvitedUsers();
    } catch (e) {
      rethrow;
    }
  }

  /// 部屋に参加
  Future<void> _joinRoom(int roomId) async {
    try {
      final room = await _roomApiService.acceptInvitation(
        roomId: roomId,
        userId: _userId!,
        accessToken: _accessToken!,
      );

      setState(() {
        _room = room;
        _matchType = room['matchType'] ?? 5;
        _language = room['language'] ?? 'english';
        _isLoading = false;
        _statusMessage = '部屋に参加しました';
      });
    } catch (e) {
      rethrow;
    }
  }

  /// 招待済みユーザーを読み込む
  Future<void> _loadInvitedUsers() async {
    if (_room == null) return;

    try {
      final users = await _roomApiService.getInvitedUsers(
        roomId: _room!['roomId'],
        accessToken: _accessToken!,
      );

      setState(() {
        _invitedUsers = users;
      });
    } catch (e) {
      debugPrint('招待済みユーザー取得エラー: $e');
    }
  }

  /// WebSocket接続
  void _connectWebSocket() {
    _stompClient = StompClient(
      config: StompConfig(
        url: 'ws://localhost:8080/ws',
        webSocketConnectHeaders: {
          'Sec-WebSocket-Protocol': 'v12.stomp',
        },
        onConnect: (StompFrame frame) {
          if (!mounted) return;

          // ルーム通知を購読
          _stompClient!.subscribe(
            destination: '/topic/room/$_userId',
            callback: (StompFrame frame) {
              if (frame.body == null) return;
              final data = jsonDecode(frame.body!);
              _handleRoomMessage(data);
            },
          );

          // 招待通知を購読
          _stompClient!.subscribe(
            destination: '/topic/room-invitation/$_userId',
            callback: (StompFrame frame) {
              if (frame.body == null) return;
              final data = jsonDecode(frame.body!);
              _handleInvitationMessage(data);
            },
          );
        },
        onWebSocketError: (dynamic error) {
          debugPrint('WebSocketエラー: $error');
        },
      ),
    );

    _stompClient!.activate();
  }

  /// ルームメッセージを処理
  void _handleRoomMessage(Map<String, dynamic> data) {
    final type = data['type'];

    switch (type) {
      case 'guest_joined':
        _onGuestJoined(data);
        break;
      case 'guest_left':
        _onGuestLeft(data);
        break;
      case 'player_ready':
        _onPlayerReady(data);
        break;
      case 'player_unready':
        _onPlayerUnready(data);
        break;
      case 'match_start':
        _onMatchStart(data);
        break;
      case 'room_canceled':
        _onRoomCanceled(data);
        break;
      case 'room_reset':
        _onRoomReset(data);
        break;
    }
  }

  /// 招待メッセージを処理
  void _handleInvitationMessage(Map<String, dynamic> data) {
    final type = data['type'];
    if (type == 'room_invitation') {
      _showInvitationDialog(data);
    }
  }

  void _onGuestJoined(Map<String, dynamic> data) {
    setState(() {
      _room = data;
      _statusMessage = 'ゲストが参加しました！';
    });
  }

  void _onGuestLeft(Map<String, dynamic> data) {
    setState(() {
      _room = data;
      _statusMessage = 'ゲストが退出しました';
    });
  }

  void _onPlayerReady(Map<String, dynamic> data) {
    setState(() {
      _room = data;
    });
  }

  void _onPlayerUnready(Map<String, dynamic> data) {
    setState(() {
      _room = data;
    });
  }

  void _onMatchStart(Map<String, dynamic> data) {
    final matchId = data['matchId'] ?? '';
    final roomId = data['roomId'];
    Navigator.pushReplacementNamed(
      context,
      '/battle?matchId=$matchId&isRoomMatch=true&roomId=$roomId',
    );
  }

  void _onRoomCanceled(Map<String, dynamic> data) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ホストが部屋を解散しました'),
        backgroundColor: Colors.red,
      ),
    );
    Navigator.pop(context);
  }

  void _onRoomReset(Map<String, dynamic> data) {
    setState(() {
      _room = data;
      _isReady = false;
      _statusMessage = '再戦準備完了！';
    });
  }

  void _showInvitationDialog(Map<String, dynamic> data) {
    final inviter = data['inviter'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ルームマッチへの招待'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: inviter['imageUrl'] != null
                  ? NetworkImage(inviter['imageUrl'])
                  : null,
              child: inviter['imageUrl'] == null
                  ? const Icon(Icons.person)
                  : null,
            ),
            const SizedBox(height: 16),
            Text('${inviter['username']} さんから招待が届きました'),
            const SizedBox(height: 8),
            Text('先取${data['matchType']}本勝負'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('後で'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => RoomMatchScreen(
                    roomId: data['roomId'],
                    isGuest: true,
                  ),
                ),
              );
            },
            child: const Text('参加'),
          ),
        ],
      ),
    );
  }

  /// 準備完了を切り替え
  void _toggleReady() {
    if (_room == null || _stompClient == null) return;

    final destination = _isReady ? '/app/room/cancel-ready' : '/app/room/ready';
    _stompClient!.send(
      destination: destination,
      body: jsonEncode({
        'roomId': _room!['roomId'],
        'userId': _userId,
      }),
    );

    setState(() {
      _isReady = !_isReady;
    });
  }

  /// 対戦開始（ホストのみ）
  void _startMatch() {
    if (_room == null || _stompClient == null) return;

    _stompClient!.send(
      destination: '/app/room/start',
      body: jsonEncode({
        'roomId': _room!['roomId'],
        'userId': _userId,
      }),
    );
  }

  /// 退出
  Future<void> _leaveRoom() async {
    if (_room == null) {
      Navigator.pop(context);
      return;
    }

    try {
      await _roomApiService.leaveRoom(
        roomId: _room!['roomId'],
        userId: _userId!,
        accessToken: _accessToken!,
      );
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('退出エラー: $e')),
      );
    }
  }

  bool get _isHost => _room != null && _room!['hostId'] == _userId;
  bool get _hasGuest => _room != null && _room!['guestId'] != null;
  bool get _guestReady => _room != null && (_room!['guestReady'] ?? false);
  bool get _canStart => _isHost && _hasGuest && _guestReady;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _leaveRoom();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Room Match'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _leaveRoom,
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ルーム情報
          _buildRoomInfo(),
          const SizedBox(height: 24),

          // プレイヤー情報
          _buildPlayersInfo(),
          const SizedBox(height: 24),

          // ステータスメッセージ
          if (_statusMessage.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _statusMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          const SizedBox(height: 24),

          // アクションボタン
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildRoomInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              '先取 $_matchType 本勝負',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '言語: ${_language == 'english' ? '英語' : '韓国語'}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            if (_room != null)
              Text(
                'Room ID: ${_room!['roomId']}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[400],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayersInfo() {
    return Row(
      children: [
        // ホスト
        Expanded(
          child: _buildPlayerCard(
            label: 'ホスト',
            player: _room?['host'],
            isReady: _room?['hostReady'] ?? false,
            isCurrentUser: _isHost,
          ),
        ),
        const SizedBox(width: 16),
        const Icon(Icons.sports_kabaddi, size: 32),
        const SizedBox(width: 16),
        // ゲスト
        Expanded(
          child: _hasGuest
              ? _buildPlayerCard(
                  label: 'ゲスト',
                  player: _room?['guest'],
                  isReady: _guestReady,
                  isCurrentUser: !_isHost,
                )
              : _buildWaitingCard(),
        ),
      ],
    );
  }

  Widget _buildPlayerCard({
    required String label,
    Map<String, dynamic>? player,
    required bool isReady,
    required bool isCurrentUser,
  }) {
    return Card(
      color: isCurrentUser ? Colors.blue[50] : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            CircleAvatar(
              radius: 30,
              backgroundImage: player?['imageUrl'] != null
                  ? NetworkImage(player!['imageUrl'])
                  : null,
              child: player?['imageUrl'] == null
                  ? const Icon(Icons.person)
                  : null,
            ),
            const SizedBox(height: 8),
            Text(
              player?['username'] ?? '---',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isReady ? Colors.green : Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isReady ? '準備完了' : '準備中',
                style: TextStyle(
                  fontSize: 12,
                  color: isReady ? Colors.white : Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaitingCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'ゲスト',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.grey[200],
              child: Icon(
                Icons.person_add,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '待機中...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            if (_isHost && _invitedUsers.isNotEmpty)
              Text(
                '招待済み: ${_invitedUsers.length}人',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange[600],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_isHost && !_hasGuest)
          ElevatedButton.icon(
            onPressed: _showInviteFriendDialog,
            icon: const Icon(Icons.person_add),
            label: const Text('フレンドを招待'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
          ),

        if (_hasGuest) ...[
          ElevatedButton.icon(
            onPressed: _toggleReady,
            icon: Icon(_isReady ? Icons.close : Icons.check),
            label: Text(_isReady ? '準備解除' : '準備完了'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isReady ? Colors.orange : Colors.green,
              padding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 16),
        ],

        if (_canStart)
          ElevatedButton.icon(
            onPressed: _startMatch,
            icon: const Icon(Icons.play_arrow),
            label: const Text('対戦開始！'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.all(16),
            ),
          ),

        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _leaveRoom,
          icon: const Icon(Icons.exit_to_app),
          label: Text(_isHost ? '部屋を解散' : '退出'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            padding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  void _showInviteFriendDialog() {
    // TODO: フレンド一覧から選択するダイアログを実装
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('フレンドを招待'),
        content: const Text('フレンド一覧機能は準備中です'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
