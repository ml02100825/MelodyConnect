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
  final bool isReturning; // 対戦後に戻ってきた場合 true
  final bool skipAccept; // 既に招待受理済みなら true
  final bool isFromVocabulary; // 単語帳から戻った場合 true

  const RoomMatchScreen({
    Key? key,
    this.roomId,
    this.isGuest = false,
    this.isReturning = false,
    this.skipAccept = false,
    this.isFromVocabulary = false,
  }) : super(key: key);

  @override
  State<RoomMatchScreen> createState() => _RoomMatchScreenState();
}

class _RoomMatchScreenState extends State<RoomMatchScreen>
    with WidgetsBindingObserver {
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

  // 設定選択フェーズ
  bool _showSettingsPhase = false;  // ホストが開始ボタンを押した後の設定選択
  int _matchType = 5; // 先取数 (5/7/9)
  String _language = 'english';
  String _questionFormat = 'ALL_RANDOM'; // ALL_RANDOM / LISTENING_ONLY / FILL_IN_BLANK_ONLY
  String _problemType = 'COMPLETE_RANDOM'; // COMPLETE_RANDOM / FAVORITE_ARTIST / GENRE_RANDOM

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  @override
  void dispose() {
    _stompClient?.deactivate();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _stompClient?.deactivate();
    } else if (state == AppLifecycleState.resumed) {
      _connectWebSocket();
    }
  }

  Future<void> _initialize() async {
    try {
      _userId = await _tokenStorage.getUserId();
      _accessToken = await _tokenStorage.getAccessToken();

      if (_userId == null || _accessToken == null) {
        throw Exception('認証情報が見つかりません');
      }

      if (widget.roomId != null) {
        if (widget.isReturning) {
          // 対戦後に戻ってきた場合：部屋情報を再読み込みするだけ
          await _loadRoomAfterBattle(widget.roomId!);
        } else if (widget.isGuest) {
          if (widget.skipAccept) {
            await _loadRoom(widget.roomId!);
            setState(() {
              _statusMessage = '部屋に参加しました';
            });
          } else {
            // 招待から新規参加する場合
            await _joinRoom(widget.roomId!);
          }
        } else {
          // 既存の部屋に戻る場合
          await _loadRoom(widget.roomId!);
        }
      } else {
        // 新規部屋作成
        await _createRoom();
      }

      _connectWebSocket();

      if (widget.isFromVocabulary) {
        await _updateVocabularyStatus(false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _statusMessage = 'エラー: ${e.toString().replaceAll('Exception: ', '')}';
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
        problemType: _problemType,
        questionFormat: _questionFormat,
        accessToken: _accessToken!,
      );

      setState(() {
        _room = room;
        _matchType = room['matchType'] ?? 5;
        _language = room['language'] ?? 'english';
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
        _questionFormat = room['questionFormat'] ?? 'ALL_RANDOM';
        _problemType = room['problemType'] ?? 'COMPLETE_RANDOM';
        _isLoading = false;
      });

      await _loadInvitedUsers();
    } catch (e) {
      rethrow;
    }
  }

  /// 対戦後に部屋情報を読み込む（FINISHEDでもOK、リセットを待つ）
  Future<void> _loadRoomAfterBattle(int roomId) async {
    try {
      final room = await _roomApiService.getRoom(
        roomId: roomId,
        accessToken: _accessToken!,
      );

      final status = room['status'] as String?;

      setState(() {
        _room = room;
        _matchType = room['matchType'] ?? 5;
        _language = room['language'] ?? 'english';
        _questionFormat = room['questionFormat'] ?? 'ALL_RANDOM';
        _problemType = room['problemType'] ?? 'COMPLETE_RANDOM';
        _isReady = false; // 対戦後はreadyリセット
        _isLoading = false;

        if (status == 'FINISHED') {
          _statusMessage = '対戦終了！ホストがリセットするのを待っています...';
        } else if (status == 'WAITING') {
          _statusMessage = '再戦準備完了！';
        } else {
          _statusMessage = '';
        }
      });
    } catch (e) {
      rethrow;
    }
  }

  /// 部屋に参加（招待から）
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
        _questionFormat = room['questionFormat'] ?? 'ALL_RANDOM';
        _problemType = room['problemType'] ?? 'COMPLETE_RANDOM';
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

  Future<void> _updateVocabularyStatus(bool inVocabulary) async {
    final roomId = _room?['roomId'] ?? widget.roomId;
    if (roomId == null || _userId == null || _accessToken == null) return;

    try {
      await _roomApiService.updateVocabularyStatus(
        roomId: roomId,
        userId: _userId!,
        inVocabulary: inVocabulary,
        accessToken: _accessToken!,
      );
    } catch (e) {
      debugPrint('単語帳状態更新エラー: $e');
    }
  }

  /// WebSocket接続
  void _connectWebSocket() {
    if (_stompClient != null && _stompClient!.connected) {
      return;
    }
    _stompClient = StompClient(
      config: StompConfig(
        url: 'ws://localhost:8080/ws',
        stompConnectHeaders: {
          if (_userId != null) 'userId': _userId.toString(),
        },
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
      case 'settings_updated':
        _onSettingsUpdated(data);
        break;
      case 'vocabulary_status':
        _onVocabularyStatusUpdated(data);
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
    _loadInvitedUsers();
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
      _showSettingsPhase = false;
      _statusMessage = '再戦準備完了！';
    });
  }

  void _onSettingsUpdated(Map<String, dynamic> data) {
    setState(() {
      _room = data;
      _matchType = data['matchType'] ?? _matchType;
      _language = data['language'] ?? _language;
      _questionFormat = data['questionFormat'] ?? _questionFormat;
      _problemType = data['problemType'] ?? _problemType;
    });
  }

  void _onVocabularyStatusUpdated(Map<String, dynamic> data) {
    setState(() {
      _room = data;
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

  /// 設定選択フェーズへ移行（ホストが開始を押した時）
  void _showSettingsSelection() {
    setState(() {
      _showSettingsPhase = true;
    });
  }

  /// 設定を更新してサーバーに送信
  void _updateSettings() {
    if (_room == null || _stompClient == null) return;

    _stompClient!.send(
      destination: '/app/room/update-settings',
      body: jsonEncode({
        'roomId': _room!['roomId'],
        'userId': _userId,
        'matchType': _matchType,
        'language': _language,
        'questionFormat': _questionFormat,
        'problemType': _problemType,
      }),
    );
  }

  /// 対戦開始（設定確定後）
  void _startMatch() {
    if (_room == null || _stompClient == null) return;

    // まず設定を更新
    _updateSettings();

    // 少し待ってから開始
    Future.delayed(const Duration(milliseconds: 300), () {
      _stompClient?.send(
        destination: '/app/room/start',
        body: jsonEncode({
          'roomId': _room!['roomId'],
          'userId': _userId,
        }),
      );
    });
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
  bool get _isFinished => _room != null && _room!['status'] == 'FINISHED';
  bool get _hostInVocabulary => _room != null && (_room!['hostInVocabulary'] ?? false);
  bool get _guestInVocabulary => _room != null && (_room!['guestInVocabulary'] ?? false);
  bool get _anyoneInVocabulary => _hostInVocabulary || _guestInVocabulary;

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
            : _showSettingsPhase
                ? _buildSettingsPhase()
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
          // プレイヤー情報
          _buildPlayersInfo(),
          const SizedBox(height: 24),

          // 現在の設定表示（ホスト以外も見れる）
          _buildCurrentSettings(),
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

  /// 現在の設定表示
  Widget _buildCurrentSettings() {
    return Card(
      color: Colors.grey[100],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ルーム設定',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            _buildSettingRow('先取数', '$_matchType本'),
            _buildSettingRow('言語', _language == 'english' ? '英語' : '韓国語'),
            _buildSettingRow('問題形式', _getFormatLabel(_questionFormat)),
            _buildSettingRow('出題方法', _getModeLabel(_problemType)),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[700])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _getFormatLabel(String format) {
    switch (format) {
      case 'LISTENING_ONLY':
        return 'リスニングのみ';
      case 'FILL_IN_BLANK_ONLY':
        return '虫食いのみ';
      default:
        return 'すべてランダム';
    }
  }

  String _getModeLabel(String mode) {
    switch (mode) {
      case 'FAVORITE_ARTIST':
        return 'お気に入りアーティスト';
      case 'GENRE_RANDOM':
        return 'ジャンル指定';
      default:
        return '完全ランダム';
    }
  }

  /// 設定選択フェーズUI（quiz_selection_screen参考）
  Widget _buildSettingsPhase() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ヘッダー
          const Center(
            child: Text(
              '対戦設定',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 1. 先取数選択
          _buildSectionTitle('1. 先取数を選択'),
          _buildMatchTypeSelector(),
          const SizedBox(height: 24),

          // 2. 言語選択
          _buildSectionTitle('2. 言語を選択'),
          _buildLanguageSelector(),
          const SizedBox(height: 24),

          // 3. 問題形式
          _buildSectionTitle('3. 問題形式を選択'),
          _buildFormatSelector(),
          const SizedBox(height: 24),

          // 4. 出題方法
          _buildSectionTitle('4. 出題方法を選択'),
          _buildModeSelector(),
          const SizedBox(height: 32),

          // 確定ボタン
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _showSettingsPhase = false;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                  child: const Text('戻る'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _startMatch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                  child: const Text(
                    '対戦開始！',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.green,
        ),
      ),
    );
  }

  /// 先取数選択
  Widget _buildMatchTypeSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildOptionCard(
            title: '5本',
            subtitle: '先取5本勝負',
            icon: Icons.looks_5,
            isSelected: _matchType == 5,
            onTap: () => setState(() => _matchType = 5),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildOptionCard(
            title: '7本',
            subtitle: '先取7本勝負',
            icon: Icons.filter_7,
            isSelected: _matchType == 7,
            onTap: () => setState(() => _matchType = 7),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildOptionCard(
            title: '9本',
            subtitle: '先取9本勝負',
            icon: Icons.filter_9,
            isSelected: _matchType == 9,
            onTap: () => setState(() => _matchType = 9),
          ),
        ),
      ],
    );
  }

  /// 言語選択
  Widget _buildLanguageSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildOptionCard(
            title: '英語',
            subtitle: 'English',
            icon: Icons.language,
            isSelected: _language == 'english',
            onTap: () => setState(() => _language = 'english'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildOptionCard(
            title: '韓国語',
            subtitle: 'Korean',
            icon: Icons.language,
            isSelected: _language == 'korean',
            onTap: () => setState(() => _language = 'korean'),
          ),
        ),
      ],
    );
  }

  /// 問題形式選択
  Widget _buildFormatSelector() {
    return Column(
      children: [
        _buildOptionCard(
          title: 'すべてランダム',
          subtitle: 'リスニングと虫食いをランダムに出題',
          icon: Icons.shuffle,
          isSelected: _questionFormat == 'ALL_RANDOM',
          onTap: () => setState(() => _questionFormat = 'ALL_RANDOM'),
        ),
        const SizedBox(height: 12),
        _buildOptionCard(
          title: 'リスニングのみ',
          subtitle: '音声を聞いて回答',
          icon: Icons.headphones,
          isSelected: _questionFormat == 'LISTENING_ONLY',
          onTap: () => setState(() => _questionFormat = 'LISTENING_ONLY'),
        ),
        const SizedBox(height: 12),
        _buildOptionCard(
          title: '虫食いのみ',
          subtitle: '空欄を埋める問題',
          icon: Icons.edit,
          isSelected: _questionFormat == 'FILL_IN_BLANK_ONLY',
          onTap: () => setState(() => _questionFormat = 'FILL_IN_BLANK_ONLY'),
        ),
      ],
    );
  }

  /// 出題方法選択
  Widget _buildModeSelector() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildOptionCard(
                title: 'ランダム',
                subtitle: '完全ランダム',
                icon: Icons.shuffle,
                isSelected: _problemType == 'COMPLETE_RANDOM',
                onTap: () => setState(() => _problemType = 'COMPLETE_RANDOM'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildOptionCard(
                title: 'お気に入り',
                subtitle: 'アーティストから',
                icon: Icons.favorite,
                isSelected: _problemType == 'FAVORITE_ARTIST',
                onTap: () => setState(() => _problemType = 'FAVORITE_ARTIST'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// オプションカード
  Widget _buildOptionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.withOpacity(0.1) : Colors.white,
          border: Border.all(
            color: isSelected ? Colors.green : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.green : Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.green : Colors.black,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Colors.green,
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
        // ホストでゲストがいない場合：招待ボタン
        if (_isHost && !_hasGuest && !_anyoneInVocabulary)
          ElevatedButton.icon(
            onPressed: _showInviteFriendDialog,
            icon: const Icon(Icons.person_add),
            label: const Text('フレンドを招待'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
          ),

        // FINISHED状態でホストの場合：リセットボタン
        if (_isFinished && _isHost) ...[
          ElevatedButton.icon(
            onPressed: _resetRoom,
            icon: const Icon(Icons.refresh),
            label: const Text('再戦する'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // ゲストがいる場合：準備完了ボタン
        if (_hasGuest && !_isFinished) ...[
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

        // 開始可能（ホストでゲストが準備完了）：設定選択へ
        if (_canStart && !_isFinished)
          ElevatedButton.icon(
            onPressed: _showSettingsSelection,
            icon: const Icon(Icons.play_arrow),
            label: const Text('対戦設定へ'),
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

  /// ルームリセット
  Future<void> _resetRoom() async {
    if (_room == null) return;

    try {
      await _roomApiService.resetRoom(
        roomId: _room!['roomId'],
        hostId: _userId!,
        accessToken: _accessToken!,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('リセットエラー: $e')),
      );
    }
  }

  void _showInviteFriendDialog() {
    showDialog(
      context: context,
      builder: (context) => _FriendInviteDialog(
        userId: _userId!,
        roomId: _room!['roomId'],
        accessToken: _accessToken!,
        roomApiService: _roomApiService,
        onInviteSent: (friendId) {
          _loadInvitedUsers();
        },
      ),
    );
  }
}

/// フレンド招待ダイアログ
class _FriendInviteDialog extends StatefulWidget {
  final int userId;
  final int roomId;
  final String accessToken;
  final RoomApiService roomApiService;
  final Function(int friendId)? onInviteSent;

  const _FriendInviteDialog({
    required this.userId,
    required this.roomId,
    required this.accessToken,
    required this.roomApiService,
    this.onInviteSent,
  });

  @override
  State<_FriendInviteDialog> createState() => _FriendInviteDialogState();
}

class _FriendInviteDialogState extends State<_FriendInviteDialog> {
  List<Map<String, dynamic>> _friends = [];
  bool _isLoading = true;
  String? _errorMessage;
  Set<int> _invitingIds = {};

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    try {
      final friends = await widget.roomApiService.getFriends(
        userId: widget.userId,
        accessToken: widget.accessToken,
      );
      if (mounted) {
        setState(() {
          _friends = friends;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _inviteFriend(int friendUserId) async {
    if (_invitingIds.contains(friendUserId)) return;

    setState(() {
      _invitingIds.add(friendUserId);
    });

    try {
      final result = await widget.roomApiService.inviteFriend(
        roomId: widget.roomId,
        hostId: widget.userId,
        friendId: friendUserId,
        accessToken: widget.accessToken,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? '招待を送信しました'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onInviteSent?.call(friendUserId);
        await _loadFriends();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('招待エラー: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _invitingIds.remove(friendUserId);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('フレンドを招待'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(child: Text(_errorMessage!))
                : _friends.isEmpty
                    ? const Center(
                        child: Text(
                          '招待可能なフレンドがいません\n\nフレンドが全員バトル中か、\n既に招待済みの可能性があります',
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                        itemCount: _friends.length,
                        itemBuilder: (context, index) {
                          final friend = _friends[index];
                          final friendUserId = friend['userId'] as int;
                          final username = friend['username'] as String?;
                          final imageUrl = friend['imageUrl'] as String?;
                          final status = friend['status'] as String? ?? 'offline';
                          final canInvite = friend['canInvite'] as bool? ?? false;
                          final alreadyInvited = friend['alreadyInvited'] as bool? ?? false;
                          final isInviting = _invitingIds.contains(friendUserId);

                          // ステータスに応じた表示設定
                          final isOffline = status == 'offline';
                          final isInBattle = status == 'in_battle';
                          final isMatching = status == 'matching';

                          String statusLabel;
                          Color statusColor;
                          if (isOffline) {
                            statusLabel = 'オフライン';
                            statusColor = Colors.grey;
                          } else if (isMatching) {
                            statusLabel = 'マッチング中';
                            statusColor = Colors.purple;
                          } else if (isInBattle) {
                            statusLabel = 'バトル中';
                            statusColor = Colors.orange;
                          } else if (alreadyInvited) {
                            statusLabel = '招待済み';
                            statusColor = Colors.blue;
                          } else {
                            statusLabel = 'オンライン';
                            statusColor = Colors.green;
                          }

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isOffline ? Colors.grey[300] : null,
                              backgroundImage: imageUrl != null && !isOffline
                                  ? NetworkImage('http://localhost:8080/images/$imageUrl')
                                  : null,
                              child: imageUrl == null || isOffline
                                  ? Icon(Icons.person, color: isOffline ? Colors.grey[400] : null)
                                  : null,
                            ),
                            title: Text(
                              username ?? 'ユーザー',
                              style: TextStyle(
                                color: isOffline ? Colors.grey : Colors.black,
                              ),
                            ),
                            subtitle: Row(
                              children: [
                                // ステータスインジケーター
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: statusColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  statusLabel,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            // オフラインの場合は招待ボタンを表示しない
                            trailing: isOffline
                                ? null
                                : isInviting
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : canInvite
                                        ? ElevatedButton(
                                            onPressed: () => _inviteFriend(friendUserId),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.blue,
                                              foregroundColor: Colors.white,
                                            ),
                                            child: const Text('招待'),
                                          )
                                        : alreadyInvited
                                            ? Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue[50],
                                                  borderRadius: BorderRadius.circular(16),
                                                ),
                                                child: const Text(
                                                  '招待済み',
                                                  style: TextStyle(
                                                    color: Colors.blue,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              )
                                            : Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[100],
                                                  borderRadius: BorderRadius.circular(16),
                                                ),
                                                child: Text(
                                                  isInBattle ? 'バトル中' : '招待不可',
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                          );
                        },
                      ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('閉じる'),
        ),
      ],
    );
  }
}
