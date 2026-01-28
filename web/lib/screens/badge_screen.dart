import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../bottom_nav.dart'; // 必要に応じてパスを調整してください
import '../services/token_storage_service.dart';


// バッジデータのモデルクラス
class BadgeModel {
  final int badgeId;
  final String title;
  final String category;
  final String description;
  final IconData icon;
  final Color color;
  final double progress;
  final String rarity;
  final String? acquiredDate;

  BadgeModel({
    required this.badgeId,
    required this.title,
    required this.category,
    required this.description,
    required this.icon,
    required this.color,
    required this.progress,
    required this.rarity,
    this.acquiredDate,
  });

  // APIのJSONデータをモデルに変換
  factory BadgeModel.fromJson(Map<String, dynamic> json) {
    return BadgeModel(
      badgeId: json['badgeId'] ?? 0,
      title: json['title'] ?? '',
      category: json['category'] ?? 'スペシャル',
      description: json['description'] ?? '',
      // サーバーからの文字列キーをアイコン・色に変換
      icon: _getIconData(json['iconKey']),
      color: _getColor(json['colorCode']),
      progress: (json['progress'] ?? 0.0).toDouble(),
      rarity: json['rarity'] ?? 'common',
      acquiredDate: json['acquiredDate'],
    );
  }

  // 文字列 -> アイコン変換
  static IconData _getIconData(String? key) {
    switch (key) {
      case 'trending_up': return Icons.trending_up;
      case 'calendar_today': return Icons.calendar_today;
      case 'sports_esports': return Icons.sports_esports;
      case 'emoji_events': return Icons.emoji_events;
      case 'military_tech': return Icons.military_tech;
      case 'group': return Icons.group;
      case 'leaderboard': return Icons.leaderboard;
      case 'king_bed': return Icons.king_bed;
      case 'collections': return Icons.collections;
      case 'search': return Icons.search;
      case 'done_all': return Icons.done_all;
      case 'emoji_objects': return Icons.emoji_objects;
      case 'swap_horiz': return Icons.swap_horiz;
      case 'card_giftcard': return Icons.card_giftcard;
      case 'local_offer': return Icons.local_offer;
      case 'event': return Icons.event;
      case 'celebration': return Icons.celebration;
      case 'person_add': return Icons.person_add;
      case 'history': return Icons.history;
      case 'cake': return Icons.cake;
      case 'holiday_village': return Icons.holiday_village;
      case 'bug_report': return Icons.bug_report;
      case 'feedback': return Icons.feedback;
      case 'share': return Icons.share;
      case 'auto_awesome': return Icons.auto_awesome;
      default: return Icons.star; // デフォルトアイコン
    }
  }

  // 文字列 -> 色変換
  static Color _getColor(String? code) {
    switch (code) {
      case 'green': return Colors.green;
      case 'blue': return Colors.blue;
      case 'red': return Colors.red;
      case 'yellow': return Colors.yellow;
      case 'purple': return Colors.purple;
      case 'pink': return Colors.pink;
      case 'orange': return Colors.orange;
      case 'amber': return Colors.amber;
      case 'grey': return Colors.grey;
      default: return Colors.grey;
    }
  }
}

class BadgeScreen extends StatefulWidget {
  const BadgeScreen({Key? key}) : super(key: key);

  @override
  State<BadgeScreen> createState() => _BadgeScreenState();
}

class _BadgeScreenState extends State<BadgeScreen> {
  // 初期値は 'all'
  String selectedFilter = 'all';
  List<BadgeModel> badgeList = [];
  bool isLoading = true;

  // サーバーURL（環境に合わせて変更してください）
  final String _baseUrl = 'http://localhost:8080';
  final TokenStorageService _tokenStorage = TokenStorageService();
  int? _currentUserId;
  String? _authToken;

  @override
  void initState() {
    super.initState();
    _fetchBadges();
   
  }
  Future<void> _loadUserId() async {
  try {
    final userId = await _tokenStorage.getUserId();
    setState(() {
      _currentUserId = userId;
    });
  } catch (e) {
    debugPrint('Error loading userId: $e');
  }
}


  // APIからバッジ情報を取得
  Future<void> _fetchBadges() async {
    await _loadToken(); // トークンが必要な場合

    await _loadUserId();
    if (_currentUserId == null) {
    debugPrint('User ID is not available. Skip badge fetch.');
    setState(() { isLoading = false; });
    return;
  }
    try {
      // ★修正: 選択されたフィルター(mode)をクエリパラメータとして送信
      // バックエンドは mode=CONTINUE などを受け取ってDB検索を行う
      final uri = Uri.parse('$_baseUrl/api/v1/badges?userId=$_currentUserId&mode=$selectedFilter');
      debugPrint('📡 Fetching badges: $uri');

      final res = await http.get(uri, headers: _getHeaders());

      if (res.statusCode == 200) {
        final List<dynamic> body = json.decode(utf8.decode(res.bodyBytes));
        setState(() {
          badgeList = body.map((e) => BadgeModel.fromJson(e)).toList();
          isLoading = false;
        });
      } else {
        debugPrint('❌ Error fetching badges: ${res.statusCode}');
        setState(() { isLoading = false; });
      }
    } catch (e) {
      debugPrint('❌ Exception fetching badges: $e');
      setState(() { isLoading = false; });
    }
  }

  Future<void> _loadToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _authToken = prefs.getString('auth_token') ?? 
                     prefs.getString('token') ?? 
                     prefs.getString('access_token');
      });
    } catch (e) {
      debugPrint('Error loading token: $e');
    }
  }

  Map<String, String> _getHeaders() {
    final headers = {'Content-Type': 'application/json', 'Accept': 'application/json'};
    if (_authToken != null) headers['Authorization'] = 'Bearer $_authToken';
    return headers;
  }

  // ★修正: クライアント側でのフィルタリングは不要になったので削除
  // サーバーから返ってきたリストをそのまま使う
  List<BadgeModel> get currentBadges => badgeList;

  Color _getRarityColor(String rarity) {
    switch (rarity) {
      case 'common': return Colors.grey;
      case 'rare': return Colors.blue;
      case 'epic': return Colors.purple;
      case 'legendary': return Colors.orange;
      default: return Colors.grey;
    }
  }

  String _getRarityText(String rarity) {
    switch (rarity) {
      case 'common': return 'コモン';
      case 'rare': return 'レア';
      case 'epic': return 'エピック';
      case 'legendary': return 'レジェンド';
      default: return 'コモン';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // 表示中のリストに基づいてカウント
    final earnedCount = badgeList.where((badge) => badge.progress == 1.0).length;
    final totalCount = badgeList.length;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'バッジ',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildStatsCard(earnedCount, totalCount),
          _buildFilterSection(),
          _buildBadgeGrid(),
        ],
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: 0, onTap: (index) {}),
    );
  }

  Widget _buildStatsCard(int earnedCount, int totalCount) {
    final progress = totalCount == 0 ? 0.0 : earnedCount / totalCount;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade100, Colors.purple.shade100],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'バッジコレクション',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$earnedCount/$totalCount 獲得',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[300],
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                  borderRadius: BorderRadius.circular(10),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.emoji_events, color: Colors.amber, size: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'カテゴリーでフィルター',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButton<String>(
              value: selectedFilter,
              isExpanded: true,
              underline: const SizedBox(),
              borderRadius: BorderRadius.circular(8),
              style: const TextStyle(color: Colors.black87, fontSize: 14),
              // ★修正: Dropdownのvalueを、バックエンドが期待するモード文字列に合わせる
              items: const [
                DropdownMenuItem(value: 'all', child: Text('すべてのカテゴリー')),
                DropdownMenuItem(value: 'CONTINUE', child: Text('継続者')),
                DropdownMenuItem(value: 'BATTLE', child: Text('バトラー')),
                DropdownMenuItem(value: 'RANKING', child: Text('ランカー')),
                DropdownMenuItem(value: 'COLLECT', child: Text('獲得大王')),
                DropdownMenuItem(value: 'SPECIAL', child: Text('スペシャル')),
              ],
              onChanged: (String? value) {
                if (value != null) {
                  setState(() {
                    selectedFilter = value;
                    isLoading = true; // ロード中表示
                  });
                  // フィルター変更時にAPIを再取得
                  _fetchBadges();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeGrid() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: badgeList.isEmpty
            ? const Center(child: Text("バッジがありません"))
            : GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.9,
                ),
                // ★修正: filteredBadgesではなくbadgeListをそのまま使用
                itemCount: badgeList.length,
                itemBuilder: (context, index) {
                  final badge = badgeList[index];
                  return _buildBadgeCircle(badge);
                },
              ),
      ),
    );
  }

  Widget _buildBadgeCircle(BadgeModel badge) {
    final isEarned = badge.progress == 1.0;
    final isInProgress = badge.progress > 0.0 && badge.progress < 1.0;

    return GestureDetector(
      onTap: () => _showBadgeDetails(badge),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: isEarned ? badge.color.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isEarned ? badge.color : Colors.grey[300]!,
                    width: 2,
                  ),
                  boxShadow: isEarned
                      ? [BoxShadow(color: badge.color.withOpacity(0.3), blurRadius: 8, spreadRadius: 1)]
                      : null,
                ),
                child: Icon(
                  badge.icon,
                  color: isEarned ? badge.color : Colors.grey,
                  size: 30,
                ),
              ),
              if (isInProgress)
                const Positioned(
                  bottom: 0, right: 0,
                  child: Icon(Icons.autorenew, color: Colors.blue, size: 20),
                ),
              if (isEarned)
                Positioned(
                  top: 0, right: 0,
                  child: Container(
                    width: 20, height: 20,
                    decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                    child: const Icon(Icons.check, color: Colors.white, size: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            badge.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isEarned ? Colors.black87 : Colors.grey,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _showBadgeDetails(BadgeModel badge) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: badge.color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(badge.icon, color: badge.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      badge.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getRarityColor(badge.rarity).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _getRarityColor(badge.rarity), width: 1),
                      ),
                      child: Text(
                        _getRarityText(badge.rarity),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _getRarityColor(badge.rarity),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(badge.description, style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 16),
              if (badge.progress == 1.0 && badge.acquiredDate != null)
                Text(
                  '獲得日: ${badge.acquiredDate}',
                  style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold),
                ),
              if (badge.progress > 0.0 && badge.progress < 1.0) ...[
                LinearProgressIndicator(
                  value: badge.progress,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(badge.color),
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(badge.progress * 100).toInt()}% 達成',
                  style: TextStyle(fontSize: 12, color: badge.color, fontWeight: FontWeight.bold),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('閉じる'),
            ),
          ],
        );
      },
    );
  }
}