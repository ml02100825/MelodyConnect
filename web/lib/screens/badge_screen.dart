import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Badge Screen',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const BadgeScreen(),
    );
  }
}

class BadgeScreen extends StatefulWidget {
  const BadgeScreen({super.key});

  @override
  State<BadgeScreen> createState() => _BadgeScreenState();
}

class _BadgeScreenState extends State<BadgeScreen> {
  String selectedFilter = 'all';

  // 49個のバッジデータ（12個完了）
  final List<Map<String, dynamic>> badgeList = [
    // 継続者カテゴリー (10個 - 3個完了)
    {
      'title': '継続者Ⅰ',
      'category': '継続者',
      'description': '達成条件：10日間ログインする',
      'icon': Icons.trending_up,
      'color': Colors.green,
      'progress': 1.0,
      'rarity': 'common',
      'acquiredDate': '2024-01-15',
    },
    {
      'title': '継続者Ⅱ',
      'category': '継続者',
      'description': '達成条件：30日間ログインする',
      'icon': Icons.trending_up,
      'color': Colors.green,
      'progress': 1.0,
      'rarity': 'common',
      'acquiredDate': '2024-02-14',
    },
    {
      'title': '継続者Ⅲ',
      'category': '継続者',
      'description': '達成条件：100日間ログインする',
      'icon': Icons.trending_up,
      'color': Colors.green,
      'progress': 0.5,
      'rarity': 'rare',
      'acquiredDate': '2024-04-10',
    },
    {
      'title': '毎日コツコツ',
      'category': '継続者',
      'description': '達成条件：1ヶ月間毎日ログイン',
      'icon': Icons.calendar_today,
      'color': Colors.blue,
      'progress': 0.0,
      'rarity': 'rare',
      'acquiredDate': null,
    },

    // バトラーカテゴリー (10個 - 2個完了)
    {
      'title': 'バトル初心者',
      'category': 'バトラー',
      'description': '達成条件：初めてバトルに参加する',
      'icon': Icons.sports_esports,
      'color': Colors.red,
      'progress': 1.0,
      'rarity': 'common',
      'acquiredDate': '2024-01-10',
    },
    {
      'title': '連勝Ⅰ',
      'category': 'バトラー',
      'description': '達成条件：3連勝する',
      'icon': Icons.emoji_events,
      'color': Colors.red,
      'progress': 1.0,
      'rarity': 'common',
      'acquiredDate': '2024-02-05',
    },
    {
      'title': '連勝Ⅱ',
      'category': 'バトラー',
      'description': '達成条件：5連勝する',
      'icon': Icons.emoji_events,
      'color': Colors.red,
      'progress': 0.0,
      'rarity': 'rare',
      'acquiredDate': null,
    },
    {
      'title': 'バトルマスター',
      'category': 'バトラー',
      'description': '達成条件：100回バトルに勝利',
      'icon': Icons.military_tech,
      'color': Colors.red,
      'progress': 0.4,
      'rarity': 'epic',
      'acquiredDate': null,
    },
    {
      'title': '友情バトル',
      'category': 'バトラー',
      'description': '達成条件：フレンドと10回バトル',
      'icon': Icons.group,
      'color': Colors.pink,
      'progress': 0.0,
      'rarity': 'common',
      'acquiredDate': null,
    },

    // ランカーカテゴリー (10個 - 3個完了)
    {
      'title': 'ランク入り',
      'category': 'ランカー',
      'description': '達成条件：初めてランキングに入る',
      'icon': Icons.leaderboard,
      'color': Colors.yellow,
      'progress': 1.0,
      'rarity': 'common',
      'acquiredDate': '2024-01-20',
    },
    {
      'title': 'トップ100',
      'category': 'ランカー',
      'description': '達成条件：ランキングTOP100に入る',
      'icon': Icons.leaderboard,
      'color': Colors.yellow,
      'progress': 1.0,
      'rarity': 'rare',
      'acquiredDate': '2024-03-01',
    },
    {
      'title': 'トップ50',
      'category': 'ランカー',
      'description': '達成条件：ランキングTOP50に入る',
      'icon': Icons.leaderboard,
      'color': Colors.yellow,
      'progress': 1.0,
      'rarity': 'epic',
      'acquiredDate': '2024-04-15',
    },
    {
      'title': 'トップ10',
      'category': 'ランカー',
      'description': '達成条件：ランキングTOP10に入る',
      'icon': Icons.leaderboard,
      'color': Colors.yellow,
      'progress': 0.0,
      'rarity': 'legendary',
      'acquiredDate': null,
    },
    {
      'title': 'ランキングキング',
      'category': 'ランカー',
      'description': '達成条件：1位になる',
      'icon': Icons.king_bed,
      'color': Colors.amber,
      'progress': 0.0,
      'rarity': 'legendary',
      'acquiredDate': null,
    },
    {
      'title': '月間ランカー',
      'category': 'ランカー',
      'description': '達成条件：月間ランキングTOP10',
      'icon': Icons.calendar_view_month,
      'color': Colors.blue,
      'progress': 0.0,
      'rarity': 'epic',
      'acquiredDate': null,
    },
    {
      'title': '週間ランカー',
      'category': 'ランカー',
      'description': '達成条件：週間ランキングTOP10',
      'icon': Icons.view_week,
      'color': Colors.green,
      'progress': 0.0,
      'rarity': 'rare',
      'acquiredDate': null,
    },
    {
      'title': '連続ランクイン',
      'category': 'ランカー',
      'description': '達成条件：4週連続でランクイン',
      'icon': Icons.timeline,
      'color': Colors.purple,
      'progress': 0.0,
      'rarity': 'epic',
      'acquiredDate': null,
    },
    {
      'title': '新人王',
      'category': 'ランカー',
      'description': '達成条件：初月でTOP100に入る',
      'icon': Icons.new_releases,
      'color': Colors.orange,
      'progress': 0.0,
      'rarity': 'rare',
      'acquiredDate': null,
    },

    // 獲得大王カテゴリー (10個 - 2個完了)
    {
      'title': 'コレクターⅠ',
      'category': '獲得大王',
      'description': '達成条件：10個のアイテムを集める',
      'icon': Icons.collections,
      'color': Colors.purple,
      'progress': 1.0,
      'rarity': 'common',
      'acquiredDate': '2024-02-01',
    },
    {
      'title': 'コレクターⅡ',
      'category': '獲得大王',
      'description': '達成条件：50個のアイテムを集める',
      'icon': Icons.collections,
      'color': Colors.purple,
      'progress': 1.0,
      'rarity': 'rare',
      'acquiredDate': '2024-03-20',
    },
    {
      'title': 'コレクターⅢ',
      'category': '獲得大王',
      'description': '達成条件：100個のアイテムを集める',
      'icon': Icons.collections,
      'color': Colors.purple,
      'progress': 0.7,
      'rarity': 'epic',
      'acquiredDate': null,
    },
    {
      'title': 'レアハンター',
      'category': '獲得大王',
      'description': '達成条件：レアアイテムを10個集める',
      'icon': Icons.search,
      'color': Colors.blue,
      'progress': 0.0,
      'rarity': 'rare',
      'acquiredDate': null,
    },
    {
      'title': 'コンプリート',
      'category': '獲得大王',
      'description': '達成条件：すべてのアイテムを集める',
      'icon': Icons.done_all,
      'color': Colors.amber,
      'progress': 0.0,
      'rarity': 'legendary',
      'acquiredDate': null,
    },
    {
      'title': 'トレジャーハンター',
      'category': '獲得大王',
      'description': '達成条件：隠しアイテムを5個発見',
      'icon': Icons.emoji_objects,
      'color': Colors.yellow,
      'progress': 0.0,
      'rarity': 'epic',
      'acquiredDate': null,
    },
    {
      'title': '交換大師',
      'category': '獲得大王',
      'description': '達成条件：アイテムを50回交換',
      'icon': Icons.swap_horiz,
      'color': Colors.green,
      'progress': 0.0,
      'rarity': 'rare',
      'acquiredDate': null,
    },
    {
      'title': 'ギフトマスター',
      'category': '獲得大王',
      'description': '達成条件：フレンドに20回ギフト',
      'icon': Icons.card_giftcard,
      'color': Colors.pink,
      'progress': 0.0,
      'rarity': 'common',
      'acquiredDate': null,
    },
    {
      'title': 'セールハンター',
      'category': '獲得大王',
      'description': '達成条件：限定アイテムを5個獲得',
      'icon': Icons.local_offer,
      'color': Colors.red,
      'progress': 0.0,
      'rarity': 'rare',
      'acquiredDate': null,
    },
    {
      'title': 'イベントコレクター',
      'category': '獲得大王',
      'description': '達成条件：イベントアイテムを全て獲得',
      'icon': Icons.event,
      'color': Colors.orange,
      'progress': 0.0,
      'rarity': 'epic',
      'acquiredDate': null,
    },

    // スペシャルカテゴリー (9個 - 2個完了)
    {
      'title': '初勝利',
      'category': 'スペシャル',
      'description': '達成条件：初めてバトルで勝利',
      'icon': Icons.celebration,
      'color': Colors.pink,
      'progress': 1.0,
      'rarity': 'common',
      'acquiredDate': '2024-01-08',
    },
    {
      'title': 'フレンド招待',
      'category': 'スペシャル',
      'description': '達成条件：フレンドを5人招待',
      'icon': Icons.person_add,
      'color': Colors.blue,
      'progress': 1.0,
      'rarity': 'common',
      'acquiredDate': '2024-02-28',
    },
    {
      'title': 'バージョン1.0',
      'category': 'スペシャル',
      'description': '達成条件：最初のバージョンプレイ',
      'icon': Icons.history,
      'color': Colors.grey,
      'progress': 0.0,
      'rarity': 'common',
      'acquiredDate': null,
    },
    {
      'title': 'アニバーサリー',
      'category': 'スペシャル',
      'description': '達成条件：1周年記念',
      'icon': Icons.cake,
      'color': Colors.purple,
      'progress': 0.0,
      'rarity': 'rare',
      'acquiredDate': null,
    },
    {
      'title': 'ホリデー',
      'category': 'スペシャル',
      'description': '達成条件：特別な日にログイン',
      'icon': Icons.holiday_village,
      'color': Colors.red,
      'progress': 0.0,
      'rarity': 'common',
      'acquiredDate': null,
    },
    {
      'title': 'バグハンター',
      'category': 'スペシャル',
      'description': '達成条件：バグを報告する',
      'icon': Icons.bug_report,
      'color': Colors.green,
      'progress': 0.0,
      'rarity': 'rare',
      'acquiredDate': null,
    },
    {
      'title': 'サポーター',
      'category': 'スペシャル',
      'description': '達成条件：フィードバックを送信',
      'icon': Icons.feedback,
      'color': Colors.orange,
      'progress': 0.0,
      'rarity': 'common',
      'acquiredDate': null,
    },
    {
      'title': 'シェアマスター',
      'category': 'スペシャル',
      'description': '達成条件：10回SNSで共有',
      'icon': Icons.share,
      'color': Colors.blue,
      'progress': 0.0,
      'rarity': 'rare',
      'acquiredDate': null,
    },
    {
      'title': 'レジェンド',
      'category': 'スペシャル',
      'description': '達成条件：全てのカテゴリーでトップ',
      'icon': Icons.auto_awesome,
      'color': Colors.amber,
      'progress': 0.0,
      'rarity': 'legendary',
      'acquiredDate': null,
    },
  ];

  List<Map<String, dynamic>> get filteredBadges {
    if (selectedFilter == null || selectedFilter == 'all') {
      return badgeList;
    }
    return badgeList.where((badge) => badge['category'] == selectedFilter).toList();
  }

  Color _getRarityColor(String rarity) {
    switch (rarity) {
      case 'common':
        return Colors.grey;
      case 'rare':
        return Colors.blue;
      case 'epic':
        return Colors.purple;
      case 'legendary':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getRarityText(String rarity) {
    switch (rarity) {
      case 'common':
        return 'コモン';
      case 'rare':
        return 'レア';
      case 'epic':
        return 'エピック';
      case 'legendary':
        return 'レジェンド';
      default:
        return 'コモン';
    }
  }

  void _showBadgeDetails(Map<String, dynamic> badge) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: badge['color'].withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: badge['progress'] == 1.0 ? badge['color'] : Colors.grey,
                    width: 2,
                  ),
                ),
                child: Icon(
                  badge['icon'],
                  color: badge['progress'] == 1.0 ? badge['color'] : Colors.grey,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      badge['title'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getRarityColor(badge['rarity']).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getRarityColor(badge['rarity']),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        _getRarityText(badge['rarity']),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _getRarityColor(badge['rarity']),
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
              Text(
                badge['description'],
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              if (badge['progress'] == 1.0 && badge['acquiredDate'] != null)
                Text(
                  '獲得日: ${badge['acquiredDate']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              if (badge['progress'] > 0.0 && badge['progress'] < 1.0) ...[
                LinearProgressIndicator(
                  value: badge['progress'],
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(badge['color']),
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(badge['progress'] * 100).toInt()}% 達成',
                  style: TextStyle(
                    fontSize: 12,
                    color: badge['color'],
                    fontWeight: FontWeight.bold,
                  ),
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

  @override
  Widget build(BuildContext context) {
    final earnedCount = badgeList.where((badge) => badge['progress'] == 1.0).length;
    final totalCount = badgeList.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'バッジ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 統計情報
          _buildStatsCard(earnedCount, totalCount),
          
          // フィルター
          _buildFilterSection(),
          
          // バッジグリッド
          _buildBadgeGrid(),
        ],
      ),
    );
  }

  Widget _buildStatsCard(int earnedCount, int totalCount) {
    final progress = earnedCount / totalCount;

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
            child: const Icon(
              Icons.emoji_events,
              color: Colors.amber,
              size: 32,
            ),
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
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
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
              underline: const SizedBox(), // デフォルトの下線を非表示
              borderRadius: BorderRadius.circular(8),
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 14,
              ),
              items: const [
                DropdownMenuItem(
                  value: 'all',
                  child: Text('すべてのカテゴリー'),
                ),
                DropdownMenuItem(
                  value: '継続者',
                  child: Text('継続者'),
                ),
                DropdownMenuItem(
                  value: 'バトラー',
                  child: Text('バトラー'),
                ),
                DropdownMenuItem(
                  value: 'ランカー',
                  child: Text('ランカー'),
                ),
                DropdownMenuItem(
                  value: '獲得大王',
                  child: Text('獲得大王'),
                ),
                DropdownMenuItem(
                  value: 'スペシャル',
                  child: Text('スペシャル'),
                ),
              ],
              onChanged: (String? value) {
                setState(() {
                  selectedFilter = value ?? 'all';
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = selectedFilter == value;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            selectedFilter = value;
          });
        },
        backgroundColor: Colors.grey[200],
        selectedColor: Colors.blue.withOpacity(0.2),
        checkmarkColor: Colors.blue,
        labelStyle: TextStyle(
          color: isSelected ? Colors.blue : Colors.grey[700],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildBadgeGrid() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.9,
          ),
          itemCount: filteredBadges.length,
          itemBuilder: (context, index) {
            final badge = filteredBadges[index];
            return _buildBadgeCircle(badge);
          },
        ),
      ),
    );
  }

  Widget _buildBadgeCircle(Map<String, dynamic> badge) {
    final isEarned = badge['progress'] == 1.0;
    final isInProgress = badge['progress'] > 0.0 && badge['progress'] < 1.0;

    return GestureDetector(
      onTap: () => _showBadgeDetails(badge),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // バッジの円形背景
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: isEarned 
                      ? badge['color'].withOpacity(0.2)
                      : Colors.grey.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isEarned ? badge['color'] : Colors.grey[300]!,
                    width: 2,
                  ),
                  boxShadow: isEarned
                      ? [
                          BoxShadow(
                            color: badge['color'].withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  badge['icon'],
                  color: isEarned ? badge['color'] : Colors.grey,
                  size: 30,
                ),
              ),
              // 進行中のインジケーター
              if (isInProgress)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.autorenew,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
              // 獲得済みチェック
              if (isEarned)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            badge['title'],
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
}