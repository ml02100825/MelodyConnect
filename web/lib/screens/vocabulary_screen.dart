import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../bottom_nav.dart';
import '../models/vocabulary_model.dart';
import '../services/vocabulary_api_service.dart';
import '../services/token_storage_service.dart';
import 'word_list_screen.dart';
import 'report_screen.dart';

class VocabularyScreen extends StatefulWidget {
  final int userId;
  final int? returnRoomId;
  
  const VocabularyScreen({
    Key? key,
    required this.userId,
    this.returnRoomId,
  }) : super(key: key);

  @override
  State<VocabularyScreen> createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends State<VocabularyScreen> {
  final VocabularyApiService _apiService = VocabularyApiService();
  final TokenStorageService _tokenStorage = TokenStorageService();
  String? _userName;
  
  // サブスク状態（テスト用）
  bool isSubscribed = false; // falseでサブスク未登録をテスト
  
  // フィルター・並び替え
  List<String> selectedLanguages = ['すべて']; // 複数選択可能
  String sortOrder = '新しい順'; // 新しい順、古い順（サブスクのみ）
  bool showJapaneseOnFront = true; // true: 日本語を表面に、false: 外国語を表面に
  List<String> selectedFilters = []; // お気に入り、学習済みなどのフィルター
  
  // データ
  List<VocabularyCard> vocabularies = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _accessToken;

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadData();
  }
   Future<void> _loadUserName() async {
    final name = await _tokenStorage.getUsername();
    if (!mounted) return;
    setState(() {
     _userName = name;
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      _accessToken = await _tokenStorage.getAccessToken();
      if (_accessToken == null) {
        setState(() {
          _errorMessage = 'ログインが必要です';
          _isLoading = false;
        });
        return;
      }

      final response = await _apiService.getUserVocabularies(widget.userId, _accessToken!);
      
      if (response.success) {
        setState(() {
          vocabularies = response.vocabularies.map((item) => VocabularyCard(
            id: item.userVocabId.toString(),
            userVocabId: item.userVocabId,
            japanese: item.displayMeaning,
            foreign: item.displayWord,
            language: item.languageDisplay,
            exampleSentence: item.exampleSentence ?? '',
            exampleTranslation: item.exampleTranslation ?? '',
            isFlagged: item.isFavorite,
            isLearned: item.isLearned,
            createdAt: item.firstLearnedAt,
            pronunciation: item.pronunciation,
            partOfSpeech: item.partOfSpeech,
          )).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response.message ?? '単語の取得に失敗しました';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'エラーが発生しました: $e';
        _isLoading = false;
      });
    }
  }

  List<VocabularyCard> get filteredVocabularies {
    var filtered = vocabularies.where((v) {
      // 言語フィルター
      if (!selectedLanguages.contains('すべて')) {
        if (!selectedLanguages.contains(v.language)) {
          return false;
        }
      }
      
      // お気に入り・学習済みフィルター
      if (selectedFilters.isNotEmpty) {
        bool matchesFilter = false;
        
        // いずれかのフィルターに一致すればOK
        if (selectedFilters.contains('お気に入り') && v.isFlagged) {
          matchesFilter = true;
        }
        if (selectedFilters.contains('学習済み') && v.isLearned) {
          matchesFilter = true;
        }
        if (selectedFilters.contains('未登録') && !v.isFlagged && !v.isLearned) {
          matchesFilter = true;
        }
        
        if (!matchesFilter) {
          return false;
        }
      }
      
      return true;
    }).toList();
    
    // 並び替え
    if (sortOrder == '新しい順') {
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else if (sortOrder == '古い順' && isSubscribed) {
      filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }
    
    return filtered;
  }
  
  // 学習済みの単語があるかチェック
  bool get hasLearnedVocabs {
    return vocabularies.any((v) => v.isLearned);
  }

  /// お気に入りフラグを更新
  Future<void> _updateFavorite(VocabularyCard vocab) async {
    if (_accessToken == null) return;
    
    final newValue = !vocab.isFlagged;
    final success = await _apiService.updateFavoriteFlag(
      vocab.userVocabId, 
      newValue, 
      _accessToken!
    );
    
    if (success) {
      setState(() {
        vocab.isFlagged = newValue;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('お気に入りの更新に失敗しました')),
      );
    }
  }

  /// 学習済みフラグを更新
  Future<void> _updateLearned(VocabularyCard vocab) async {
    if (_accessToken == null) return;
    
    final newValue = !vocab.isLearned;
    final success = await _apiService.updateLearnedFlag(
      vocab.userVocabId, 
      newValue, 
      _accessToken!
    );
    
    if (success) {
      setState(() {
        vocab.isLearned = newValue;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('学習済みの更新に失敗しました')),
      );
    }
  }

  void _handleBackNavigation() {
    final returnRoomId = widget.returnRoomId;
    if (returnRoomId != null) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/room-match?roomId=$returnRoomId&isReturning=true&fromVocabulary=true',
        (route) => route.isFirst,
      );
      return;
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final displayList = filteredVocabularies;
    final freeLimit = 50; // 無料で見られる件数

    return WillPopScope(
      onWillPop: () async {
        _handleBackNavigation();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
            onPressed: _handleBackNavigation,
          ),
          title: const Text(
            '単語帳',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
          actions: [
            // 一覧画面へ遷移
            IconButton(
              icon: const Icon(Icons.list_alt, color: Colors.black),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WordListScreen(
                      userId: widget.userId,
                      returnRoomId: widget.returnRoomId,
                    ),
                  ),
                );
              },
              tooltip: '一覧表示',
            ),
            // リフレッシュボタン
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.black),
              onPressed: _loadData,
              tooltip: '更新',
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? _buildErrorView()
                : Column(
                    children: [
                      // フィルター・並び替えエリア
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildFilterButton(
                                    label: '言語',
                                    value: selectedLanguages.contains('すべて')
                                        ? 'すべて'
                                        : selectedLanguages.join(', '),
                                    onTap: () => _showLanguageFilter(),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildFilterButton(
                                    label: '並び替え',
                                    value: sortOrder,
                                    onTap: () => _showSortFilter(),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildFilterButton(
                                    label: 'フィルター',
                                    value: selectedFilters.isEmpty
                                        ? 'すべて'
                                        : selectedFilters.join(', '),
                                    onTap: () => _showStatusFilter(),
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Text(
                                '表面表示:',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: SegmentedButton<bool>(
                                  segments: const [
                                    ButtonSegment(value: true, label: Text('日本語')),
                                    ButtonSegment(value: false, label: Text('外国語')),
                                  ],
                                  selected: {showJapaneseOnFront},
                                  onSelectionChanged: (Set<bool> newSelection) {
                                    setState(() {
                                      showJapaneseOnFront = newSelection.first;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // 単語数表示
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Text(
                            '${displayList.length}件',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          if (!isSubscribed && displayList.length > freeLimit)
                            Text(
                              '${freeLimit}件まで無料',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange[700],
                              ),
                            ),
                        ],
                      ),
                    ),
                    
                    // 単語リスト
                    Expanded(
                      child: displayList.isEmpty && selectedFilters.contains('学習済み') && !hasLearnedVocabs
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.check_circle_outline,
                                    size: 64,
                                    color: Colors.grey[300],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'まだ学習登録されていません',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '単語を左にスワイプして学習済みにしましょう',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : displayList.isEmpty
                              ? _buildEmptyView()
                              : ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: displayList.length,
                                  itemBuilder: (context, index) {
                                    final vocab = displayList[index];
                                    final isLocked = !isSubscribed && index >= freeLimit;
                                    
                                    return _FlipCard(
                                      key: ValueKey(vocab.id),
                                      vocab: vocab,
                                      isLocked: isLocked,
                                      showJapaneseOnFront: showJapaneseOnFront,
                                      isUnregisteredFilterActive: selectedFilters.contains('未登録'),
                                      onTap: () {
                                        if (isLocked) {
                                          _showSubscriptionDialog();
                                        } else {
                                          _showVocabDetail(vocab);
                                        }
                                      },
                                      onFlagToggle: () => _updateFavorite(vocab),
                                      onLearnedToggle: () => _updateLearned(vocab),
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
    )
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'エラーが発生しました',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('再読み込み'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.library_books_outlined,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            '単語がありません',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'クイズを解いて単語を追加しましょう',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.arrow_drop_down, size: 20, color: Colors.grey[600]),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageFilter() {
    // 利用可能な言語を取得
    final availableLanguages = vocabularies.map((v) => v.language).toSet().toList();
    availableLanguages.insert(0, 'すべて');

    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '言語を選択',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: availableLanguages.map((lang) {
                    final isSelected = selectedLanguages.contains(lang);
                    return FilterChip(
                      label: Text(lang),
                      selected: isSelected,
                      onSelected: (selected) {
                        setModalState(() {
                          if (lang == 'すべて') {
                            selectedLanguages = ['すべて'];
                          } else {
                            selectedLanguages.remove('すべて');
                            if (selected) {
                              selectedLanguages.add(lang);
                            } else {
                              selectedLanguages.remove(lang);
                              if (selectedLanguages.isEmpty) {
                                selectedLanguages = ['すべて'];
                              }
                            }
                          }
                        });
                        setState(() {});
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showSortFilter() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '並び替え',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('新しい順'),
              leading: Radio<String>(
                value: '新しい順',
                groupValue: sortOrder,
                onChanged: (value) {
                  setState(() => sortOrder = value!);
                  Navigator.pop(context);
                },
              ),
              onTap: () {
                setState(() => sortOrder = '新しい順');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Row(
                children: [
                  const Text('古い順'),
                  if (!isSubscribed)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'サブスク限定',
                        style: TextStyle(fontSize: 10, color: Colors.orange[800]),
                      ),
                    ),
                ],
              ),
              leading: Radio<String>(
                value: '古い順',
                groupValue: sortOrder,
                onChanged: isSubscribed
                    ? (value) {
                        setState(() => sortOrder = value!);
                        Navigator.pop(context);
                      }
                    : null,
              ),
              onTap: isSubscribed
                  ? () {
                      setState(() => sortOrder = '古い順');
                      Navigator.pop(context);
                    }
                  : () => _showSubscriptionDialog(),
            ),
          ],
        ),
      ),
    );
  }

  void _showStatusFilter() {
    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'フィルター',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['お気に入り', '学習済み', '未登録'].map((filter) {
                    final isSelected = selectedFilters.contains(filter);
                    return FilterChip(
                      label: Text(filter),
                      selected: isSelected,
                      onSelected: (selected) {
                        setModalState(() {
                          if (selected) {
                            selectedFilters.add(filter);
                          } else {
                            selectedFilters.remove(filter);
                          }
                        });
                        setState(() {});
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                if (selectedFilters.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      setModalState(() => selectedFilters.clear());
                      setState(() {});
                    },
                    child: const Text('クリア'),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showSubscriptionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('サブスクリプション'),
        content: const Text('この機能を利用するにはサブスクリプション登録が必要です。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: サブスク画面へ遷移
            },
            child: const Text('登録する'),
          ),
        ],
      ),
    );
  }

  void _showVocabDetail(VocabularyCard vocab) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ハンドル
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // 単語
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        vocab.foreign,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        vocab.isFlagged ? Icons.star : Icons.star_border,
                        color: vocab.isFlagged ? Colors.amber : Colors.grey,
                      ),
                      onPressed: () {
                        _updateFavorite(vocab);
                        Navigator.pop(context);
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.flag,
                        color: Colors.red,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ReportScreen(
                              reportType: 'VOCABULARY',
                              targetId: vocab.userVocabId,
                              targetDisplayText: vocab.foreign,
                              userName: _userName ?? 'User',
                              userId: widget.userId,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                
                // 発音
                if (vocab.pronunciation != null && vocab.pronunciation!.isNotEmpty)
                  Text(
                    vocab.pronunciation!,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                
                const SizedBox(height: 8),
                
                // 言語・品詞
                Wrap(
                  spacing: 8,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.purple[50],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        vocab.language,
                        style: TextStyle(fontSize: 12, color: Colors.purple[700]),
                      ),
                    ),
                    if (vocab.partOfSpeech != null && vocab.partOfSpeech!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          vocab.partOfSpeech!,
                          style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                
                // 意味
                const Text(
                  '意味',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  vocab.japanese,
                  style: const TextStyle(fontSize: 18),
                ),
                
                // 例文
                if (vocab.exampleSentence.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Text(
                    '例文',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    vocab.exampleSentence,
                    style: const TextStyle(fontSize: 16),
                  ),
                  if (vocab.exampleTranslation.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      vocab.exampleTranslation,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
                
                const SizedBox(height: 32),
                
                // アクションボタン
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _updateLearned(vocab);
                          Navigator.pop(context);
                        },
                        icon: Icon(
                          vocab.isLearned ? Icons.check_circle : Icons.check_circle_outline,
                        ),
                        label: Text(vocab.isLearned ? '学習済み解除' : '学習済みにする'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// FlipCardウィジェット
class _FlipCard extends StatefulWidget {
  final VocabularyCard vocab;
  final bool isLocked;
  final bool showJapaneseOnFront;
  final bool isUnregisteredFilterActive;
  final VoidCallback onTap;
  final VoidCallback onFlagToggle;
  final VoidCallback onLearnedToggle;

  const _FlipCard({
    Key? key,
    required this.vocab,
    required this.isLocked,
    required this.showJapaneseOnFront,
    required this.isUnregisteredFilterActive,
    required this.onTap,
    required this.onFlagToggle,
    required this.onLearnedToggle,
  }) : super(key: key);

  @override
  State<_FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<_FlipCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isFlipped = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(widget.vocab.id),
      background: _buildSwipeBackground(
        color: Colors.amber,
        icon: Icons.star,
        alignment: Alignment.centerLeft,
      ),
      secondaryBackground: _buildSwipeBackground(
        color: Colors.green,
        icon: Icons.check,
        alignment: Alignment.centerRight,
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // 右へスワイプ: お気に入り登録/解除
          widget.onFlagToggle();
          return false; // カードは削除しない
        } else if (direction == DismissDirection.endToStart) {
          // 左へスワイプ: 学習済みにする
          if (!widget.vocab.isLearned) {
            widget.onLearnedToggle();
            // 未登録フィルターが有効な場合は、リストから削除
            return widget.isUnregisteredFilterActive;
          }
          return false; // すでに学習済みの場合は何もしない
        }
        return false;
      },
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPressStart: widget.isLocked ? null : (_) {
          if (!_isFlipped) {
            _controller.forward();
            setState(() {
              _isFlipped = true;
            });
          }
        },
        onLongPressEnd: widget.isLocked ? null : (_) {
          if (_isFlipped) {
            _controller.reverse();
            setState(() {
              _isFlipped = false;
            });
          }
        },
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            final angle = _animation.value * math.pi;
            final transform = Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle);

            return Transform(
              transform: transform,
              alignment: Alignment.center,
              child: angle >= math.pi / 2
                  ? Transform(
                      transform: Matrix4.identity()..rotateY(math.pi),
                      alignment: Alignment.center,
                      child: _buildBackSide(),
                    )
                  : _buildFrontSide(),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFrontSide() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (widget.vocab.isFlagged)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(Icons.star, color: Colors.amber[600], size: 20),
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.purple[50],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  widget.vocab.language,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.purple[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              if (widget.vocab.isLearned)
                Icon(Icons.check_circle, color: Colors.green[400], size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.showJapaneseOnFront ? widget.vocab.japanese : widget.vocab.foreign,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackSide() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (widget.vocab.isFlagged)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(Icons.star, color: Colors.amber[600], size: 20),
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.purple[50],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  widget.vocab.language,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.purple[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              if (widget.vocab.isLearned)
                Icon(Icons.check_circle, color: Colors.green[400], size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.showJapaneseOnFront ? widget.vocab.foreign : widget.vocab.japanese,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.vocab.isFlagged ? Colors.amber[300]! : Colors.grey[300]!,
          width: widget.vocab.isFlagged ? 2 : 1,
        ),
      ),
      child: Stack(
        children: [
          child,
          if (widget.isLocked)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.lock, color: Colors.white, size: 32),
                      SizedBox(height: 8),
                      Text(
                        'サブスク登録で閲覧可能',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSwipeBackground({
    required Color color,
    required IconData icon,
    required Alignment alignment,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Icon(icon, color: Colors.white, size: 32),
    );
  }
}

/// 単語カードデータ
class VocabularyCard {
  final String id;
  final int userVocabId;
  final String japanese;
  final String foreign;
  final String language;
  final String exampleSentence;
  final String exampleTranslation;
  bool isFlagged;
  bool isLearned;
  final DateTime createdAt;
  final String? pronunciation;
  final String? partOfSpeech;

  VocabularyCard({
    required this.id,
    required this.userVocabId,
    required this.japanese,
    required this.foreign,
    required this.language,
    required this.exampleSentence,
    required this.exampleTranslation,
    required this.isFlagged,
    required this.isLearned,
    required this.createdAt,
    this.pronunciation,
    this.partOfSpeech,
  });
}
