import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../bottom_nav.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({Key? key}) : super(key: key);

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedSeason = 'シーズン3';
  final List<String> _seasons = ['シーズン1', 'シーズン2', 'シーズン3'];
  
  // シーズンのステータス（true=開催中、false=終了）
  final Map<String, bool> _seasonStatus = {
    'シーズン1': false, // 終了
    'シーズン2': false, // 終了
    'シーズン3': true,  // 開催中
  };

  Timer? _updateTimer;
  final Random _random = Random();
  DateTime? _lastUpdateTime;
  DateTime? _weekStartDate; // 週の開始日を記録
  
  // フレンドフィルター
  bool _showFriendsOnly = false;
  bool _showFriendsOnlyWeekly = false;
  
  // フレンドリスト（実際のアプリではバックエンドから取得）
  final Set<String> _friendsList = {
    'User2', 'User5', 'User8', 'User12', 'User15', 'User20', 'User25', 'User30'
  };

  // ログインユーザー名を取得する関数（実際のアプリでは認証情報から取得）
  String get _currentUserName {
    // TODO: 実際の実装では、認証サービスやSharedPreferencesから取得
    // 例: FirebaseAuth.instance.currentUser?.displayName ?? 'Guest';
    return 'Kanata'; // 仮の実装
  }

  // サンプルデータ：ランキング（名前とスコア）
  Map<String, List<Map<String, dynamic>>> _rankings = {};
  
  // 学習週間ランキングデータ（名前と学習回数）
  List<Map<String, dynamic>> _weeklyRankings = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeRankings();
    _startRealtimeUpdate();
  }

  void _initializeRankings() {
    _rankings = {
      'シーズン1': List.generate(50, (i) => {
        'name': 'User${i + 1}',
        'score': 1500 - i * 10,
      })..[1] = {'name': _currentUserName, 'score': 1450},
      
      'シーズン2': List.generate(50, (i) => {
        'name': 'User${i + 1}',
        'score': 1600 - i * 12,
      })..[5] = {'name': _currentUserName, 'score': 1540},
      
      'シーズン3': List.generate(50, (i) => {
        'name': 'User${i + 1}',
        'score': 1400 - i * 8,
      })..[2] = {'name': _currentUserName, 'score': 1384},
    };
    
    // 今週の開始日を設定
    final now = DateTime.now();
    _weekStartDate = now.subtract(Duration(days: now.weekday % 7));
    
    // 学習週間ランキングの初期化（今週のデータ）
    _initializeWeeklyRankings();
    
    // 開催中のシーズンの初期更新時刻を設定
    if (_seasonStatus[_selectedSeason] == true) {
      _lastUpdateTime = DateTime.now();
    }
  }
  
  void _initializeWeeklyRankings() {
    // 週の学習回数をランダムに初期化（0〜現在の曜日×20回程度）
    final now = DateTime.now();
    final daysSinceStart = now.weekday % 7; // 0(日曜)〜6(土曜)
    final maxCount = (daysSinceStart + 1) * 20; // 日曜は20、月曜は40...
    
    _weeklyRankings = List.generate(50, (i) {
      final baseCount = maxCount - i * 2;
      return {
        'name': 'User${i + 1}',
        'count': baseCount > 0 ? baseCount : _random.nextInt(10),
      };
    })..[3] = {
      'name': _currentUserName, 
      'count': maxCount > 30 ? maxCount - 15 : _random.nextInt(maxCount > 0 ? maxCount : 10)
    };
  }

  void _startRealtimeUpdate() {
    // 開催中のシーズンのみ3秒ごとに更新
    _updateTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      // 週が変わったかチェック
      _checkAndResetWeeklyRankings();
      
      if (_seasonStatus[_selectedSeason] == true) {
        setState(() {
          _updateScores(_selectedSeason);
          _lastUpdateTime = DateTime.now();
        });
      }
    });
  }
  
  void _checkAndResetWeeklyRankings() {
    final now = DateTime.now();
    final currentWeekStart = now.subtract(Duration(days: now.weekday % 7));
    
    // 週が変わった場合（日曜日になった場合）
    if (_weekStartDate != null && 
        currentWeekStart.isAfter(_weekStartDate!.add(const Duration(days: 6)))) {
      setState(() {
        _weekStartDate = currentWeekStart;
        _initializeWeeklyRankings();
      });
    }
  }

  void _updateScores(String season) {
    if (_rankings[season] == null) return;
    
    // レートランキング: ランダムに数人のスコアを変動させる
    final rankings = _rankings[season]!;
    final numUpdates = _random.nextInt(5) + 2; // 2〜6人のスコアを更新
    
    for (int i = 0; i < numUpdates; i++) {
      final index = _random.nextInt(rankings.length);
      final change = _random.nextInt(21) - 10; // -10 〜 +10の変動
      rankings[index]['score'] = (rankings[index]['score'] as int) + change;
    }
    
    // 学習週間ランキング: ランダムに学習回数を増やす
    final weeklyUpdates = _random.nextInt(3) + 1; // 1〜3人の学習回数を更新
    for (int i = 0; i < weeklyUpdates; i++) {
      final index = _random.nextInt(_weeklyRankings.length);
      final increase = _random.nextInt(3) + 1; // +1 〜 +3回増加
      _weeklyRankings[index]['count'] = (_weeklyRankings[index]['count'] as int) + increase;
    }
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _tabController.dispose();
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
    List<Map<String, dynamic>> rankings = List.from(_rankings[_selectedSeason] ?? []);
    rankings.sort((a, b) => b['score'].compareTo(a['score']));
    
    // フレンドフィルター適用
    List<Map<String, dynamic>> displayRankings = rankings;
    if (_showFriendsOnly) {
      displayRankings = rankings.where((r) => 
        _friendsList.contains(r['name']) || r['name'] == _currentUserName
      ).toList();
    }

    final myRankIndex = displayRankings.indexWhere((r) => r['name'] == _currentUserName);
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
                  // ステータス表示
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSeasonActive ? Colors.green[100] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSeasonActive ? Icons.fiber_manual_record : Icons.stop_circle,
                          size: 12,
                          color: isSeasonActive ? Colors.green[700] : Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isSeasonActive ? '開催中' : '終了',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSeasonActive ? Colors.green[700] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // シーズン選択
                  Row(
                    children: [
                      const Text('シーズン: ', style: TextStyle(fontSize: 16)),
                      DropdownButton<String>(
                        value: _selectedSeason,
                        items: _seasons.map((season) {
                          return DropdownMenuItem<String>(
                            value: season,
                            child: Text(season),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedSeason = value!;
                            // シーズン変更時に開催中なら更新時刻を設定
                            if (_seasonStatus[_selectedSeason] == true) {
                              _lastUpdateTime = DateTime.now();
                            } else {
                              _lastUpdateTime = null;
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // フレンドフィルター
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
                  // 更新日時表示（開催中のみ）
                  if (isSeasonActive && _lastUpdateTime != null)
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${_formatUpdateTime(_lastUpdateTime!)}',
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
                      Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'フレンドがいません',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: displayRankings.length > 30 ? 30 : displayRankings.length,
                  itemBuilder: (context, index) {
                    final item = displayRankings[index];
                    final isMe = item['name'] == _currentUserName;
                    final isFriend = _friendsList.contains(item['name']);
                    
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
                                '#${index + 1}',
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
                            if (index < 3)
                              Icon(
                                Icons.emoji_events,
                                size: 20,
                                color: index == 0 
                                    ? Colors.amber[700]
                                    : index == 1
                                        ? Colors.grey[600]
                                        : Colors.brown[400],
                              ),
                            if (isMe) ...[
                              const SizedBox(width: 4),
                              Icon(Icons.person, size: 16, color: Colors.amber[700]),
                            ],
                            if (isFriend && !isMe) ...[
                              const SizedBox(width: 4),
                              Icon(Icons.people, size: 16, color: Colors.green[600]),
                            ],
                          ],
                        ),
                        title: Text(
                          item['name'],
                          style: TextStyle(
                            fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        trailing: Text(
                          '${item['score']}',
                          style: TextStyle(
                            fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
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
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                '${displayRankings[myRankIndex]['score']}',
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
    List<Map<String, dynamic>> rankings = List.from(_weeklyRankings);
    rankings.sort((a, b) => b['count'].compareTo(a['count']));
    
    // フレンドフィルター適用
    List<Map<String, dynamic>> displayRankings = rankings;
    if (_showFriendsOnlyWeekly) {
      displayRankings = rankings.where((r) => 
        _friendsList.contains(r['name']) || r['name'] == _currentUserName
      ).toList();
    }

    final myRankIndex = displayRankings.indexWhere((r) => r['name'] == _currentUserName);
    final myRank = myRankIndex >= 0 ? myRankIndex + 1 : -1;
    
    // 今週の期間を計算（日曜日始まり）
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday % 7));
    final weekEnd = weekStart.add(const Duration(days: 6));

    return Column(
      children: [
        // 週の期間表示
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
        // フレンドフィルター
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
                      Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'フレンドがいません',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: displayRankings.length > 30 ? 30 : displayRankings.length,
                  itemBuilder: (context, index) {
                    final item = displayRankings[index];
                    final isMe = item['name'] == _currentUserName;
                    final isFriend = _friendsList.contains(item['name']);
                    
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
                                '#${index + 1}',
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
                            if (index < 3)
                              Icon(
                                Icons.emoji_events,
                                size: 20,
                                color: index == 0 
                                    ? Colors.amber[700]
                                    : index == 1
                                        ? Colors.grey[600]
                                        : Colors.brown[400],
                              ),
                          ],
                        ),
                        title: Row(
                          children: [
                            Text(
                              item['name'],
                              style: TextStyle(
                                fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            if (isMe) ...[
                              const SizedBox(width: 8),
                              Icon(Icons.person, size: 16, color: Colors.blue[700]),
                            ],
                            if (isFriend && !isMe) ...[
                              const SizedBox(width: 8),
                              Icon(Icons.people, size: 16, color: Colors.green[600]),
                            ],
                          ],
                        ),
                        trailing:                         Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${item['count']}回',
                              style: TextStyle(
                                fontWeight: isMe ? FontWeight.bold : FontWeight.w600,
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
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                    '${displayRankings[myRankIndex]['count']}回',
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
}