import 'dart:async';
import 'package:flutter/material.dart';
import '../services/life_api_service.dart';
import '../services/token_storage_service.dart';
import '../services/room_invitation_service.dart';

/// バトルモード選択画面
/// Ranked MatchとRoom Matchを選択します
class BattleModeSelectionScreen extends StatefulWidget {
  const BattleModeSelectionScreen({Key? key}) : super(key: key);

  @override
  State<BattleModeSelectionScreen> createState() => _BattleModeSelectionScreenState();
}

class _BattleModeSelectionScreenState extends State<BattleModeSelectionScreen> {
  final _lifeApiService = LifeApiService();
  final _tokenStorage = TokenStorageService();
  final _invitationService = RoomInvitationService();

  LifeStatus? _lifeStatus;
  bool _isLoading = true;
  int _invitationCount = 0;
  StreamSubscription<int>? _countSubscription;
  StreamSubscription<RoomInvitationEvent>? _eventSubscription;

  @override
  void initState() {
    super.initState();
    _fetchLifeStatus();
    _initInvitationService();
  }

  Future<void> _initInvitationService() async {
    await _invitationService.connect();

    // 招待数の更新を購読
    _countSubscription = _invitationService.countStream.listen((count) {
      if (mounted) {
        setState(() {
          _invitationCount = count;
        });
      }
    });

    // リアルタイム招待通知を購読
    _eventSubscription = _invitationService.eventStream.listen((event) {
      if (event.type == RoomInvitationEventType.received && mounted) {
        _showInvitationSnackBar(event.data);
      }
    });

    // 初期値を設定
    if (mounted) {
      setState(() {
        _invitationCount = _invitationService.invitationCount;
      });
    }
  }

  void _showInvitationSnackBar(Map<String, dynamic> data) {
    final inviterName = data['inviter']?['username'] ?? '誰か';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$inviterName さんから招待が届きました'),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: '確認',
          textColor: Colors.white,
          onPressed: () {
            Navigator.pushNamed(context, '/room-invitations');
          },
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  void dispose() {
    _countSubscription?.cancel();
    _eventSubscription?.cancel();
    super.dispose();
  }

  Future<void> _fetchLifeStatus() async {
    try {
      final userId = await _tokenStorage.getUserId();
      final accessToken = await _tokenStorage.getAccessToken();

      if (userId != null && accessToken != null) {
        final lifeStatus = await _lifeApiService.getLifeStatus(
          userId: userId,
          accessToken: accessToken,
        );
        if (mounted) {
          setState(() {
            _lifeStatus = lifeStatus;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('ライフ状態取得エラー: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatRecoveryTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _showInsufficientLifeDialog() {
    final nextRecovery = _lifeStatus?.nextRecoveryInSeconds ?? 600;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ライフが不足しています'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.music_off,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'ランクマッチにはライフが必要です',
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(
              '次の回復まで: ${_formatRecoveryTime(nextRecovery)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 600;
    final padding = isWideScreen ? 48.0 : 24.0;
    final maxWidth = isWideScreen ? 600.0 : double.infinity;

    final hasLife = _lifeStatus != null && _lifeStatus!.currentLife > 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Battle Mode'),
        centerTitle: true,
        actions: [
          // 招待ボタン（バッジ付き）
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.mail_outline),
                tooltip: '受信した招待',
                onPressed: () {
                  Navigator.pushNamed(context, '/room-invitations');
                },
              ),
              if (_invitationCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      _invitationCount > 9 ? '9+' : '$_invitationCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(padding),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ライフ表示
                if (!_isLoading && _lifeStatus != null)
                  _buildLifeDisplay(),
                const SizedBox(height: 24),

                // タイトル
                const Text(
                  'バトルモードを選択',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '対戦モードを選んでください',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // Ranked Matchボタン
                _buildModeCard(
                  context: context,
                  title: 'Ranked Match',
                  description: 'レーティングをかけて戦う',
                  icon: Icons.emoji_events,
                  color: Colors.amber,
                  isAvailable: hasLife || _isLoading,
                  isLifeInsufficient: !_isLoading && !hasLife,
                  onTap: () {
                    if (!hasLife && !_isLoading) {
                      _showInsufficientLifeDialog();
                    } else {
                      Navigator.pushNamed(context, '/language-selection');
                    }
                  },
                ),
                const SizedBox(height: 24),

                // Room Matchボタン
                _buildModeCard(
                  context: context,
                  title: 'Room Match',
                  description: 'フレンドとプライベート対戦',
                  icon: Icons.people,
                  color: Colors.green,
                  isAvailable: true,
                  isLifeInsufficient: false,
                  onTap: () {
                    Navigator.pushNamed(context, '/room-match');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// ライフ表示ウィジェット
  Widget _buildLifeDisplay() {
    final currentLife = _lifeStatus!.currentLife;
    final maxLife = _lifeStatus!.maxLife;
    final nextRecovery = _lifeStatus!.nextRecoveryInSeconds;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'ライフ: ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ...List.generate(maxLife, (index) {
                final isFilled = index < currentLife;
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(
                    Icons.music_note,
                    color: isFilled ? Colors.blue[600] : Colors.grey[300],
                    size: 24,
                  ),
                );
              }),
            ],
          ),
          if (currentLife < maxLife) ...[
            const SizedBox(height: 8),
            Text(
              '次の回復まで: ${_formatRecoveryTime(nextRecovery)}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// モード選択カードを構築
  Widget _buildModeCard({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required bool isAvailable,
    required bool isLifeInsufficient,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // アイコン
              Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    icon,
                    size: 80,
                    color: isAvailable ? color : Colors.grey,
                  ),
                  if (!isAvailable && !isLifeInsufficient)
                    const Icon(
                      Icons.lock,
                      size: 40,
                      color: Colors.white,
                    ),
                  if (isLifeInsufficient)
                    const Icon(
                      Icons.music_off,
                      size: 40,
                      color: Colors.white,
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // タイトル
              Text(
                title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isAvailable ? Colors.black : Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // 説明
              Text(
                description,
                style: TextStyle(
                  fontSize: 16,
                  color: isAvailable ? Colors.grey[700] : Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),

              // ステータス
              if (!isAvailable && !isLifeInsufficient) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '準備中',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ),
              ],
              if (isLifeInsufficient) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'ライフ不足',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
