import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../bottom_nav.dart';
import '../services/token_storage_service.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({Key? key}) : super(key: key);

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ★修正: 固定リストを廃止し、サーバーから取得するように変更
  String _selectedSeason = '';
  List<String> _seasons = [];

  // シーズンの開催ステータス
  final Map<String, bool> _seasonStatus = {};

  Timer? _updateTimer;
  DateTime? _lastUpdateTime;
  DateTime? _weekStartDate;

  bool _showFriendsOnly = false;
  bool _showFriendsOnlyWeekly = false;

  final Map<String, List<Map<String, dynamic>>> _rankings = {};
  List<Map<String, dynamic>> _weeklyRankings = [];

  // サーバーのURL（環境に合わせて変更してください）
  final String _baseUrl = 'http://localhost:8080';
  final TokenStorageService _tokenStorage = TokenStorageService();
  int? _currentUserId;

  String? _authToken;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeData();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    await _loadToken();
    await _loadUserId();

    if (_currentUserId == null) {
      debugPrint('User ID is not available. Skip ranking fetch.');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    // 1. まずシーズン一覧を取得 (DBに存在するシーズンを確認)
    await _fetchSeasons();

    // 2. 次に週間ランキングを取得
    await _fetchWeeklyRanking();

    final now = DateTime.now();
    _weekStartDate = now.subtract(Duration(days: now.weekday % 7));

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }

    _startRealtimeUpdate();

    // ★追加: ランキング画面を開いたのでバッジ判定をリクエスト
    _requestBadgeCheck();
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

  Future<void> _loadToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      setState(() {
        _authToken = token;
      });

      if (token == null) {
        final alternativeToken = prefs.getString('token') ??
            prefs.getString('access_token') ??
            prefs.getString('jwt_token');
        if (alternativeToken != null) {
          setState(() {
            _authToken = alternativeToken;
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading token: $e');
    }
  }

  Map<String, String> _getHeaders() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (_authToken != null && _authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_authToken';
    }

    return headers;
  }

  // ★追加: DBに存在するシーズン一覧を取得するメソッド
  Future<void> _fetchSeasons() async {
    try {
      final uri = Uri.parse('$_baseUrl/api/v1/rankings/seasons');
      debugPrint('📡 [Seasons] Fetching: $uri');

      final res = await http.get(uri, headers: _getHeaders());

      if (res.statusCode == 200) {
        // 文字化け対策のため utf8.decode を使用
        final List<dynamic> seasonList =
            json.decode(utf8.decode(res.bodyBytes));
        final List<String> fetchedSeasons = seasonList.cast<String>();

        debugPrint('✅ [Seasons] 取得成功: $fetchedSeasons');

        if (fetchedSeasons.isNotEmpty && mounted) {
          setState(() {
            _seasons = fetchedSeasons;

            // 現在選択中のシーズンが新しいリストに無ければ、最新（最後）を選択
            if (!_seasons.contains(_selectedSeason)) {
              _selectedSeason = _seasons.last;
            }

            // 最新のシーズンだけを「開催中」にする（簡易ロジック）
            _seasonStatus.clear();
            for (var s in _seasons) {
              _seasonStatus[s] = (s == _seasons.last);
            }
          });

          // シーズンが確定したら、そのランキングデータを取得
          await _fetchSeasonRanking(_selectedSeason);
        }
      } else {
        debugPrint('❌ [Seasons] Error ${res.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Seasons] Exception: $e');
      // エラー時のフォールバック
      if (mounted && _seasons.isEmpty) {
        setState(() {
          _seasons = ['シーズン3'];
          _selectedSeason = 'シーズン3';
          _seasonStatus['シーズン3'] = true;
        });
        await _fetchSeasonRanking(_selectedSeason);
      }
    }
  }

  Future<void> _fetchSeasonRanking(String season) async {
    if (season.isEmpty) return; // シーズン未定なら何もしない
    if (_currentUserId == null) return;
    try {
      final queryParams = {
        'season': season,
        'limit': '50',
        'userId': _currentUserId!.toString(),
        'friendsOnly': 'false',
      };

      final uri = Uri.parse('$_baseUrl/api/v1/rankings/season')
          .replace(queryParameters: queryParams);

      debugPrint('📡 [Season] Fetching: $uri');

      final res = await http
          .get(
            uri,
            headers: _getHeaders(),
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final Map<String, dynamic> body =
            json.decode(utf8.decode(res.bodyBytes)); // 文字化け対策
        final List<dynamic> entries = body['entries'] ?? [];
        final bool isActive =
            body['isActive'] ?? _seasonStatus[season] ?? false;
        final lastUpdatedRaw = body['lastUpdated'];
        DateTime? parsedUpdated;
        if (lastUpdatedRaw != null && lastUpdatedRaw is String) {
          try {
            parsedUpdated = DateTime.parse(lastUpdatedRaw);
          } catch (e) {
            parsedUpdated = null;
          }
        }

        final List<Map<String, dynamic>> list = [];
        for (var e in entries) {
          list.add({
            'rank': e['rank'] ?? (list.length + 1),
            'name': e['name'] ?? '',
            'rate': e['rate'] ?? 0,
            'isFriend': e['isFriend'] ?? false,
            'isMe': e['isMe'] ?? false,
          });
        }

        if (mounted) {
          setState(() {
            _rankings[season] = list;
            _seasonStatus[season] = isActive;
            _lastUpdateTime = parsedUpdated;
          });
        }
      } else {
        debugPrint('❌ [Season] Error ${res.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Season] Exception: $e');
    }
  }

  Future<void> _fetchWeeklyRanking({DateTime? weekStart}) async {
    
    try {
      if (_currentUserId == null) return;
      final params = <String, String>{
        'limit': '50',
        'userId': _currentUserId!.toString(),
        'friendsOnly': 'false'
      };
      // ※バックエンドの仕様変更により weekStart は無視されますが、送信しても問題ありません
      if (weekStart != null) {
        params['weekStart'] =
            '${weekStart.year.toString().padLeft(4, '0')}-${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}';
      }
      final uri = Uri.parse('$_baseUrl/api/v1/rankings/weekly')
          .replace(queryParameters: params);

      debugPrint('📡 [Weekly] Fetching: $uri');

      final res = await http
          .get(
            uri,
            headers: _getHeaders(),
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final Map<String, dynamic> body =
            json.decode(utf8.decode(res.bodyBytes));
        final List<dynamic> entries = body['entries'] ?? [];
        final List<Map<String, dynamic>> list = [];
        for (var e in entries) {
          list.add({
            'rank': e['rank'] ?? (list.length + 1),
            'name': e['name'] ?? '',
            'count': e['rate'] ?? e['count'] ?? 0,
            'isFriend': e['isFriend'] ?? false,
            'isMe': e['isMe'] ?? false,
          });
        }

        if (mounted) {
          setState(() {
            _weeklyRankings = list;
          });
        }
      }
    } catch (e) {
      debugPrint('❌ [Weekly] Exception: $e');
    }
  }

  // ★追加: バッジ判定リクエスト
  Future<void> _requestBadgeCheck() async {
    try {
      final uri = Uri.parse('$_baseUrl/api/v1/rankings/access?userId=$_currentUserId');
      await http.get(
        uri,
        headers: _getHeaders(),
      );
    } catch (e) {
      debugPrint('❌ バッジ判定リクエストエラー: $e');
    }
  }

  void _startRealtimeUpdate() {
    _updateTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      // 選択中のシーズンがあり、かつそれがアクティブ（開催中）なら更新
      if (_selectedSeason.isNotEmpty &&
          (_seasonStatus[_selectedSeason] ?? false)) {
        await _fetchSeasonRanking(_selectedSeason);
        if (mounted) {
          setState(() {
            _lastUpdateTime = DateTime.now();
          });
        }
      }
    });
  }

  String get _currentUserName {
    return 'Kanata';
  }

  String _formatUpdateTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}秒前';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分前';
    } else {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

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
          'ランキング',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          indicatorColor: Colors.amber[700],
          tabs: const [
            Tab(text: 'レートランキング'),
            Tab(text: '学習週間ランキング'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRateRanking(),
          _buildWeeklyRanking(),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 0,
        onTap: (index) {},
      ),
    );
  }

  Widget _buildRateRanking() {
    final List<Map<String, dynamic>> rankings =
        List.from(_rankings[_selectedSeason] ?? []);
    rankings.sort((a, b) => (b['rate'] as int).compareTo(a['rate'] as int));

    List<Map<String, dynamic>> displayRankings = rankings;
    if (_showFriendsOnly) {
      displayRankings = rankings
          .where((r) => (r['isFriend'] == true) || (r['isMe'] == true))
          .toList();
    }

    final myRankIndex = displayRankings.indexWhere((r) => r['isMe'] == true);
    final myRank = myRankIndex >= 0 ? myRankIndex + 1 : -1;
    final isSeasonActive = _seasonStatus[_selectedSeason] ?? false;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color:
                          isSeasonActive ? Colors.green[100] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSeasonActive
                              ? Icons.fiber_manual_record
                              : Icons.stop_circle,
                          size: 12,
                          color: isSeasonActive
                              ? Colors.green[700]
                              : Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isSeasonActive ? '開催中' : '終了',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSeasonActive
                                ? Colors.green[700]
                                : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // ★修正: 「シーズン:」のテキストを削除し、動的なプルダウンを配置
                  _seasons.isEmpty
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : DropdownButton<String>(
                          value: _selectedSeason.isNotEmpty
                              ? _selectedSeason
                              : null,
                          items: _seasons.map((season) {
                            return DropdownMenuItem<String>(
                              value: season,
                              child: Text(season),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedSeason = value!;
                              _fetchSeasonRanking(_selectedSeason);
                            });
                          },
                        ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.people, size: 20, color: Colors.grey[700]),
                      const SizedBox(width: 8),
                      const Text('フレンドのみ', style: TextStyle(fontSize: 14)),
                      Switch(
                        value: _showFriendsOnly,
                        onChanged: (value) {
                          setState(() {
                            _showFriendsOnly = value;
                          });
                        },
                        activeColor: Colors.amber[700],
                      ),
                    ],
                  ),
                  if (isSeasonActive && _lastUpdateTime != null)
                    Row(
                      children: [
                        Icon(Icons.access_time,
                            size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          _formatUpdateTime(_lastUpdateTime!),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: displayRankings.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline,
                          size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'データがありません',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount:
                      displayRankings.length > 30 ? 30 : displayRankings.length,
                  itemBuilder: (context, index) {
                    final item = displayRankings[index];
                    final isMe = item['isMe'] == true;
                    final isFriend = item['isFriend'] == true;

                    return Container(
                      color: isMe ? Colors.amber[100] : null,
                      child: ListTile(
                        leading: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 40,
                              alignment: Alignment.center,
                              child: Text(
                                '#${item['rank'] ?? index + 1}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: index == 0
                                      ? Colors.amber[700]
                                      : index == 1
                                          ? Colors.grey[600]
                                          : index == 2
                                              ? Colors.brown[400]
                                              : Colors.black,
                                ),
                              ),
                            ),
                            if ((item['rank'] ?? index + 1) <= 3)
                              Icon(
                                Icons.emoji_events,
                                size: 20,
                                color: (item['rank'] ?? index + 1) == 1
                                    ? Colors.amber[700]
                                    : (item['rank'] ?? index + 1) == 2
                                        ? Colors.grey[600]
                                        : Colors.brown[400],
                              ),
                            if (isMe) ...[
                              const SizedBox(width: 4),
                              Icon(Icons.person,
                                  size: 16, color: Colors.amber[700]),
                            ],
                            if (isFriend && !isMe) ...[
                              const SizedBox(width: 4),
                              Icon(Icons.people,
                                  size: 16, color: Colors.green[600]),
                            ],
                          ],
                        ),
                        title: Text(
                          item['name'] ?? '',
                          style: TextStyle(
                            fontWeight:
                                isMe ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        trailing: Text(
                          '${item['rate'] ?? 0}',
                          style: TextStyle(
                            fontWeight:
                                isMe ? FontWeight.bold : FontWeight.normal,
                            color: isMe ? Colors.amber[700] : Colors.black,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
        if (myRank > 30)
          Container(
            color: Colors.amber[100],
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    alignment: Alignment.center,
                    child: Text(
                      '#$myRank',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  Icon(Icons.person, size: 16, color: Colors.amber[700]),
                ],
              ),
              title: Text(
                _currentUserName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              trailing: Text(
                '${displayRankings[myRankIndex]['rate']}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.amber[700],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildWeeklyRanking() {
    final List<Map<String, dynamic>> rankings = List.from(_weeklyRankings);
    rankings.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

    List<Map<String, dynamic>> displayRankings = rankings;
    if (_showFriendsOnlyWeekly) {
      displayRankings = rankings
          .where((r) => (r['isFriend'] == true) || (r['isMe'] == true))
          .toList();
    }

    final myRankIndex = displayRankings.indexWhere((r) => r['isMe'] == true);
    final myRank = myRankIndex >= 0 ? myRankIndex + 1 : -1;

    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday % 7));
    final weekEnd = weekStart.add(const Duration(days: 6));

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            border: Border(
              bottom: BorderSide(color: Colors.blue[100]!, width: 1),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calendar_today, size: 18, color: Colors.blue[700]),
              const SizedBox(width: 8),
              Text(
                '${weekStart.month}/${weekStart.day}(日) 〜 ${weekEnd.month}/${weekEnd.day}(土)',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[900],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(Icons.people, size: 20, color: Colors.grey[700]),
              const SizedBox(width: 8),
              const Text('フレンドのみ', style: TextStyle(fontSize: 14)),
              Switch(
                value: _showFriendsOnlyWeekly,
                onChanged: (value) {
                  setState(() {
                    _showFriendsOnlyWeekly = value;
                  });
                },
                activeColor: Colors.blue[700],
              ),
            ],
          ),
        ),
        Expanded(
          child: displayRankings.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline,
                          size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'データがありません',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount:
                      displayRankings.length > 30 ? 30 : displayRankings.length,
                  itemBuilder: (context, index) {
                    final item = displayRankings[index];
                    final isMe = item['isMe'] == true;
                    final isFriend = item['isFriend'] == true;

                    return Container(
                      color: isMe ? Colors.blue[50] : null,
                      child: ListTile(
                        leading: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 40,
                              alignment: Alignment.center,
                              child: Text(
                                '#${item['rank'] ?? index + 1}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: index == 0
                                      ? Colors.amber[700]
                                      : index == 1
                                          ? Colors.grey[600]
                                          : index == 2
                                              ? Colors.brown[400]
                                              : Colors.black,
                                ),
                              ),
                            ),
                            if ((item['rank'] ?? index + 1) <= 3)
                              Icon(
                                Icons.emoji_events,
                                size: 20,
                                color: (item['rank'] ?? index + 1) == 1
                                    ? Colors.amber[700]
                                    : (item['rank'] ?? index + 1) == 2
                                        ? Colors.grey[600]
                                        : Colors.brown[400],
                              ),
                            if (isMe) ...[
                              const SizedBox(width: 4),
                              Icon(Icons.person,
                                  size: 16, color: Colors.amber[700]),
                            ],
                            if (isFriend && !isMe) ...[
                              const SizedBox(width: 4),
                              Icon(Icons.people,
                                  size: 16, color: Colors.green[600]),
                            ],
                          ],
                        ),
                        title: Row(
                          children: [
                            Text(
                              item['name'] ?? '',
                              style: TextStyle(
                                fontWeight:
                                    isMe ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            if (isMe) ...[
                              const SizedBox(width: 8),
                              Icon(Icons.person,
                                  size: 16, color: Colors.blue[700]),
                            ],
                            if (isFriend && !isMe) ...[
                              const SizedBox(width: 8),
                              Icon(Icons.people,
                                  size: 16, color: Colors.green[600]),
                            ],
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${item['count'] ?? 0}回',
                              style: TextStyle(
                                fontWeight:
                                    isMe ? FontWeight.bold : FontWeight.w600,
                                fontSize: 16,
                                color: isMe ? Colors.blue[700] : Colors.black87,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '(今週)',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        if (myRank > 30)
          Container(
            color: Colors.blue[50],
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    alignment: Alignment.center,
                    child: Text(
                      '#$myRank',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  Icon(Icons.person, size: 16, color: Colors.blue[700]),
                ],
              ),
              title: Text(
                _currentUserName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${displayRankings[myRankIndex]['count'] ?? 0}回',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.blue[700],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '(今週)',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
